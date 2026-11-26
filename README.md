# 造梦西游3 完全本地离线版

4399《造梦西游3 大闹天庭篇》的本地离线运行版：不联网、不需要 4399 账号，
双击 `start.bat` 即可游玩，存档保存在本地。

## 快速开始

1. 安装 Python 3（用于本地静态服务）；
2. 准备 Flash Player 独立播放器 `flashplayer_sa.exe`，
   放到 `D:\4399\tools\flashplayer_sa.exe`（或修改 `start.ps1` 里的路径）；
3. 双击 `start.bat`。

启动后：

- 本地服务：`http://127.0.0.1:8765`
- 游戏窗口：Flash Player 独立播放器
- 存档：`%APPDATA%\Macromedia\Flash Player\#SharedObjects\...\127.0.0.1\launcher.swf\zmxy3_offline.sol`

## 目录

| 路径 | 说明 |
| --- | --- |
| `run/` | 运行目录：启动器 + 游戏主 SWF + 全部资源 |
| `offline/src/` | 离线启动器源码（AS3） |
| `src_gamefile/` | 游戏主 SWF 反编译源码（1104 个 .as） |
| `src_v261029/` | 4399 外层壳反编译源码 |
| `game_offline.swf` | 打过离线补丁的主 SWF |
| `BUILD.md` | 原理、构建、修改说明 |
| `build_asset_list.py` | 从源码生成资源清单 |
| `fetch_assets.ps1` | 批量抓取资源 |

## 原理

游戏逻辑与 4399 平台通过 `GMain.setHold(hold)` 解耦。离线版：

1. 把 `save.api.4399.com` 的取时间接口等长替换为本地 `/time`；
2. 把 `Config.checkWebUid()` 改成恒返回 `true`；
3. 注入 `LocalHold`：假账号 + `SharedObject` 存档，充值/排行/公会空实现。

## 说明

游戏代码、美术、音乐版权归 4399 / 造梦西游团队所有。
本仓库仅用于个人学习、研究与存档，请勿用于商业用途。
