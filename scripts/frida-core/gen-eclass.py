import re, sys

pins = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip()]
extra = [
    ("releng", "https://github.com/frida/releng.git", "164a6a41179c38481e6afa4303abb92c9234ea2c"),
    ("releng/meson", "https://github.com/frida-forks/meson.git", "145667c57ed2649ddcc6fbb11b6008e0d451df1d"),
    ("releng/tomlkit", "https://github.com/python-poetry/tomlkit.git", "911cccd630965ff423316e25b4685ecf7df0ec0a"),
]
items = [(p[0], p[1], p[2]) for p in pins] + extra


def archive(url, rev):
    url = url.removesuffix(".git")
    m = re.match(r"https://github\.com/([^/]+)/([^/]+)$", url)
    if m:
        owner, repo = m.groups()
        if re.fullmatch(r"[0-9a-f]{40}", rev):
            return f"{url}/archive/{rev}.tar.gz", f"{owner}-{repo}-{rev}.tar.gz"
        return f"{url}/archive/refs/tags/{rev}.tar.gz", f"{owner}-{repo}-{rev}.tar.gz"
    m = re.match(r"https://gitlab\.gnome\.org/GNOME/([^/]+)$", url)
    return f"{url}/-/archive/{rev}/{m.group(1)}-{rev}.tar.gz", f"gnome-{m.group(1)}-{rev}.tar.gz"


uri, table = [], []
for path, url, rev in items:
    u, name = archive(url, rev)
    uri.append(f"\t{u} -> {name}")
    table.append(f'\t"{path} {name}"')

nl = "\n"
print(f'''# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: frida-core.eclass
# @MAINTAINER:
# Mike Lothian <fireburn@gentoo.org>
# @SUPPORTED_EAPIS: 8
# @BLURB: Sources and build options shared by frida-core and its consumers
# @DESCRIPTION:
# frida-core pins every subproject by git revision and its build runs with
# downloads disabled, so each pin is a distfile of its own. This eclass holds
# the pins of one frida-core release, unpacks them into a tree, and carries
# the meson options that make the tree build offline against bundled copies of
# glib and capstone. Bump FRIDA_CORE_PV together with the pins, which are
# regenerated from the wrap files of the release.

case ${{EAPI}} in
	8) ;;
	*) die "${{ECLASS}}: EAPI ${{EAPI:-0}} not supported" ;;
esac

if [[ -z ${{_FRIDA_CORE_ECLASS}} ]]; then
_FRIDA_CORE_ECLASS=1

# @ECLASS_VARIABLE: FRIDA_CORE_PV
# @DESCRIPTION:
# The frida-core release that the pins below belong to.
FRIDA_CORE_PV=17.26.2

# @ECLASS_VARIABLE: FRIDA_CORE_SRC_URI
# @DESCRIPTION:
# The frida-core release tarball and every pinned subproject.
FRIDA_CORE_SRC_URI="
	https://github.com/frida/frida-core/archive/refs/tags/${{FRIDA_CORE_PV}}.tar.gz -> frida-core-${{FRIDA_CORE_PV}}.tar.gz
{nl.join(uri)}
"

# @ECLASS_VARIABLE: FRIDA_CORE_FILESDIR
# @DESCRIPTION:
# Directory holding the patches that frida-core needs.
FRIDA_CORE_FILESDIR=${{EBUILD%/*/*/*}}/dev-libs/frida-core/files

# @ECLASS_VARIABLE: FRIDA_CORE_PATCHES
# @DESCRIPTION:
# Patches to apply to the unpacked tree, in order, relative to its root.
FRIDA_CORE_PATCHES=(
	"${{FRIDA_CORE_FILESDIR}}"/libunwind-include-immintrin-for-shstk.patch
	"${{FRIDA_CORE_FILESDIR}}"/gum-pthread-from-ptr-integer-pthread_t.patch
	"${{FRIDA_CORE_FILESDIR}}"/gum-module-handle-llvm-libc-uses-dlopen.patch
	"${{FRIDA_CORE_FILESDIR}}"/libc-shim-stdio-streams-not-const.patch
)

# @ECLASS_VARIABLE: FRIDA_CORE_DEPEND
# @DESCRIPTION:
# Libraries that the bundled build still takes from the system.
FRIDA_CORE_DEPEND="
	app-arch/brotli
	app-arch/xz-utils
	dev-libs/elfutils
	dev-libs/libffi
	dev-libs/libpcre2
	dev-libs/openssl:=
	dev-db/sqlite
	net-libs/libpsl
	net-libs/nghttp2:=
	virtual/zlib:=
"

# @ECLASS_VARIABLE: FRIDA_CORE_BDEPEND
# @DESCRIPTION:
# Build tools that the tree needs.
FRIDA_CORE_BDEPEND="
	dev-lang/vala:0.58
	virtual/pkgconfig
"

# <directory inside the tree> <distfile>
_FRIDA_PINS=(
{nl.join(table)}
)

# @FUNCTION: frida-core_unpack
# @USAGE: <destination>
# @DESCRIPTION:
# Unpack the frida-core release into the destination directory and put every
# pinned subproject in its place.
frida-core_unpack() {{
	local dest=$1 i dir dist
	mkdir -p "${{dest}}" || die
	tar -xzf "${{DISTDIR}}/frida-core-${{FRIDA_CORE_PV}}.tar.gz" -C "${{dest}}" \\
		--strip-components=1 || die "unpacking frida-core"

	for ((i = 0; i < ${{#_FRIDA_PINS[@]}}; i++)); do
		set -- ${{_FRIDA_PINS[i]}}
		dir=${{dest}}/$1 dist=$2
		rm -rf "${{dir}}" || die
		mkdir -p "${{dir}}" || die
		tar -xzf "${{DISTDIR}}/${{dist}}" -C "${{dir}}" --strip-components=1 \\
			|| die "unpacking ${{dist}}"
	done
}}

# @FUNCTION: frida-core_patch
# @USAGE: <tree>
# @DESCRIPTION:
# Apply the frida-core patches to a tree made by frida-core_unpack.
frida-core_patch() {{
	eapply -d "$1" "${{FRIDA_CORE_PATCHES[@]}}"
}}

# @FUNCTION: frida-core_setup_env
# @DESCRIPTION:
# Environment for the build. The devkit is an ar archive of every object in
# the tree, which cannot hold LTO bitcode, and LTO_SELF keeps a site-wide
# -flto out of CFLAGS.
frida-core_setup_env() {{
	export LTO_SELF=1
	filter-lto

	export FRIDA_VERSION=${{FRIDA_CORE_PV}}
	export VALAC=${{BROOT}}/usr/bin/valac-0.58
}}

# @FUNCTION: frida-core_emesonargs
# @USAGE: <prefix>
# @DESCRIPTION:
# Fill FRIDA_CORE_EMESONARGS with the meson options for frida-core. The prefix
# is empty when frida-core is the project and "frida-core:" when it is a
# subproject. The bundled glib and capstone replace the system ones: the
# system capstone declares bpf_insn as an enum, which libbpf redefines.
frida-core_emesonargs() {{
	local p=$1
	FRIDA_CORE_EMESONARGS=(
		-Db_lto=false
		-Ddefault_library=static
		-D${{p}}fruity_backend=disabled
		-D${{p}}droidy_backend=enabled
		-D${{p}}simmy_backend=disabled
		-D${{p}}barebone_backend=disabled
		-D${{p}}connectivity=disabled
		-D${{p}}portal=disabled
		-D${{p}}gadget=disabled
		-D${{p}}inject=disabled
		-D${{p}}server=disabled
		-D${{p}}compat=disabled
		-D${{p}}devkits=core
		-D${{p}}tests=disabled
		-D${{p}}compiler_backend=disabled
		-Dfrida-gum:v8=disabled
		-Dfrida-gum:quickjs=enabled
		-Dfrida-gum:database=disabled
		-Dfrida-gum:gumpp=disabled
		-Dfrida-gum:tests=disabled
		-Dglib:introspection=disabled
	)
}}

fi
''')
