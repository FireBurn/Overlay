# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="AMD Radeon GPU Profiler and the rest of the Radeon Developer Tool Suite"
HOMEPAGE="https://gpuopen.com/rgp/ https://github.com/GPUOpen-Tools/radeon_gpu_profiler"

# Upstream publishes only binaries; the source is not available.
MY_P="RadeonDeveloperToolSuite-${PV//./-}-1806"
SRC_URI="https://gpuopen.com/download/${MY_P}.tgz"
S="${WORKDIR}/${MY_P}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip"
QA_PREBUILT="opt/${PN}/*"

# The bundled Qt and ICU are used through RPATH.
RDEPEND="
	media-libs/mesa
	x11-libs/libxcb
"

src_install() {
	insinto /opt/${PN}
	doins -r .

	local f
	for f in RadeonGPUProfiler RadeonMemoryVisualizer RadeonRaytracingAnalyzer \
		RadeonDeveloperPanel RadeonDeveloperPanelCLI RadeonDeveloperService \
		RadeonDeveloperServiceCLI rgd rga; do
		fperms +x /opt/${PN}/${f}
		dosym ../${PN}/${f} /opt/bin/${f}
	done
	fperms +x /opt/${PN}/RadeonGPUAnalyzer-bin /opt/${PN}/rga-bin
}
