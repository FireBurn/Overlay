# dev-java/openjdk

Slotted per major version (`SLOT="$(ver_cut 1)"`).

1. Maintain one ebuild per slot for **all LTS releases** (8, 11, 17, 21, 25, and any newer LTS) **and the latest GA release** (currently 27), matching `dev-java/openjdk-bin` and `dev-java/openjdk-jre-bin` (where available) so bootstrapping works. Do not drop an LTS slot, and do not add `_alpha`/`_beta` pre-releases.
2. When adding a new major slot or bumping an existing one, start from `/var/db/repos/gentoo/dev-java/openjdk/` for that version (and copy any new slot patches from `/var/db/repos/gentoo/dev-java/openjdk/files/`). Never copy a different major slot's ebuild (such as copying 17 to 21/25/27), as `SRC_URI`, `PATCHES`, `*_XPAK` bootstrap tarballs, and `econf` flags differ across major versions.
3. Overlay customizations on top of the Gentoo ebuild:
   - `KEYWORDS="~amd64"`
   - Under `elibc_llvm`, ensure `--with-stdc++lib=dynamic` is passed (already unconditional in 21+; guarded by `use elibc_llvm` with `elibc_llvm` in `IUSE` on 17 and earlier) and check whether `openjdk-sysinfo-new-include.patch` or `elibc_llvm` compiler/libc++ patches are needed for that slot.
4. Keep `Manifest` complete for all arches referenced in `SRC_URI` by running `sudo -n ebuild <ebuild> manifest`.
5. Validate each changed or added slot with `emerge -1 =dev-java/openjdk-<ver>`, a smoke test (`java -version` and `javac -version` from the installed VM), and `pkgcheck scan --repo FireBurn --commits`.
