# dev-java/openjdk-bin

Slotted per major version (`SLOT="$(ver_cut 1)"`).

1. Maintain one ebuild per slot for **all LTS releases** (8, 11, 17, 21, 25, and any newer LTS) **and the latest GA release** (currently 27), so `dev-java/openjdk` can bootstrap every slot. Do not drop an LTS slot, and do not add `_alpha`/`_beta` pre-releases.
2. Compare against `/var/db/repos/gentoo/dev-java/openjdk-bin/` for each slot, keeping the overlay's `elibc_llvm` (Alpine/musl Temurin tarball) handling, `KEYWORDS="-* ~amd64"`, and `IUSE="... elibc_llvm"`.
3. Validate each changed or added slot with `sudo -n ebuild <ebuild> manifest`, `emerge -1 =dev-java/openjdk-bin-<ver>`, a smoke test (`java -version`), and `pkgcheck scan --repo FireBurn --commits`.
