import os, re, glob
root = os.path.expanduser("~/frida-build/fc")
out = []
for dp, dn, fn in os.walk(root):
    if "/build" in dp.replace(root, "", 1)[:7] or dp.startswith(root + "/build"):
        dn[:] = []; continue
    if "/releng" in dp[len(root):]: dn[:] = []; continue
    if os.path.basename(dp) != "subprojects": continue
    for w in fn:
        if not w.endswith(".wrap"): continue
        t = open(os.path.join(dp, w)).read()
        if "wrap-redirect" in t: continue
        name = w[:-5]
        d = re.search(r"^directory *= *(.+)$", t, re.M)
        d = d.group(1).strip() if d else name
        full = os.path.join(dp, d)
        if not os.path.isdir(full) or not os.listdir(full): continue
        if not re.search(r"^(url|source_url) *=", t, re.M): print("NOURL", os.path.join(dp, w)); print(t); continue
        m = re.search(r"^url *= *(.+)$", t, re.M)
        if m:
            u = m.group(1).strip(); r = re.search(r"^revision *= *(.+)$", t, re.M).group(1).strip()
        else:
            u = re.search(r"^source_url *= *(.+)$", t, re.M).group(1).strip(); r = "FILE:" + re.search(r"^source_hash *= *(.+)$", t, re.M).group(1).strip()
        extra = re.findall(r"^(patch_\w+|diff_files) *=", t, re.M)
        out.append((os.path.relpath(full, root), u, r, ",".join(extra)))
for o in sorted(out): print("\t".join(o))
