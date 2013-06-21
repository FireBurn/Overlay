# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/opencl/opencl-0-r2.ebuild,v 1.2 2012/03/24 11:56:44 ago Exp $

EAPI="4"

DESCRIPTION="Virtual for OpenCL implementations"

SLOT="0"
KEYWORDS="~amd64 ~x86"
CARDS=( fglrx nvidia radeon radeonsi r600 nouveau )
IUSE="${CARDS[@]/#/video_cards_}"

DEPEND=""
RDEPEND="app-admin/eselect-opencl
	|| (
		video_cards_fglrx? ( >=x11-drivers/ati-drivers-12.1-r1 )
		video_cards_nvidia? ( >=x11-drivers/nvidia-drivers-290.10-r2 )
		video_cards_radeon? ( >=media-libs/mesa-8.1[video_cards_radeon,opencl] )
		video_cards_radeonsi? ( >=media-libs/mesa-8.1[video_cards_radeonsi,opencl] )
		video_cards_r600? ( >=media-libs/mesa-8.1[video_cards_r600,opencl] )
		video_cards_nouveau? ( >=media-libs/mesa-8.1[video_cards_nouveau,opencl] )
		dev-util/intel-ocl-sdk
	)"
