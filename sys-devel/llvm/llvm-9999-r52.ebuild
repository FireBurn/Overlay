# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/llvm/llvm-9999.ebuild,v 1.40 2013/03/19 12:42:12 chithanh Exp $

EAPI=5

# pypy gives me around 1700 unresolved tests due to open file limit
# being exceeded. probably GC does not close them fast enough.
PYTHON_COMPAT=( python{2_5,2_6,2_7} )

inherit subversion eutils flag-o-matic multilib python-r1 pax-utils multilib-minimal

DESCRIPTION="Low Level Virtual Machine"
HOMEPAGE="http://llvm.org/"
SRC_URI=""
ESVN_REPO_URI="http://llvm.org/svn/llvm-project/llvm/trunk"

LICENSE="UoI-NCSA"
SLOT="0"
KEYWORDS="amd64"
LLVM_TARGETS="x86 x86_64 sparc powerpc aarch64 arm mips mipsel mips64 mips64el xcore msp430 cpp hexagon mblaze nvptx systemz r600"
LLVM_TARGETS_USE=""
for i in $LLVM_TARGETS ; do
	LLVM_TARGETS_USE="${LLVM_TARGETS_USE} +llvm_targets_${i}"
done
IUSE="+clang debug doc gold +libffi ocaml python test udis86 +static-analyzer vim-syntax ${LLVM_TARGETS_USE}"

DEPEND="!sys-devel/llvm-32bit
	!<sys-devel/clang-9999-r52
	dev-lang/perl
	dev-python/sphinx
	>=sys-devel/make-3.79
	>=sys-devel/flex-2.5.4
	>=sys-devel/bison-1.875d
	|| ( >=sys-devel/gcc-3.0 >=sys-devel/gcc-apple-4.2.1 )
	|| ( >=sys-devel/binutils-2.18 >=sys-devel/binutils-apple-3.2.3 )
	gold? ( >=sys-devel/binutils-2.22[cxx] )
	libffi? ( virtual/pkgconfig
		virtual/libffi )
	ocaml? ( dev-lang/ocaml )
	udis86? ( dev-libs/udis86[pic(+),${MULTILIB_USEDEP}] )
	static-analyzer? ( dev-lang/perl )
	${PYTHON_DEPS}"
RDEPEND="dev-lang/perl
	libffi? ( virtual/libffi )
	vim-syntax? ( || ( app-editors/vim app-editors/gvim ) )"

src_unpack() {
	# Fetching LLVM and subprojects
	ESVN_PROJECT=llvm subversion_fetch "http://llvm.org/svn/llvm-project/llvm/trunk"
	if use clang ; then
		ESVN_PROJECT=compiler-rt S="${S}"/projects/compiler-rt subversion_fetch "http://llvm.org/svn/llvm-project/compiler-rt/trunk"
		ESVN_PROJECT=clang S="${S}"/tools/clang subversion_fetch "http://llvm.org/svn/llvm-project/cfe/trunk"
	fi
}

pkg_setup() {
	# need to check if the active compiler is ok

	broken_gcc=" 3.2.2 3.2.3 3.3.2 4.1.1 "
	broken_gcc_x86=" 3.4.0 3.4.2 "
	broken_gcc_amd64=" 3.4.6 "

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
	epatch "${FILESDIR}"/llvm-3.2-nodoctargz.patch
	use clang && epatch "${FILESDIR}"/clang-2.7-fixdoc.patch

	# fix the static analyzer for in-tree install
	sed -e 's/import ScanView/from clang \0/'  \
		-i tools/clang/tools/scan-view/scan-view \
		|| die "scan-view sed failed"
	sed -e "/scanview.css\|sorttable.js/s#\$RealBin#${EPREFIX}/usr/share/clang#" \
		-i tools/clang/tools/scan-build/scan-build \
		|| die "scan-build sed failed"

	# User patches
	epatch_user

	multilib_copy_sources
}

multilib_src_configure() {
	if use clang ; then
		# multilib-strict
		sed -e "/PROJ_headers/s#lib/clang#$(get_libdir)/clang#" \
			-i tools/clang/lib/Headers/Makefile \
			|| die "clang Makefile failed"
		sed -e "/PROJ_resources/s#lib/clang#$(get_libdir)/clang#" \
			-i tools/clang/runtime/compiler-rt/Makefile \
			|| die "compiler-rt Makefile failed"
		# Set correct path for gold plugin
		sed -e "/LLVMgold.so/s#lib/#$(get_libdir)/llvm/#" \
			-i  tools/clang/lib/Driver/Tools.cpp \
			|| die "gold plugin path sed failed"
	fi

	# unfortunately ./configure won't listen to --mandir and the-like, so take
	# care of this.
	einfo "Fixing install dirs"
	sed -e 's,^PROJ_docsdir.*,PROJ_docsdir := $(PROJ_prefix)/share/doc/${PF}', \
		-e 's,^PROJ_etcdir.*,PROJ_etcdir := '"${EPREFIX}"'/etc/llvm,' \
		-e 's,^PROJ_libdir.*,PROJ_libdir := $(PROJ_prefix)/'$(get_libdir)/llvm, \
		-i Makefile.config.in || die "Makefile.config sed failed"
	sed -e "/ActiveLibDir = ActivePrefix/s/lib/$(get_libdir)\/llvm/" \
		-i tools/llvm-config/llvm-config.cpp || die "llvm-config sed failed"

	einfo "Fixing rpath and CFLAGS"
	sed -e 's,\$(RPATH) -Wl\,\$(\(ToolDir\|LibDir\)),$(RPATH) -Wl\,'"${EPREFIX}"/usr/$(get_libdir)/llvm, \
		-e '/OmitFramePointer/s/-fomit-frame-pointer//' \
		-i Makefile.rules || die "rpath sed failed"
	if use gold; then
		sed -e 's,\$(SharedLibDir),'"${EPREFIX}"/usr/$(get_libdir)/llvm, \
			-i tools/gold/Makefile || die "gold rpath sed failed"
	fi

	# FileCheck is needed at least for dragonegg tests
	sed -e "/NO_INSTALL = 1/s/^/#/" -i utils/FileCheck/Makefile \
		|| die "FileCheck Makefile sed failed"


	local CONF_FLAGS="--enable-shared
		--with-optimize-option=
		$(use_enable !debug optimized)
		$(use_enable debug assertions)
		$(use_enable debug expensive-checks)"

	# Setup the search path to include the Prefix includes
	if use prefix ; then
		CONF_FLAGS="${CONF_FLAGS} \
			--with-c-include-dirs=${EPREFIX}/usr/include:/usr/include"
	fi

	local ENABLE_TARGETS='host'
	for i in $LLVM_TARGETS ; do
		use llvm_targets_$i && ENABLE_TARGETS="${ENABLE_TARGETS},${i}"
	done
	CONF_FLAGS="${CONF_FLAGS} --enable-targets=${ENABLE_TARGETS}"

	if use amd64; then
		CONF_FLAGS="${CONF_FLAGS} --enable-pic"
	fi

	if use gold; then
		CONF_FLAGS="${CONF_FLAGS} --with-binutils-include=${EPREFIX}/usr/include/"
	fi
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

	# build with a suitable Python version
	python_export_best

	# llvm prefers clang over gcc, so we may need to force that
	tc-export CC CXX
	econf ${CONF_FLAGS}
}

multilib_src_compile() {
	emake VERBOSE=1 KEEP_SYMBOLS=1 REQUIRES_RTTI=1

	emake -C docs -f Makefile.sphinx man
	use doc && emake -C docs -f Makefile.sphinx html

	pax-mark m Release/bin/lli
	if use test; then
		pax-mark m unittests/ExecutionEngine/JIT/Release/JITTests
		pax-mark m unittests/ExecutionEngine/MCJIT/Release/MCJITTests
		pax-mark m unittests/Support/Release/SupportTests
	fi
}

multilib_src_install() {
	local LLVM_FIX_BINARIES=''
	local CLANG_FIX_BINARIES=''
	if [[ ${ABI} == ${DEFAULT_ABI} ]] ; then
		emake KEEP_SYMBOLS=1 DESTDIR="${D}" install
		dosym "${ED}"/usr/bin/llvm-config /usr/bin/llvm-config-${ABI}

		doman docs/_build/man/*.1
		use doc && dohtml -r docs/_build/html/

		if use vim-syntax; then
			insinto /usr/share/vim/vimfiles/syntax
			doins utils/vim/*.vim
		fi

		if use static-analyzer ; then
			dobin tools/clang/tools/scan-build/ccc-analyzer
			dosym ccc-analyzer /usr/bin/c++-analyzer
			dobin tools/clang/tools/scan-build/scan-build

			insinto /usr/share/clang
			doins tools/clang/tools/scan-build/scanview.css
			doins tools/clang/tools/scan-build/sorttable.js
		fi

		python_inst() {
			if use static-analyzer ; then
				pushd tools/clang/tools/scan-view >/dev/null || die

				python_doscript scan-view

				touch __init__.py || die
				python_moduleinto clang
				python_domodule __init__.py Reporter.py Resources ScanView.py startfile.py

				popd >/dev/null || die
			fi

			if use python ; then
				pushd tools/clang/bindings/python/clang >/dev/null || die

				python_moduleinto clang
				python_domodule __init__.py cindex.py enumerations.py

				popd >/dev/null || die
			fi

			# AddressSanitizer symbolizer (currently separate)
			python_doscript "${S}"/projects/compiler-rt/lib/asan/scripts/asan_symbolize.py
		}
		use clang && python_foreach_impl python_inst

		LLVM_FIX_BINARIES="${ED}"/usr/bin/*
		CLANG_FIX_BINARIES="${ED}"/usr/bin/{c-index-test,clang}
	else
		emake KEEP_SYMBOLS=1 DESTDIR="${D}" install-libs
		if use clang ; then
			pushd tools/clang >/dev/null
			emake KEEP_SYMBOLS=1 DESTDIR="${D}" install-libs
			popd >/dev/null
		fi
		insinto /usr/bin
		newbin "${S}-${ABI}"/Release/bin/llvm-config llvm-config-${ABI} 
	fi
	# Fix install_names on Darwin.  The build system is too complicated
	# to just fix this, so we correct it post-install
	local lib= f= odylib= libpv=${PV}
	if [[ ${CHOST} == *-darwin* ]] ; then
		eval $(grep PACKAGE_VERSION= configure)
		[[ -n ${PACKAGE_VERSION} ]] && libpv=${PACKAGE_VERSION}
		for lib in {libEnhancedDisassembly,libLLVM-${libpv},libLTO,libprofile_rt,BugpointPasses,LLVMHello,libclang}.dylib ; do
			# libEnhancedDisassembly is Darwin10 only, so non-fatal
			[[ -f ${ED}/usr/$(get_libdir)/llvm/${lib} ]] || continue
			ebegin "fixing install_name of $lib"
			install_name_tool \
				-id "${EPREFIX}"/usr/$(get_libdir)/llvm/${lib} \
				"${ED}"/usr/$(get_libdir)/llvm/"${f}"
			eend $?
		done
		for f in $LLVM_FIX_BINARIES "${ED}"/usr/$(get_libdir)/llvm/libLTO.dylib ; do
			odylib=$(scanmacho -BF'%n#f' "${f}" | tr ',' '\n' | grep libLLVM-${libpv}.dylib)
			ebegin "fixing install_name reference to ${odylib} of ${f##*/}"
			install_name_tool \
				-change "${odylib}" \
					"${EPREFIX}"/usr/$(get_libdir)/llvm/libLLVM-${libpv}.dylib \
				"${f}"
			eend $?
		done
		if use clang ; then
			for f in $CLANG_FIX_BINARIES "${ED}"/usr/$(get_libdir)/llvm/libclang.dylib ; do
				ebegin "fixing references in ${f##*/}"
				install_name_tool \
					-change "@rpath/libclang.dylib" \
						"${EPREFIX}"/usr/$(get_libdir)/llvm/libclang.dylib \
					-change "@executable_path/../lib/libLLVM-${PV}.dylib" \
						"${EPREFIX}"/usr/$(get_libdir)/llvm/libLLVM-${PV}.dylib \
					-change "${S}"/Release/lib/libclang.dylib \
						"${EPREFIX}"/usr/$(get_libdir)/llvm/libclang.dylib \
					"${f}"
				eend $?
			done
		fi
	fi
}

multilib_check_headers() {
	einfo "Skipping header check"
}
