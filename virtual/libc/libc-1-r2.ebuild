# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for the C library"
SLOT="0"
# elibc_llvm is not one of the values the gentoo profiles declare, so it is
# named here rather than left to USE_EXPAND. On a profile which does not set
# ELIBC=llvm it is simply off, and this behaves as the virtual it replaces.
IUSE="elibc_llvm"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~arm64-macos ~x64-macos ~x64-solaris"

# explicitly depend on SLOT 2.2 of glibc, because it sets
# a different SLOT for cross-compiling
RDEPEND="
	!prefix-guest? (
		elibc_glibc? ( sys-libs/glibc:2.2 )
		elibc_musl? ( sys-libs/musl )
		elibc_llvm? ( llvm-runtimes/libc )
	)
	prefix-guest? (
		!sys-libs/glibc
		!sys-libs/musl
	)"
