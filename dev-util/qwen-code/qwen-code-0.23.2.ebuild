# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit wrapper

DESCRIPTION="The open source AI coding agent for the terminal by Qwen"
HOMEPAGE="https://github.com/QwenLM/qwen-code"

URI_BASE="https://github.com/QwenLM/qwen-code/releases/download/v${PV}"
SRC_URI="
	amd64? (
		${URI_BASE}/qwen-code-linux-x64.tar.gz
			-> ${P}-linux-x64.tar.gz
	)
	arm64? (
		${URI_BASE}/qwen-code-linux-arm64.tar.gz
			-> ${P}-linux-arm64.tar.gz
	)
"

S="${WORKDIR}/qwen-code"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="mirror strip"

QA_PREBUILT="opt/${PN}/*"

RDEPEND="
	dev-vcs/git
"

src_install() {
	insinto /opt/${PN}
	doins -r bin lib node manifest.json

	fperms +x /opt/${PN}/bin/qwen
	fperms +x /opt/${PN}/node/bin/node
	fperms +x /opt/${PN}/node/bin/npm
	fperms +x /opt/${PN}/node/bin/npx
	fperms +x /opt/${PN}/node/bin/corepack

	find "${ED}/opt/${PN}" -type f -name rg -exec chmod +x {} + 2>/dev/null || die

	make_wrapper qwen "${EPREFIX}/opt/${PN}/bin/qwen"

	einstalldocs
}
