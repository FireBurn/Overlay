# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="AMD XDNA user space driver and kernel module"
HOMEPAGE="https://github.com/amd/xdna-driver"
EGIT_REPO_URI="${HOMEPAGE}.git"
SRC_URI="https://github.com/Xilinx/VTD/raw/5f7fec23620be7a3984c8970bc514f0faa2b2ee3/archive/strx/xrt_smi_strx.a
		https://github.com/Xilinx/VTD/raw/5f7fec23620be7a3984c8970bc514f0faa2b2ee3/archive/phx/xrt_smi_phx.a"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# Prevent Portage from trying to strip the static archives (.a files)
RESTRICT="strip"

# Dependencies discovered from the root CMakeLists.txt
RDEPEND="
	dev-libs/boost
	dev-libs/json-c
	dev-libs/libfmt
	x11-libs/libdrm
	sys-libs/ncurses
"
DEPEND="${RDEPEND}
	dev-libs/protobuf
"

src_prepare() {
	default

	local pkg_cmake="${S}/CMake/pkg.cmake"

	# Correct hardcoded /bins install path in top-level CMakeLists.txt
	sed -i 's|set(XDNA_BIN_DIR[[:space:]]\+/bins)|set(XDNA_BIN_DIR ${CMAKE_INSTALL_PREFIX})|' "${S}/CMakeLists.txt" || die "Failed to patch XDNA_BIN_DIR"

	# Make this work on Gentoo
	sed -i '/else("${XDNA_CPACK_LINUX_PKG_FLAVOR}" MATCHES "debian")/d' "${pkg_cmake}" || die "Failed to remove else condition"
	sed -i '/message(FATAL_ERROR "Unknown Linux package flavor:/d' "${pkg_cmake}" || die "Failed to remove fatal error message"

	# Patch the FetchContent URLs to point to the local files in DISTDIR.
	# We use double quotes so the shell expands ${DISTDIR}.
	sed -i "s|URL \".*/xrt_smi_phx.a\"|URL \"file://${DISTDIR}/xrt_smi_phx.a\"|" "${pkg_cmake}" || die "Failed to patch phx archive URL"
	sed -i "s|URL \".*/xrt_smi_strx.a\"|URL \"file://${DISTDIR}/xrt_smi_strx.a\"|" "${pkg_cmake}" || die "Failed to patch strx archive URL"

	# Fix string issue
	local hwq_cpp="${S}/src/shim/hwq.cpp"
	sed -i 's/shim_err(errno, "Failed to open dump file: %s", dumpfile);/shim_err(errno, "Failed to open dump file: %s", dumpfile.c_str());/' "${hwq_cpp}" || die "Failed to patch hwq.cpp for dumpfile"
	sed -i 's/shim_err(ec.value(), "Failed to create BO dump dir: %s: %s", dir_path, ec.message());/shim_err(ec.value(), "Failed to create BO dump dir: %s: %s", dir_path.c_str(), ec.message().c_str());/' "${hwq_cpp}" || die "Failed to patch hwq.cpp for dir_path"

	local platform_virtio_cpp="${S}/src/shim/virtio/platform_virtio.cpp"
	# Add header for std::memset
	sed -i '1i#include <cstring>' "${platform_virtio_cpp}" || die "Failed to add cstring include"
	# Split VLA declaration and initialization into two lines
	sed -i 's|uint64_t req_buf\[req_sz_in_u64\] = {};|uint64_t req_buf[req_sz_in_u64];\n  std::memset(req_buf, 0, req_sz_in_u64 * sizeof(uint64_t));|' "${platform_virtio_cpp}" || die "Failed to patch VLA"

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		# The build script sets XDNA_DRIVER_BUILD_KMOD based on the -kmod/-nokmod flag.
		# We tie this directly to the 'kmod' USE flag.
		-DSKIP_KMOD=ON
		-DCMAKE_INSTALL_PREFIX=/usr
    )
	cmake_src_configure
}
