# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Google's agentic development platform (CLI companion)"
HOMEPAGE="https://antigravity.google/ https://github.com/google-antigravity/antigravity-cli"

SRC_URI="
	amd64? ( https://github.com/google-antigravity/antigravity-cli/releases/download/${PV}/agy_cli_linux_x64.tar.gz )
	arm64? ( https://github.com/google-antigravity/antigravity-cli/releases/download/${PV}/agy_cli_linux_arm64.tar.gz )
"

# Tarball unpacks the bare files without a root directory
S="${WORKDIR}"

LICENSE="Google-TOS"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="bindist mirror strip"

# Prevent QA warnings regarding pre-stripped Go binaries
QA_PREBUILT="usr/bin/agy"

RDEPEND="sys-libs/glibc"
BDEPEND=""

src_install() {
	# Install the 'antigravity' Go binary to /usr/bin/antigravity
	dobin antigravity

	# Include documentation/licenses if present in the fetched tarball
	[[ -f LICENSE ]] && dodoc LICENSE
	[[ -f README.md ]] && dodoc README.md
}

pkg_postinst() {
	elog "Google Antigravity CLI has been installed successfully."
	elog "To launch the Terminal User Interface (TUI), execute:"
	elog ""
	elog "    antigravity"
	elog ""
	elog "Features available in version ${PV}:"
	elog " - Local workspace and multi-agent orchestration"
	elog " - Model Context Protocol (MCP) server support"
	elog " - Support for custom skills via Markdown"
	elog ""
	elog "Note: The first time you launch 'agy', it will prompt you to authorize"
	elog "via your system keyring or a Google OAuth browser sign-in."
}
