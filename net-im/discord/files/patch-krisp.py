#!/usr/bin/env python3
# Bypass the "signed by Discord" check in discord_krisp.node so that Krisp
# works when Discord runs on a host binary that Discord has not signed
# (e.g. the system Electron).
#
# discord::util::IsSignedByDiscord() computes the MD5 of the host executable
# and compares it against a hardcoded hash of the official Discord binary.
# The comparison ends with:
#
#     cmp    $0xffff,%eax
#     sete   %bpl
#     mov    %ebp,%eax      # return value
#
# This rewrites the last two instructions to `mov $0x1,%eax; nop`, making
# the check always pass.
import sys

ORIG = bytes.fromhex("3dffff0000400f94c589e8")
PATCHED = bytes.fromhex("3dffff0000b80100000090")


def main(path):
    with open(path, "rb") as f:
        data = f.read()

    if data.count(ORIG) == 1:
        with open(path, "wb") as f:
            f.write(data.replace(ORIG, PATCHED))
        print("patched")
        return 0
    if data.count(PATCHED) == 1:
        print("already patched")
        return 0
    print(f"error: expected exactly one occurrence of the signature check, "
          f"found {data.count(ORIG)} (module layout changed?)", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
