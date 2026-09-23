# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Print AMDGPU_TARGETS for the AMD GPUs in this system"
HOMEPAGE="https://github.com/FireBurn/Overlay"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="app-alternatives/awk"

src_install() {
	dobin "${FILESDIR}"/amdgpu2targets
}
