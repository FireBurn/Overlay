# app-editors/zed

Pure cargo package with two extra pins.

1. `git mv` the ebuild to the new version.
2. Download the release tag tarball into the scratch directory and run `python3 scripts/cargo-crates.py <unpacked>/Cargo.lock --ebuild app-editors/zed/zed-<ver>.ebuild`. Review the diff with `git diff -U0`.
3. `WEBRTC_COMMIT`: take it from the `webrtc-sys`/`livekit` build script or Cargo patch section in the new source and update it only if it changed.
4. Check `llvm-r2` slots against the new minimum compiler version in `rust-toolchain.toml` and update `RUST_MIN_VER`/the `LLVM_COMPAT` list if it moved.
5. `sudo -n ebuild <ebuild> manifest`, then `emerge -1 =app-editors/zed-<ver>`. The build is long (30+ minutes): detach it and block on its PID.
6. Smoke test: `zed --version`.
