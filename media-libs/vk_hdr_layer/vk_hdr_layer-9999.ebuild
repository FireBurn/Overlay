# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson git-r3

EGIT_REPO_URI="https://github.com/Zamundaaa/VK_hdr_layer.git"
EGIT_SUBMODULES=( '-*' )
DESCRIPTION="Vulkan layer utilizing a small color management HDR protocol for experimentation"
HOMEPAGE="https://github.com/Zamundaaa/VK_hdr_layer"

RDEPEND="dev-libs/wayland
		media-libs/vkroots
		media-libs/vulkan-loader
		x11-libs/libX11"
DEPEND="${RDEPEND}
		dev-util/vulkan-headers
		dev-util/wayland-scanner"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
