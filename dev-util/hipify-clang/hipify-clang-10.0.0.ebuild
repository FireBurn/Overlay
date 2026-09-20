# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( 23 )

inherit cmake llvm-r2

MY_P=HIPIFY-therock-10.0

DESCRIPTION="A set of tools to translate CUDA source code into portable HIP C++"
HOMEPAGE="https://github.com/ROCm/HIPIFY"
if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/ROCm/HIPIFY"
	inherit git-r3
	S="${WORKDIR}/${P}"
else
	SRC_URI="https://github.com/ROCm/HIPIFY/archive/refs/tags/therock-10.0.tar.gz -> ${MY_P}.tar.gz"
	S="${WORKDIR}/${MY_P}"
	KEYWORDS="~amd64"
fi

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"

PATCHES=(
	"${FILESDIR}/${PN}-10.0.0-link-clang-cpp.patch"
)

# upstream CMake adds a $ORIGIN/../lib RUNPATH to hipify-clang
QA_FLAGS_IGNORED="/usr/bin/hipify-clang"

DEPEND="
	$(llvm_gen_dep "
		llvm-core/clang:\${LLVM_SLOT}=
		llvm-core/llvm:\${LLVM_SLOT}=
	")
"
RDEPEND="${DEPEND}"

src_configure() {
	# 928906: CMakeLists.txt ignores CC/CXX, switches compiler to clang
	# and fails if non-compatible CFLAGS/CXXFLAGS are used
	strip-unsupported-flags

	local mycmakeargs=(
		-DCMAKE_PREFIX_PATH="$(get_llvm_prefix)"
		-DHIPIFY_CLANG_TESTS=OFF
	)

	cmake_src_configure
}
