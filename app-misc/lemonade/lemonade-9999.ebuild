EAPI=8

inherit cmake git-r3

DESCRIPTION="Lemonade - Refreshingly fast local AI"
HOMEPAGE="https://github.com/lemonade-sdk/lemonade"
EGIT_REPO_URI="https://github.com/lemonade-sdk/lemonade.git"

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

KEYWORDS="-* ~amd64"

DEPEND="
	dev-cpp/nlohmann_json
	dev-cpp/cli11
	net-misc/curl
	app-arch/zstd
	dev-cpp/cpp-httplib
	net-libs/libwebsockets
	net-libs/mbedtls
	app-misc/jq
"
RDEPEND="${DEPEND}
	sci-libs/fastflowlm
"
BDEPEND="
	virtual/pkgconfig
"

RESTRICT="network-sandbox"

src_configure() {
	local mycmakeargs=(
		-DUSE_SYSTEM_JSON=ON
		-DUSE_SYSTEM_CURL=ON
		-DUSE_SYSTEM_ZSTD=ON
		-DUSE_SYSTEM_CLI11=ON
		-DUSE_SYSTEM_HTTPLIB=ON
		-DUSE_SYSTEM_LWS=ON
	)
	cmake_src_configure
}
