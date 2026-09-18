#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Point Discord's app.asar at its own resources directory.

Discord reads process.resourcesPath, which Electron sets to its own
installation. The loader in resources/app overrides it for the main process,
but preload scripts run elsewhere and see the real value, so the string is
rewritten in the archive to read an environment variable the launcher sets.

The replacement is the same length as the original, so every offset in the
archive stays valid; only the integrity hashes are recalculated, and those
are hex strings of a fixed length too.  That length is also why the variable
has such a short name: "process.env." leaves nine characters for it.

Usage: asar-resources-path.py <app.asar>
"""

import hashlib
import json
import struct
import sys

OLD = b"process.resourcesPath"
NEW = b"process.env.DISCORD_R"
assert len(OLD) == len(NEW), "the replacement must not change any offset"

path = sys.argv[1]
data = bytearray(open(path, "rb").read())

# uint32 sizes, then the JSON header, padded to a multiple of 4
header_size = struct.unpack("<I", data[12:16])[0]
header_start = 16
header_end = header_start + header_size
header = json.loads(bytes(data[header_start:header_end]).decode("utf8").rstrip("\0"))
content_start = header_end + (-header_end % 4)


def files(node, path=""):
    for name, entry in node.get("files", {}).items():
        if "files" in entry:
            yield from files(entry, f"{path}/{name}")
        else:
            yield f"{path}/{name}", entry


patched = 0
for name, entry in files(header):
    if "offset" not in entry:
        continue
    start = content_start + int(entry["offset"])
    end = start + entry["size"]
    content = bytes(data[start:end])
    if OLD not in content:
        continue

    content = content.replace(OLD, NEW)
    data[start:end] = content
    patched += 1

    integrity = entry.get("integrity")
    if not integrity:
        continue
    # Replace each hash in place: same algorithm, so same hex length
    block_size = integrity["blockSize"]
    new_blocks = [
        hashlib.sha256(content[i:i + block_size]).hexdigest()
        for i in range(0, len(content), block_size)
    ]
    old_hashes = [integrity["hash"], *integrity["blocks"]]
    new_hashes = [hashlib.sha256(content).hexdigest(), *new_blocks]
    if len(old_hashes) != len(new_hashes):
        sys.exit(f"{name}: block count changed, refusing to patch")
    for old, new in zip(old_hashes, new_hashes):
        index = data.index(old.encode(), header_start, header_end)
        data[index:index + len(old)] = new.encode()

if not patched:
    sys.exit(f"{path}: {OLD.decode()} not found")

open(path, "wb").write(bytes(data))
print(f"patched {patched} file(s) in {path}")
