# Bumping frida-core, dev-python/frida and dev-libs/frida-core

`eclass/frida-core.eclass` pins every subproject of one frida-core release.
`dev-libs/frida-core` and `dev-python/frida` share it, so both move together;
`dev-util/frida-tools` installs a pure-Python wheel and bumps on its own.

1. Unpack the new frida-core tag as `~/frida-build/fc`, put the three `releng`
   gitlinks (`releng`, `releng/meson`, `releng/tomlkit`) in place, and read the
   pinned shas with `gh api repos/frida/frida-core/contents/releng?ref=<tag>`.
2. Run `vendor-loop.sh`: it configures, fetches whichever wrap meson asks for
   with `fetchwrap.sh`, and repeats until configure passes.
3. `list-pins.py > pins.tsv` lists every vendored subproject with its pin.
4. `gen-eclass.py pins.tsv > eclass/frida-core.eclass`, then update the
   releng shas in it and `FRIDA_BINDGEN_REV` in `dev-python/frida`
   (`contents/frida-bindgen?ref=<tag>` of frida-python).
5. Check the patches in `dev-libs/frida-core/files` still apply, rename both
   ebuilds, and run `ebuild ... manifest`.

`configure.sh` is the by-hand configuration used to prove a release builds.
