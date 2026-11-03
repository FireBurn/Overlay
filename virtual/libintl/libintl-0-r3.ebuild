# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit multilib-build

DESCRIPTION="Virtual for the GNU Internationalization Library"

SLOT="0"
KEYWORDS="~amd64 ~arm64 ~riscv"
# elibc_llvm is not one of the values the gentoo profiles declare, so it is
# named here as virtual/libc does.
IUSE="elibc_llvm"

# llvm-libc has the gettext functions, and its libintl.h, in the C library.
RDEPEND="!elibc_glibc? ( !elibc_musl? ( !elibc_llvm? ( dev-libs/libintl[${MULTILIB_USEDEP}] ) ) )"
