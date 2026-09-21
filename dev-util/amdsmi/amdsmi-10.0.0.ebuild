# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
ROCM_SKIP_GLOBALS=1
inherit cmake linux-info python-r1 rocm

DESCRIPTION="AMD System Management Interface for managing and monitoring GPUs"
HOMEPAGE="
	https://github.com/ROCm/rocm-systems/tree/develop/projects/amdsmi
	https://rocm.docs.amd.com/projects/amdsmi/en/latest/
"
if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/ROCm/rocm-systems.git"
	EGIT_SUBMODULES=()
	inherit git-r3
	S="${WORKDIR}/${P}/projects/amdsmi"
else
	SRC_URI="https://github.com/ROCm/rocm-systems/releases/download/therock-10.0/${PN}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}"
	KEYWORDS="~amd64"
fi

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"

IUSE="test"
RESTRICT="!test? ( test )"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

CONFIG_CHECK="~HSA_AMD ~DRM_AMDGPU"

RDEPEND="
	${PYTHON_DEPS}
	x11-libs/libdrm[video_cards_amdgpu]
	dev-libs/libnl
	net-libs/libmnl
"
DEPEND="${RDEPEND}
	test? ( dev-cpp/gtest )
"
BDEPEND="dev-build/rocm-cmake"

src_prepare() {
	# Compatibility with CMake < 3.10 will be removed
	sed -e "/cmake_minimum_required/ s/3\.5\.0/3.10/" \
		-i goamdsmi_shim/CMakeLists.txt || die

	sed -e "s/-Wall -Wextra//" \
		-i CMakeLists.txt goamdsmi_shim/CMakeLists.txt || die

	# Reset custom installation path
	sed -e "/generic_add_rocm/d" -i CMakeLists.txt || die

	# Remove /usr/lib to fix multilib
	sed -e '/target_link_libraries.*\/lib/d' -i goamdsmi_shim/CMakeLists.txt || die

	# Install docs to correct place
	sed -e "s:doc/\${CPACK_PACKAGE_NAME}:doc/${P}:" -i CMakeLists.txt || die

	# Do not install /usr/share/doc/${P}-asan
	sed -e "s/COMPONENT asan/COMPONENT asan EXCLUDE_FROM_ALL/" -i CMakeLists.txt || die

	cmake_src_prepare
}

src_configure() {
	python_setup

	local mycmakeargs=(
		-DBUILD_TESTS=$(usex test)
		# fetches a pinned commit from the network at configure time
		-DENABLE_ESMI_LIB=OFF
		-Wno-dev
	)
	use test && mycmakeargs+=( -DCMAKE_REQUIRE_FIND_PACKAGE_GTest=ON )
	cmake_src_configure
}

src_test() {
	# GPU access in amdsmitstReadOnly.TestSysInfoRead and amdsmitstReadOnly.TestIdInfoRead
	addwrite /dev/dri/renderD128

	# Few tests fail on ASUS GZ302E: no metrics from kernel?
	GTEST_FILTER="-amdsmitstReadOnly.TempRead:amdsmitstReadOnly.TestFrequenciesRead" \
	"${BUILD_DIR}/tests/amd_smi_test/amdsmitst" || die "Test failed"
}

src_install() {
	cmake_src_install

	# Wrong places
	rm "${ED}"/usr/share/amd_smi/amdsmi/{libamd_smi.so,LICENSE,README.md} || die

	python_fix_shebang "${ED}"/usr/libexec/amdsmi_cli/amdsmi_cli.py
	python_domodule "${ED}"/usr/libexec/amdsmi_cli
	python_domodule "${ED}"/usr/share/amd_smi/amdsmi

	fperms a+x "/usr/lib/${EPYTHON}/site-packages/amdsmi_cli/amdsmi_cli.py"
	# upstream symlink points at the libexec copy
	rm "${ED}"/usr/bin/amd-smi || die
	dosym -r "/usr/lib/${EPYTHON}/site-packages/amdsmi_cli/amdsmi_cli.py" /usr/bin/amd-smi

	rm -rf "${ED}"/usr/share/amd_smi "${ED}"/usr/libexec/amdsmi_cli || die
}
