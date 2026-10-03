# dev-lang/rust

Coupled files: `dev-lang/rust/rust-<ver>.ebuild`, `dev-lang/rust/Manifest`, `eclass/rust.eclass`, `dev-lang/rust/files/`.

1. Check `/usr/portage/dev-lang/rust` and `/usr/portage/eclass/rust.eclass` for the new version first. Port what it changed (new patch set, `RUST_MIN_VER`, bootstrap versions, config keys) rather than rediscovering it.
2. `git mv` the old ebuild, then bump `RUST_MAX_VER`/`RUST_PV` handling if the filename scheme changed. `RUST_PATCH_VER`: if `https://gitweb.gentoo.org/proj/rust-patches.git/snapshot/rust-patches-<ver>.tar.bz2` does not exist (HTTP 404), keep the newest existing patch set and say so in a comment.
3. `eclass/rust.eclass`: add the version to `_RUST_LLVM_MAP` with the LLVM slots the release supports (read `src/llvm-project` version and `src/bootstrap` minimum in the release tarball). Check that the `RUST_MIN_VER` bootstrap compiler chain is satisfiable from this overlay or Gentoo.
4. Patches in `files/<ver>/` may be obsolete; try them with `ebuild ... prepare` and drop any that upstream merged. Carry LLVM compatibility patches only if the build needs them.
5. Config keys change between releases. Diff `bootstrap.example.toml` of the old and new tarball against the keys the ebuild writes in `src_configure` (for example `use-lld` became `bootstrap-override-lld`).
6. Use only the release tarball (`rustc-<ver>-src.tar.xz`) and its `.asc`. Never overlay a tag tarball or other source.
7. The build takes about 60-90 minutes: `ebuild <ebuild> clean`, then `setsid nohup ebuild <ebuild> compile`; resume with `compile` after a fix. Check `temp/build.log` for ` * ERROR:` and the error text above it. Finish with `sudo ebuild <ebuild> install qmerge`, then smoke test `rustc --version`, `cargo --version`, and compile a hello world.
8. Commits: `dev-lang/rust: bump to <ver>` and, separately, `eclass/rust.eclass: add <ver> to the LLVM map` (eclass first if the ebuild depends on it).
9. Always run `sudo -n ebuild <ebuild> clean` (Portage's work dir is owned by portage; without sudo the clean fails silently). A work dir left over from an earlier attempt gives hybrid sources and misleading errors such as a vendored crate version mismatch. After any failure that mentions a crate version, a missing vendored crate or `--locked`/`--frozen`, check `stat -c %y work/*/Cargo.lock` against the tarball date and re-unpack clean before suspecting the tarball.
