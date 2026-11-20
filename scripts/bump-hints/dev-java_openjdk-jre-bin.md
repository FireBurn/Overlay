# dev-java/openjdk-jre-bin

Slotted per major version (`SLOT="${MY_SLOT}"`).

1. Maintain one ebuild per slot for **all LTS releases** (8, 11, 17, 21, 25, and any newer LTS) **and the latest GA release** when upstream/Gentoo provides a JRE binary for it. Do not drop an LTS slot.
2. Compare against `/var/db/repos/gentoo/dev-java/openjdk-jre-bin/` for each slot, keeping the overlay's `elibc_llvm` (Alpine/musl Temurin tarball) handling, `KEYWORDS="-* ~amd64"`, and `IUSE="... elibc_llvm"`.
3. Validate each changed or added slot with `sudo -n ebuild <ebuild> manifest`, `emerge -1 =dev-java/openjdk-jre-bin-<ver>`, a smoke test (`java -version`), and `pkgcheck scan --repo FireBurn --commits`.
