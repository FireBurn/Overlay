# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/llvm/llvm-2.9-r2.ebuild,v 1.1 2011/05/23 11:43:47 voyageur Exp $

EAPI="3"
ABI=x86
inherit eutils flag-o-matic multilib toolchain-funcs

PN="llvm"   
P="llvm-2.9"   
PF="llvm-2.9-r2"
PV="2.9"

DESCRIPTION="Low Level Virtual Machine"
HOMEPAGE="http://llvm.org/"
SRC_URI="http://llvm.org/releases/${PV}/${P}.tgz"

LICENSE="UoI-NCSA"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86 ~amd64-linux ~x86-linux ~ppc-macos"
IUSE="debug +libffi llvm-gcc multitarget ocaml test udis86 vim-syntax"

DEPEND="dev-lang/perl
	>=sys-devel/make-3.79
	>=sys-devel/flex-2.5.4
	>=sys-devel/bison-1.28
	!~sys-devel/bison-1.85
	!~sys-devel/bison-1.875
	|| ( >=sys-devel/gcc-3.0 >=sys-devel/gcc-apple-4.2.1 )
	|| ( >=sys-devel/binutils-2.18 >=sys-devel/binutils-apple-3.2.3 )
	libffi? ( dev-util/pkgconfig
		dev-libs/libffi-32bit )
	ocaml? ( dev-lang/ocaml )
	udis86? ( amd64? ( dev-libs/udis86-32bit[pic] )
		!amd64? ( dev-libs/udis86-32bit ) )"
RDEPEND="dev-lang/perl
	libffi? ( dev-libs/libffi-32bit )
	vim-syntax? ( || ( app-editors/vim app-editors/gvim ) )"

S=${WORKDIR}/${PN}-${PV/_pre*}

pkg_setup() {
	# need to check if the active compiler is ok

	broken_gcc=" 3.2.2 3.2.3 3.3.2 4.1.1 "
	broken_gcc_x86=" 3.4.0 3.4.2 "
	broken_gcc_amd64=" 3.4.6 "
	
	append-flags -m32
	
	gcc_vers=$(gcc-fullversion)

	if [[ ${broken_gcc} == *" ${version} "* ]] ; then
		elog "Your version of gcc is known to miscompile llvm."
		elog "Check http://www.llvm.org/docs/GettingStarted.html for"
		elog "possible solutions."
		die "Your currently active version of gcc is known to miscompile llvm"
	fi

	if [[ ${CHOST} == i*86-* && ${broken_gcc_x86} == *" ${version} "* ]] ; then
		elog "Your version of gcc is known to miscompile llvm on x86"
		elog "architectures.  Check"
		elog "http://www.llvm.org/docs/GettingStarted.html for possible"
		elog "solutions."
		die "Your currently active version of gcc is known to miscompile llvm"
	fi

	if [[ ${CHOST} == x86_64-* && ${broken_gcc_amd64} == *" ${version} "* ]];
	then
		 elog "Your version of gcc is known to miscompile llvm in amd64"
		 elog "architectures.  Check"
		 elog "http://www.llvm.org/docs/GettingStarted.html for possible"
		 elog "solutions."
		die "Your currently active version of gcc is known to miscompile llvm"
	 fi
}

src_prepare() {
	PN="llvm"
	P="llvm-2.9"
	# unfortunately ./configure won't listen to --mandir and the-like, so take
	# care of this.
	einfo "Fixing install dirs"
	sed -e 's,^PROJ_docsdir.*,PROJ_docsdir := $(PROJ_prefix)/share/doc/'${PF}, \
		-e 's,^PROJ_etcdir.*,PROJ_etcdir := '"${EPREFIX}"'/etc/llvm,' \
		-e 's,^PROJ_libdir.*,PROJ_libdir := $(PROJ_prefix)/'lib32/${PN}, \
		-i Makefile.config.in || die "Makefile.config sed failed"
	sed -e 's,$ABS_RUN_DIR/lib,'"${EPREFIX}"/usr/lib32/${PN}, \
		-i tools/llvm-config/llvm-config.in.in || die "llvm-config sed failed"

	einfo "Fixing rpath"
	sed -e 's,\$(RPATH) -Wl\,\$(\(ToolDir\|LibDir\)),$(RPATH) -Wl\,'"${EPREFIX}"/usr/lib32/${PN}, \
		-i Makefile.rules || die "rpath sed failed"

	epatch "${FILESDIR}"/${PN}-2.6-commandguide-nops.patch
	epatch "${FILESDIR}"/${PN}-2.9-nodoctargz.patch

	# Upstream commit r131062
	epatch "${FILESDIR}"/${P}-Operator.h-c++0x.patch
}

src_configure() {
	local CONF_FLAGS="--enable-shared
		$(use_enable !debug optimized)
		$(use_enable debug assertions)
		$(use_enable debug expensive-checks)"

	if use multitarget; then
		CONF_FLAGS="${CONF_FLAGS} --enable-targets=all"
	else
		CONF_FLAGS="${CONF_FLAGS} --enable-targets=host-only"
	fi

	if use amd64; then
		CONF_FLAGS="${CONF_FLAGS} --enable-pic"
	fi

	# things would be built differently depending on whether llvm-gcc is
	# used or not.
	local LLVM_GCC_DIR=/dev/null
	local LLVM_GCC_DRIVER=nope ; local LLVM_GPP_DRIVER=nope
	if use llvm-gcc ; then
		if has_version sys-devel/llvm-gcc; then
			LLVM_GCC_DIR=$(ls -d ${EROOT}/usr/lib32/llvm-gcc* 2> /dev/null)
			LLVM_GCC_DRIVER=$(find ${LLVM_GCC_DIR} -name 'llvm*-gcc' 2> /dev/null)
			if [[ -z ${LLVM_GCC_DRIVER} ]] ; then
				die "failed to find installed llvm-gcc, LLVM_GCC_DIR=${LLVM_GCC_DIR}"
			fi
			einfo "Using $LLVM_GCC_DRIVER"
			LLVM_GPP_DRIVER=${LLVM_GCC_DRIVER/%-gcc/-g++}
		else
			eerror "llvm-gcc USE flag enabled, but sys-devel/llvm-gcc was not found"
			eerror "Building with standard gcc, re-merge this package after installing"
			eerror "llvm-gcc to build with it"
			eerror "This is normal behavior on first LLVM merge"
		fi
	fi

	CONF_FLAGS="${CONF_FLAGS} \
		--with-llvmgccdir=${LLVM_GCC_DIR} \
		--with-llvmgcc=${LLVM_GCC_DRIVER} \
		--with-llvmgxx=${LLVM_GPP_DRIVER}"

	if use ocaml; then
		CONF_FLAGS="${CONF_FLAGS} --enable-bindings=ocaml"
	else
		CONF_FLAGS="${CONF_FLAGS} --enable-bindings=none"
	fi

	if use udis86; then
		CONF_FLAGS="${CONF_FLAGS} --with-udis86"
	fi

	if use libffi; then
		append-cppflags "$(pkg-config --cflags libffi)"
	fi
	CONF_FLAGS="${CONF_FLAGS} $(use_enable libffi)"
	econf ${CONF_FLAGS} || die "econf failed"
}

src_compile() {
	emake VERBOSE=1 KEEP_SYMBOLS=1 REQUIRES_RTTI=1 || die "emake failed"
}

src_install() {
	emake KEEP_SYMBOLS=1 DESTDIR="${D}" install || die "install failed"

	if use vim-syntax; then
		insinto /usr/share/vim/vimfiles/syntax
		doins utils/vim/*.vim
	fi

	# Fix install_names on Darwin.  The build system is too complicated
	# to just fix this, so we correct it post-install
	if [[ ${CHOST} == *-darwin* ]] ; then
		for lib in lib{EnhancedDisassembly,LLVM-${PV},LTO}.dylib {BugpointPasses,LLVMHello,profile_rt}.dylib ; do
			# libEnhancedDisassembly is Darwin10 only, so non-fatal
			[[ -f ${ED}/usr/lib/${PN}/${lib} ]] || continue
			ebegin "fixing install_name of $lib"
			install_name_tool \
				-id "${EPREFIX}"/usr/lib/${PN}/${lib} \
				"${ED}"/usr/lib/${PN}/${lib}
			eend $?
		done
		for f in "${ED}"/usr/bin/* "${ED}"/usr/lib/${PN}/libLTO.dylib ; do
			ebegin "fixing install_name reference to libLLVM-${PV}.dylib of ${f##*/}"
			install_name_tool \
				-change "@executable_path/../lib/libLLVM-${PV}.dylib" \
					"${EPREFIX}"/usr/lib/${PN}/libLLVM-${PV}.dylib \
				"${f}"
			eend $?
		done
	fi
	rm -rf "${D}"/usr/share || die "Removing files failed."
        rm -rf "${D}"/usr/bin || die "Removing files failed."
        rm -rf "${D}"/usr/include || die "Removing files failed."
}
