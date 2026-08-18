EAPI=8

inherit cmake git-r3

DESCRIPTION="NPU-first runtime built exclusively for Ryzen AI"
HOMEPAGE="https://github.com/ROCm/FastFlowLM"
EGIT_REPO_URI="https://github.com/ROCm/FastFlowLM.git"
EGIT_SUBMODULES=( '*' )

LICENSE="MIT"
SLOT="0"

KEYWORDS="-* ~amd64"

DEPEND="
	dev-libs/boost:=
	net-misc/curl
	media-video/ffmpeg:=
	sci-libs/fftw:=
	sys-libs/readline:=
	sys-libs/ncurses:=
	dev-libs/xrt
"
RDEPEND="${DEPEND}"
BDEPEND="
	virtual/pkgconfig
	dev-lang/rust
"

RESTRICT="network-sandbox"

CMAKE_USE_DIR="${S}/src"

src_configure() {
	local mycmakeargs=(
		-DFLM_VERSION="9999"
		-DNPU_VERSION="9999"
		-DFLM_PORTABLE_BUILD=OFF
	)
	
	cmake_src_configure
}


