# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/opencl/opencl-0-r4.ebuild,v 1.2 2013/09/21 20:24:50 mgorny Exp $

EAPI=5

inherit multilib-build

DESCRIPTION="Virtual for OpenCL implementations"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~x86"
CARDS=( fglrx nvidia radeon radeonsi r600 nouveau )
IUSE="${CARDS[@]/#/video_cards_}"

DEPEND=""
# intel-ocl-sdk is amd64-only
RDEPEND="app-admin/eselect-opencl
	|| (
		video_cards_fglrx? ( >=x11-drivers/ati-drivers-12.1-r1 )
		video_cards_nvidia? ( >=x11-drivers/nvidia-drivers-290.10-r2 )
		video_cards_radeon? ( media-libs/mesa[video_cards_radeon,opencl,${MULTILIB_USEDEP}] )
		video_cards_radeonsi? ( media-libs/mesa[video_cards_radeonsi,opencl,${MULTILIB_USEDEP}] )
		video_cards_r600? ( media-libs/mesa[video_cards_r600,opencl,${MULTILIB_USEDEP}] )
		video_cards_nouveau? ( media-libs/mesa[video_cards_nouveau,opencl,${MULTILIB_USEDEP}] )
		abi_x86_64? ( !abi_x86_32? ( dev-util/intel-ocl-sdk ) )
	)"
