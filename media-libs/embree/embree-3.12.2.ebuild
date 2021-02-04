# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

inherit cmake-utils

DESCRIPTION="Embree ray tracing kernels by intel"
HOMEPAGE="https://embree.github.io"

if [[ "$PV" == "9999" ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/embree/embree.git"
else
	SRC_URI="https://github.com/embree/embree/archive/v${PV}.tar.gz -> ${P}.tar.gz"
fi


LICENSE="Apache-2.0"
SLOT="3"
KEYWORDS="amd64"
IUSE="+ispc tutorials +tbb
	cpu_flags_x86_sse2 cpu_flags_x86_sse4_2 cpu_flags_x86_avx cpu_flags_x86_avx2
	cpu_flags_x86_avx512f cpu_flags_x86_avx512cd
	cpu_flags_x86_avx512er cpu_flags_x86_avx512pf
	cpu_flags_x86_avx512vl cpu_flags_x86_avx512dq cpu_flags_x86_avx512bw"

RDEPEND="
	>=media-libs/glfw-3
	ispc? ( dev-lang/ispc )
	tbb? ( dev-cpp/tbb )
	"
DEPEND="${RDEPEND}"

src_configure() {
	local mycmakeargs=(
		-DEMBREE_ISPC_SUPPORT=$(usex ispc)
                -DEMBREE_TUTORIALS=$(usex tutorials)
                -DEMBREE_TASKING_SYSTEM=$(usex tutorials)
                -DEMBREE_MAX_ISA=NONE
                -DEMBREE_ISA_SSE2=$(usex cpu_flags_x86_sse2)
                -DEMBREE_ISA_SSE42=$(usex cpu_flags_x86_sse4_2)
                -DEMBREE_ISA_AVX=$(usex cpu_flags_x86_avx)
                -DEMBREE_ISA_AVX2=$(usex cpu_flags_x86_avx2)
                -DEMBREE_ISA_AVX512KNL=$(usex cpu_flags_x86_avx512f && usex cpu_flags_x86_avx512cd && usex cpu_flags_x86_avx512er && usex cpu_flags_x86_avx512pf)
                -DEMBREE_ISA_AVX512SKX=$(usex cpu_flags_x86_avx512f && usex cpu_flags_x86_avx512cd && usex cpu_flags_x86_avx512vl && usex cpu_flags_x86_avx512dq && usex cpu_flags_x86_avx512bw)
        )
	if use tbb ; then
		mycmakeargs+=(
			-DEMBREE_TASKING_SYSTEM=TBB
		)
	else
		mycmakeargs+=(
			-DEMBREE_TASKING_SYSTEM=INTERNAL
		)
	fi
	if use ispc ; then
		mycmakeargs+=(
			-DEMBREE_ISPC_SUPPORT=ON
		)
	else
		mycmakeargs+=(
			-DEMBREE_ISPC_SUPPORT=OFF
		)
	fi
#	mycmakeargs="${mycmakeargs}
#		  -DCMAKE_INSTALL_PREFIX=/usr
#		  -DCMAKE_BUILD_TYPE=Release
#		  -DENABLE_TUTORIALS=OFF
#		  -DTBB_ROOT=/usr"
	cmake-utils_src_configure
}

