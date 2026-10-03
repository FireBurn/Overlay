# dev-util/codex

Pure cargo package; the bump is mechanical unless `Cargo.lock` adds a git dependency or the rusty_v8 pin moves.

1. `git mv` the ebuild to the new version (this drops any `-rN`; carry its downstream edits such as the daemon auto-start change).
2. Download `https://github.com/openai/codex/archive/rust-v<ver>.tar.gz` into the scratch directory, unpack it there and run `python3 scripts/cargo-crates.py <unpacked>/codex-rs/Cargo.lock --ebuild dev-util/codex/codex-<ver>.ebuild`. It rewrites `CRATES` and `GIT_CRATES` in place. Check `git diff -U0` shows only the expected crate changes.
3. `RUSTY_V8_TAG`: read it from the `v8` entry in `codex-rs/Cargo.lock` (the `v8` crate version) and compare with the ebuild. Only change it if they differ.
4. `sudo -n ebuild <ebuild> manifest`, then `emerge -1 =dev-util/codex-<ver>`. A cold build takes about 15 minutes; run it detached and block on its PID.
5. Smoke test: `codex --version`.
