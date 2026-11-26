# 造梦西游3 离线版 —— 构建与修改说明

## 一、运行原理

4399 的造梦西游3 是三层套娃：

```
v261029.swf                     4399 外层壳（登录/支付/防沉迷）
└─ gamefile.swf                 真正的游戏主 SWF（GMain）
   └─ MainResourcev3730.swf     主资源包
```

游戏本身和 4399 平台是解耦的：

- 登录、存档、充值、排行全部走 `GMain.setHold(hold)` 注入的对象；
- 资源按 **相对路径** 加载（`Decode.doDecrypt("Commonv3720.swf")`），
  所以只要把主 SWF 和资源放在同一个 HTTP 目录里就能跑；
- 唯一硬编码的联网点是 `Config.requestData()` 里的
  `https://save.api.4399.com/?ac=get_time`（失败会无限重试），
  以及 `Config.checkWebUid()` 通过 `ExternalInterface` 校验 4399 uid。

离线化做了三件事：

1. `gamefile.swf` 里 `https://save.api.4399.com/?ac=get_time&`
   等长替换成本地 `http://127.0.0.1:8765/time?ac=get_time&`；
2. `config.Config.checkWebUid()` 方法体改成 `return true;`
   （4 字节字节码 `d0 30 26 48`）；
3. 新写一个 `launcher.swf`：
   - 本地加载 `gamefile.swf`；
   - 注入 `LocalHold`（`isLog` 返回假账号，`saveData/getData` 写
     `SharedObject`，充值/排行/公会全部空实现）；
   - 把假账号写进 `Config.logInfo`。

## 二、目录

| 路径 | 说明 |
| --- | --- |
| `run/` | **实际运行目录**：`launcher.swf` + `gamefile.swf` + 所有资源 SWF |
| `run/server.py` | 本地 HTTP 服务（含 `/time` 假时间接口、`/diag` 调试接口） |
| `offline/src/` | 启动器源码：`Launcher.as`、`LocalHold.as`、`Evt.as` |
| `offline/launcher.swf` | 编译好的启动器 |
| `game_offline.swf` | 打过补丁的游戏主 SWF（`run/gamefile.swf` 的来源） |
| `src_gamefile/` | 游戏主 SWF 的反编译源码（1104 个 .as） |
| `src_v261029/` | 4399 外层壳源码 |
| `assets/` | 已抓取的 57 个静态资源 SWF |
| `build_asset_list.py` | 从源码生成完整资源清单 |
| `fetch_assets.ps1` | 按清单批量抓取资源 |
| `start.bat` / `start.ps1` | 一键启动 |

## 三、启动

```bat
start.bat
```

脚本会：启动本地 8765 端口服务 → 用 Flash Player 独立播放器打开
`http://127.0.0.1:8765/launcher.swf`。

`start.bat auto` 会带 `?auto=1`，自动过菜单/选人/存档，用于测试。

## 四、重新构建

### 1. 编译启动器

```powershell
$env:PLAYERGLOBAL_HOME = "D:\4399\tools\flex_sdk\frameworks\libs\player"
D:\4399\tools\flex_sdk\bin\mxmlc.exe -strict=false -source-path offline\src `
  -output offline\launcher.swf offline\src\Launcher.as
```

### 2. 给主 SWF 打补丁

```powershell
# 解压
java -jar ffdec.jar -decompress gamefile.swf game_fws.swf
# 等长替换 URL（PowerShell 脚本见 README 历史）
# 改 checkWebUid
java -cp "D:\4399\tools\swfpatch;<ffdec_lib.jar>" SwfPatch `
  game_fws_patched.swf config.Config checkWebUid d0302648 game_offline.swf
```

`D:\4399\tools\swfpatch\SwfPatch.java` 是通用方法体替换工具：

```
SwfPatch <in.swf> <类名> <方法名> <十六进制字节码|-> <out.swf>
```

字节码可以从 FFDec 的 `pcodehex` 导出里逐条抄。

## 五、修改游戏内容

### A. 小改动（数值、开关、单条逻辑）

用 `SwfPatch` 直接替换方法字节码，或用 FFDec 的 P-code 编辑器。
优点：不用重新编译整个工程。

### B. 大改动（配置表、装备表、技能）

需要改 `src_gamefile/scripts/config/Config.as`、
`my/AllEquipment.as`、`petInfo/PetInfo.as` 等，然后重新编译。

目前反编译源码直接全量编译会报少量错（GMain 里类名乱码、
`AUtils` 重名、`union.view.BasicView.items` 可见性冲突等），
需要先修这些再整体编译。修好后就可以用 mxmlc 出全新 SWF，
改内容会非常方便。

### C. 换美术/音效

`assets/*.swf` 是 **加密过的**（前 300 字节/25 字节轮转）。
处理流程：

```
解密：writeBytes(d,300,25) + writeBytes(d,0,300) + writeBytes(d,325)
加密：反向操作
```

解密后用 FFDec 打开替换图片/声音，再按反向规则加密回 CDN 格式。

### D. 抓全资源

```powershell
python build_asset_list.py > mirror_names.txt
powershell -File fetch_assets.ps1 -ListFile mirror_names.txt -OutDir run
```

清单包含：58 个静态 SWF、关卡包（0v1150 / 24v1180 …）、
Monster1~260、四个角色、13 个宠物、以及从 `AllEquipment.as`
解析出的全部装备贴图名。

## 六、画质与帧率

帧率由游戏引擎写死为 24（`Config.frameClips = 24`，所有逻辑按帧计数），
**提高帧率会让游戏加速**，所以不要改 `stage.frameRate`。实测 1x / 1.5x / 2x
窗口下都稳定在 24 FPS，瓶颈不在渲染。

清晰度问题来自 Windows DPI 缩放：

- 本机是 2560×1440 @150%，Flash Player 默认 DPI 不感知，
  窗口会被系统整体拉伸 1.5 倍 → 模糊；
- 解决方式：
  1. 给 `flashplayer_sa.exe` 写 AppCompat 标记 `~ HIGHDPIAWARE`；
  2. 用 `bin/winsize.exe` 把窗口设成 1.5x/2x 的**物理像素**尺寸；
  3. 启动器里 `stage.quality = "best"`。

这样 Flash 会直接按 1410×885 渲染（矢量图重新栅格化），而不是渲染
940×590 再被系统拉伸，画面明显更锐利。

启动器可用参数（URL query）：

| 参数 | 作用 |
| --- | --- |
| `q=low/medium/high/best` | 渲染质量，默认 best |
| `fps=1` | 显示 FPS 覆盖层 |
| `smooth=0` | 关闭位图平滑 |
| `auto=1` | 自动测试流程 |

## 七、存档

存档在：

```
%APPDATA%\Macromedia\Flash Player\#SharedObjects\<随机目录>\127.0.0.1\launcher.swf\zmxy3_offline.sol
```

是标准 AMF SharedObject，可以用 FFDec / SolEditor 打开修改
（金币、等级、装备等）。

## 八、常见问题

### 点击关卡后卡在“加载中”

几乎都是缺少该关卡的资源包。打开 `run/server.log`，看最后一次 `404`：

- `stageInfov1620.swf` / `stageCommonv1270.swf` / `petsUniversalv690.swf`
- `N.swf`（第 N 关的关卡包）
- `ROLE1_0.swf` / `ROLE1_EQUIP_0.swf`（角色默认外观）

把缺失文件下载到 `run/` 即可。注意：游戏的加载器在素材 404、重试 3 次后
会**直接停住**，不会跳过，所以必须补齐文件。

重新扫描完整清单并补抓：

```powershell
python build_asset_list.py | Where-Object { $_ -match '\.swf$' } |
  Sort-Object -Unique | Set-Content mirror_names_clean.txt
powershell -File fetch_assets.ps1 -ListFile mirror_names_clean.txt -OutDir run
```

## 九、版权

所有游戏代码、美术、音乐版权归 4399 / 造梦西游团队所有。
本目录仅用于个人学习、研究与存档，请勿传播或商用。
