# -*- coding: utf-8 -*-
"""
扫描反编译源码，生成造梦西游3 需要从 CDN 抓取的资源 SWF 清单。
用法: python build_asset_list.py > mirror_names.txt
"""
import os, re, sys

SRC = r"D:\4399\zmxy3\src_gamefile\scripts"

names = set()

# 1. 源码中出现的所有字面量 xxx.swf
for root, dirs, files in os.walk(SRC):
    for fn in files:
        if not fn.endswith(".as"):
            continue
        p = os.path.join(root, fn)
        try:
            t = open(p, encoding="utf-8", errors="ignore").read()
        except Exception:
            continue
        for m in re.finditer(r'"([A-Za-z0-9_\-\.]+\.swf)"', t):
            names.add(m.group(1))
        # Monster 资源名（代码里会拼 "Monster" + id）
        for m in re.finditer(r'\bMonster(\d+)\b', t):
            names.add("Monster%s.swf" % m.group(1))
        # 关卡材质 id 列表（Decrypt 里的裸字符串 + 数字）
        for m in re.finditer(r'loadSwfsWhenStage\w+\s*=\s*\[([^\]]*)\]', t):
            for s in re.findall(r'"([^"]+)"', m.group(1)):
                names.add(s)

# 2. Decrypt.getUrlByAfterName 的映射
dec = os.path.join(SRC, "my", "Decrypt.as")
if os.path.exists(dec):
    t = open(dec, encoding="utf-8", errors="ignore").read()
    for m in re.finditer(r'if\(urlString == "([^"]+)"\)\s*\{\s*urlString = "([^"]+)"', t):
        names.add(m.group(1))
        names.add(m.group(2))

# 3. 角色 / 宠物（Config 里的固定映射）
names.update(["Role1v690.swf", "Role2v3550.swf", "Role3v690.swf", "Role4v3550.swf"])
names.update("%s.swf" % x for x in [
    "nianv1040", "monkeyv690", "horsev680", "tigressv680", "turtlev680",
    "phoenixv680", "dragonv680", "rabbitv680", "ufov680", "mousev790",
    "neat", "roomhorse", "yintiger",
])

# 4. 装备贴图：ROLE<n>_<showid>.swf / ROLE<n>_EQUIP_<showid>.swf
eq = os.path.join(SRC, "my", "AllEquipment.as")
role_map = {"悟空": "ROLE1", "唐僧": "ROLE2", "八戒": "ROLE3", "沙僧": "ROLE4"}
cloth_types = {"zbfj", "zbfb"}
weapon_types = {"zbwq", "zbwp"}
if os.path.exists(eq):
    t = open(eq, encoding="utf-8", errors="ignore").read()
    pat = re.compile(r'new MyEquipObj\(\s*(\d+)\s*,\s*"[^"]*"\s*,\s*[^,]+\s*,\s*"(\w+)"\s*,\s*"([^"]*)"')
    for m in pat.finditer(t):
        sid, typ, role = m.group(1), m.group(2), m.group(3)
        prefix = role_map.get(role)
        if not prefix:
            continue
        if typ in cloth_types:
            names.add("%s_%s.swf" % (prefix, sid))
        elif typ in weapon_types:
            names.add("%s_EQUIP_%s.swf" % (prefix, sid))
            if prefix == "ROLE4":
                names.add("ROLE4_SHOVEL_%s.swf" % sid)
                names.add("ROLE4_ARROW_%s.swf" % sid)

# 5. 保险：怪物编号区间
for i in range(1, 261):
    names.add("Monster%d.swf" % i)

# 6. 裸资源名（Decrypt 数组里的数字 / 名字）统一补 .swf
extra = set()
for n in list(names):
    if not n.endswith(".swf"):
        extra.add(n + ".swf")
names |= extra

# 过滤明显不是资源的
bad_prefix = ("http", "www.", "E:")
names = {n for n in names if not n.startswith(bad_prefix)}

for n in sorted(names):
    print(n)
