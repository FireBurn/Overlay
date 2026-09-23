# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Meta package for the ROCm stack in this overlay"
HOMEPAGE="https://github.com/ROCm/TheRock"
S="${WORKDIR}"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	~dev-build/rocm-cmake-${PV}
	~dev-libs/rccl-${PV}
	~dev-libs/rocm-comgr-${PV}
	~dev-libs/rocm-core-${PV}
	~dev-libs/rocm-device-libs-${PV}
	~dev-libs/rocm-opencl-runtime-${PV}
	~dev-libs/rocr-runtime-${PV}
	~dev-libs/roct-thunk-interface-${PV}
	~dev-util/amdsmi-${PV}
	~dev-util/aqlprofile-${PV}
	~dev-util/hip-${PV}
	~dev-util/hipcc-${PV}
	~dev-util/hipify-clang-${PV}
	~dev-util/rocminfo-${PV}
	~dev-util/rocprofiler-${PV}
	~dev-util/roctracer-${PV}
	~dev-util/Tensile-${PV}
	~sci-libs/hipBLAS-${PV}
	~sci-libs/hipBLAS-common-${PV}
	~sci-libs/hipBLASLt-${PV}
	~sci-libs/hipFFT-${PV}
	~sci-libs/miopen-${PV}
	~sci-libs/rocBLAS-${PV}
	~sci-libs/rocFFT-${PV}
	~sci-libs/rocRAND-${PV}
"
