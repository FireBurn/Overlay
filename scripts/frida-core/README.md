# Bumping frida-core and dev-python/frida

`eclass/frida-core.eclass` pins every subproject of one frida-core release.
`dev-python/frida` builds that frida-core release as a subproject; there is no
separate frida-core package. `dev-util/frida-tools` installs a pure-Python wheel
and bumps on its own, within the range `dev-python/frida` allows it.

1. Unpack the new frida-core tag as `~/frida-build/fc`, put the three `releng`
   gitlinks (`releng`, `releng/meson`, `releng/tomlkit`) in place, and read the
   pinned shas with `gh api repos/frida/frida-core/contents/releng?ref=<tag>`.
2. Run `vendor-loop.sh`: it configures, fetches whichever wrap meson asks for
   with `fetchwrap.sh`, and repeats until configure passes.
3. `list-pins.py > pins.tsv` lists every vendored subproject with its pin.
4. `gen-eclass.py pins.tsv > eclass/frida-core.eclass`, then update the
   releng shas in it and `FRIDA_BINDGEN_REV` in `dev-python/frida`
   (`contents/frida-bindgen?ref=<tag>` of frida-python).
5. Check the patches in `dev-python/frida/files` still apply, rename the
   ebuild, and run `ebuild ... manifest`.

`configure.sh` is the by-hand configuration used to prove a release builds.
