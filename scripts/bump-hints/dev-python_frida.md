# dev-python/frida

Coupled files: `dev-python/frida/frida-<ver>.ebuild`, `dev-python/frida/Manifest`, `dev-python/frida/files/`, `eclass/frida-core.eclass`, `dev-lang/vala` (the Frida snapshot), `dev-util/frida-tools`.

`dev-python/frida` builds the matching frida-core release as a meson subproject; there is no separate frida-core package. `eclass/frida-core.eclass` pins every subproject of that release, and `FRIDA_CORE_PV` must equal the ebuild's `PV`.

1. Follow `scripts/frida-core/README.md` to regenerate the eclass for the new tag, then update the releng shas and `FRIDA_BINDGEN_REV`. If the eclass already pins the newest release, there is nothing to do: report it and stop.
2. The patches in `dev-python/frida/files` carry the llvm-libc and clang fixes. Check them with `sudo -n ebuild <ebuild> clean prepare` before the full build.
3. Rename the ebuild, `sudo -n ebuild <ebuild> manifest`, then `emerge -1 =dev-python/frida-<ver>`. Smoke test: `python3 -c 'import frida; print(frida.__version__)'`.
4. `dev-lang/vala` follows the vala pin in `releng/deps.toml` of the new release; bump it in its own commit when the pin changed.
5. `dev-util/frida-tools` is a separate pypi wheel and has its own bump. Its dependency range on `dev-python/frida` may need widening. The `tools` USE flag (default on) of `dev-python/frida` pulls it in through PDEPEND.
