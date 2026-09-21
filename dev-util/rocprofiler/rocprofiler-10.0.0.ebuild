# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( 23 )
# Ninja rejects duplicate library name-link rules from the V1/V2 libraries.
CMAKE_MAKEFILE_GENERATOR=emake

inherit cmake llvm-r2

PERFETTO_PV=v44.0

DESCRIPTION="ROCm Profiler library and rocprof tool"
HOMEPAGE="https://github.com/ROCm/rocm-systems/tree/develop/projects/rocprofiler"
if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/ROCm/rocm-systems.git"
	EGIT_SUBMODULES=()
	inherit git-r3
	S="${WORKDIR}/${P}/projects/rocprofiler"
else
	SRC_URI="
		https://github.com/ROCm/rocm-systems/releases/download/therock-10.0/${PN}.tar.gz -> ${P}.tar.gz
		https://github.com/google/perfetto/archive/refs/tags/${PERFETTO_PV}.tar.gz -> perfetto-${PERFETTO_PV}.tar.gz
	"
	S="${WORKDIR}/${PN}"
	KEYWORDS="~amd64"
fi
PERFETTO_S="${WORKDIR}/perfetto-${PERFETTO_PV#v}"

LICENSE="Apache-2.0 MIT"
SLOT="0/$(ver_cut 1-2)"

RDEPEND="
	dev-libs/elfutils
	dev-libs/rocm-comgr:${SLOT}
	dev-libs/rocr-runtime:${SLOT}
	dev-util/aqlprofile:${SLOT}
"
DEPEND="
	${RDEPEND}
	dev-util/hip:${SLOT}
"
BDEPEND="
	$(llvm_gen_dep "llvm-core/clang:\${LLVM_SLOT}")
"

src_prepare() {
	# the perfetto submodule is not vendored in the release tarball
	# and would otherwise be git-cloned at configure time
	rm -rf plugin/perfetto/perfetto || die
	mv "${PERFETTO_S}" plugin/perfetto/perfetto || die
	# the checkout check uses a directory as TEST_FILE which never
	# satisfies the exists check, so point it at a real file
	sed -i 's/TEST_FILE "sdk"/TEST_FILE "sdk\/perfetto.cc"/' plugin/perfetto/CMakeLists.txt || die

	# modern libstdc++ ships <filesystem> in the main library
	sed -i 's/stdc++fs//g' $(find . -name CMakeLists.txt) || die

	# upstream force-enables test/CI builds for their CI
	sed -i '/^set(ROCPROFILER_BUILD_TESTS ON)$/d; /^set(ROCPROFILER_BUILD_CI ON)$/d' CMakeLists.txt || die

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DROCM_PATH="${EPREFIX}/usr"
		# requires dev-python/barectf, not in Gentoo
		-DROCPROFILER_BUILD_PLUGIN_CTF=OFF
		-Wno-dev
	)

	cmake_src_configure
}
