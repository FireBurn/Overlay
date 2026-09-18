# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="Model Context Protocol (MCP) server for Ghidra via PyGhidra"
HOMEPAGE="https://github.com/clearbluejar/pyghidra-mcp https://pypi.org/project/pyghidra-mcp/"
SRC_URI="https://github.com/clearbluejar/pyghidra-mcp/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="test"

RDEPEND="
	>=dev-python/click-8.2.1[${PYTHON_USEDEP}]
	>=dev-python/click-option-group-0.5.9[${PYTHON_USEDEP}]
	>=dev-python/mcp-1.26.0[${PYTHON_USEDEP}]
	<dev-python/mcp-2[${PYTHON_USEDEP}]
	>=dev-python/pyghidra-2.2.1[${PYTHON_USEDEP}]
	>=dev-python/ghidrecomp-0.5.8[${PYTHON_USEDEP}]
"
BDEPEND="
	dev-python/hatchling[${PYTHON_USEDEP}]
"

PATCHES=(
	"${FILESDIR}/${P}-optional-chromadb.patch"
)

src_prepare() {
	default

	# chromadb is optional (see the patch), and only the mcp server API is
	# used, not the [cli] extra
	sed -i -e '/chromadb/d' \
		-e 's/mcp\[cli\]/mcp/' \
		pyproject.toml || die
}
