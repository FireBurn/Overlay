# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/llvm/llvm-9999-r1.ebuild,v 1.1 2013/07/21 10:00:50 mgorny Exp $

EAPI=5

PYTHON_COMPAT=( python{2_5,2_6,2_7} pypy{1_9,2_0} )

inherit subversion cmake-utils eutils flag-o-matic multilib multilib-minimal \
	python-r1 toolchain-funcs pax-utils

DESCRIPTION="Low Level Virtual Machine"
HOMEPAGE="http://llvm.org/"
SRC_URI=""
ESVN_REPO_URI="http://llvm.org/svn/llvm-project/llvm/trunk"

LICENSE="UoI-NCSA"
SLOT="0"
KEYWORDS=""
IUSE="clang lldb lld doc gold +libffi ocaml python
	+static-analyzer test udis86"
REQUIRED_USE="lldb? ( clang )"

declare -A LLVM_TARGETS
LLVM_TARGETS["x86"]="X86"
LLVM_TARGETS["amd64"]="X86"
LLVM_TARGETS["arm"]="ARM"
LLVM_TARGETS["aarch64"]="AArch64"
LLVM_TARGETS["mips"]="Mips"
LLVM_TARGETS["mipsel"]="Mips"
LLVM_TARGETS["mips64"]="Mips"
LLVM_TARGETS["mips64el"]="Mips"
LLVM_TARGETS["ppc"]="PowerPC"
LLVM_TARGETS["cpp"]="CppBackend"
LLVM_TARGETS["nvptx"]="NVPTX"
LLVM_TARGETS["systemz"]="SystemZ"
LLVM_TARGETS["r600"]="R600"
LLVM_TARGETS["sparc"]="Sparc"
LLVM_TARGETS["xcore"]="XCore"
LLVM_TARGETS["hexagon"]="Hexagon"
LLVM_TARGETS["mblaze"]="MBlaze"
# All other targets here
for i in "${!LLVM_TARGETS[@]}" ; do
	IUSE+=" llvm_targets_${i}"
done

DEPEND="dev-lang/perl
	dev-python/sphinx
	>=sys-devel/make-3.79
	>=sys-devel/flex-2.5.4
	>=sys-devel/bison-1.875d
	|| ( >=sys-devel/gcc-3.0 >=sys-devel/gcc-apple-4.2.1 )
	|| ( >=sys-devel/binutils-2.18 >=sys-devel/binutils-apple-3.2.3 )
	sys-libs/zlib
	gold? ( >=sys-devel/binutils-2.22[cxx] )
	libffi? ( virtual/pkgconfig
		virtual/libffi[${MULTILIB_USEDEP}] )
	ocaml? ( dev-lang/ocaml )
	udis86? ( dev-libs/udis86[pic(+),${MULTILIB_USEDEP}] )
	${PYTHON_DEPS}"
RDEPEND="dev-lang/perl
	libffi? ( virtual/libffi[${MULTILIB_USEDEP}] )
	clang? ( python? ( ${PYTHON_DEPS} ) )
	udis86? ( dev-libs/udis86[pic(+),${MULTILIB_USEDEP}] )
	clang? ( !<=sys-devel/clang-9999-r99 )
	abi_x86_32? ( !<=app-emulation/emul-linux-x86-baselibs-20130224
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)] )"

# pypy gives me around 1700 unresolved tests due to open file limit
# being exceeded. probably GC does not close them fast enough.
REQUIRED_USE="${PYTHON_REQUIRED_USE}
	test? ( || ( $(python_gen_useflags 'python*') ) )"

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

src_unpack() {
	if use clang; then
		ESVN_PROJECT=compiler-rt S="${S}"/projects/compiler-rt subversion_fetch "http://llvm.org/svn/llvm-project/compiler-rt/trunk"
		ESVN_PROJECT=clang S="${S}"/tools/clang subversion_fetch "http://llvm.org/svn/llvm-project/cfe/trunk"
	fi
	if use lldb; then
		ESVN_PROJECT=lldb S="${S}"/tools/lldb subversion_fetch "http://llvm.org/svn/llvm-project/lldb/trunk"
	fi
	if use lld; then
		ESVN_PROJECT=lld S="${S}"/tools/lld subversion_fetch "http://llvm.org/svn/llvm-project/lld/trunk"
	fi
	subversion_src_unpack
}

src_prepare() {
	if use lldb ; then
		edos2unix tools/lldb/source/CMakeLists.txt
	fi
	epatch "${FILESDIR}"/${PN}-3.4-gentoo-install.patch
	use clang && epatch "${FILESDIR}"/clang-3.3-gentoo-install.patch
	use lldb && epatch "${FILESDIR}"/lldb-3.4-gentoo-install.patch
	use lld && epatch "${FILESDIR}"/lld-3.4-gentoo-install.patch

	local sub_files=( )
	use clang && sub_files+=(
		tools/clang/lib/Driver/Tools.cpp
		tools/clang/tools/scan-build/scan-build
	)

	use lldb && sub_files+=(
		tools/lldb/scripts/lldb_python_module.cmake
	)

	# unfortunately ./configure won't listen to --mandir and the-like, so take
	# care of this.
	# note: we're setting the main libdir intentionally.
	# where per-ABI is appropriate, we use $(GENTOO_LIBDIR) make.
	einfo "Fixing install dirs"
	sed -e "s,@libdir@,$(get_libdir),g" \
		-e "s,@PF@,${PF},g" \
		-e "s,@EPREFIX@,${EPREFIX},g" \
		-i "${sub_files[@]}" \
		|| die "install paths sed failed"

	# User patches
	epatch_user
}

src_configure() {
	multilib-minimal_src_configure
}
src_compile() {
	multilib-minimal_src_compile
}
src_install() {
	multilib-minimal_src_install
}
src_test() {
	multilib-minimal_src_test
}
llvm_add_ldpath() {
	# Add LLVM built libraries to LD_LIBRARY_PATH.
	# This way we don't have to hack RPATHs of executables.
	local libpath
	libpath=${BUILD_DIR}/lib

	export LD_LIBRARY_PATH=${libpath}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
}

multilib_src_configure() {
	local targets=''
	for i in "${!LLVM_TARGETS[@]}" ; do
		if use "llvm_targets_${i}" ; then
			targets+="${LLVM_TARGETS[${i}]};"
		fi
	done

	local libdir="$(get_libdir)"

	local mycmakeargs=(
		"-DCMAKE_C_FLAGS='${CFLAGS}'"
		"-DCMAKE_CXX_FLAGS='${CXXFLAGS} -std=gnu++0x'"
		"-DCMAKE_EXE_LINKER_FLAGS='${LDFLAGS}'"
		"-DCMAKE_SHARED_LINKER_FLAGS='${LDFLAGS}'"
		"-DCMAKE_MODULE_LINKER_FLAGS='${LDFLAGS}'"
		"-DBUILD_SHARED_LIBS='ON'"
		"-DLLVM_TARGETS_TO_BUILD='${targets}'"
		"-DLLVM_ENABLE_PIC='ON'"
		"-DLLVM_LIBDIR_SUFFIX='${libdir/lib}'"
	)
	if use lldb && ! multilib_is_native_abi ; then
		mycmakeargs+=(
			"-DLLVM_EXTERNAL_LLDB_BUILD='OFF'"
		)
	fi

	if multilib_is_native_abi ; then
		mycmakeargs+=(
			"-DLLVM_BUILD_TOOLS='ON'"
		)
	else
		mycmakeargs+=(
			"-DLLVM_BUILD_TOOLS='OFF'"
		)
	fi

	if use clang; then
		mycmakeargs+=(
			"-DCLANG_RESOURCE_DIR='../lib/clang/3.4'"
		)
	fi

	if multilib_is_native_abi && use gold; then
		mycmakeargs+=(
			"-DLLVM_BINUTILS_INCDIR='${EPREFIX}/usr/include/'"
		)
	fi

#	if multilib_is_native_abi && use ocaml; then
#		CONF_FLAGS="${CONF_FLAGS} --enable-bindings=ocaml"
#	else
#		CONF_FLAGS="${CONF_FLAGS} --enable-bindings=none"
#	fi

#	if use udis86; then
#		CONF_FLAGS="${CONF_FLAGS} --with-udis86"
#	fi

	if use libffi; then
		local ffiflags="$(pkg-config --cflags libffi)"
		ffiflags="${ffiflags/ }"
		mycmakeargs+=(
			"-DLLVM_ENABLE_FFI='ON'"
			"-DFFI_INCLUDE_DIR='${ffiflags/-I}'"
		)
	fi

	# build with a suitable Python version
	python_export_best

	# llvm prefers clang over gcc, so we may need to force that
	tc-export CC CXX

	CMAKE_USE_DIR="${S}" \
	cmake-utils_src_configure
}

multilib_src_compile() {
	local mymakeopts=(
		VERBOSE=1
		REQUIRES_RTTI=1
		GENTOO_LIBDIR="$(get_libdir)"
	)

	local -x LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
	llvm_add_ldpath

	# Tests need all the LLVM built.
	emake "${mymakeopts[@]}"

	if multilib_is_native_abi; then
		emake -C "${S}"/docs -f Makefile.sphinx man
		use doc && emake -C "${S}"/docs -f Makefile.sphinx html

		pax-mark m bin/llvm-rtdyld
		pax-mark m bin/lli
	fi

	if use test; then
		pax-mark m unittests/ExecutionEngine/JIT/Release/JITTests
		pax-mark m unittests/ExecutionEngine/MCJIT/Release/MCJITTests
		pax-mark m unittests/Support/Release/SupportTests
	fi
}

multilib_src_test() {
	local -x LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
	llvm_add_ldpath

	emake check
}

src_install() {
	multilib-minimal_src_install
	mv "${ED}"/usr/include2 "${ED}"/usr/include
}

multilib_src_install() {
	local mymakeopts=(
		DESTDIR="${D}"
		GENTOO_LIBDIR="$(get_libdir)"
	)
	local tools=(
		llvm-config
		llvm-tblgen
		llvm-lit
	)
	use clang && tools+=(
		clang-tblgen
	)

	local -x LD_LIBRARY_PATH=${LD_LIBRARY_PATH}

	emake "${mymakeopts[@]}" install
	for t in "${tools[@]}" ; do
		mv "${ED}/usr/bin/${t}" "${ED}/usr/bin/${t}-${ABI}" || die
	done
	if multilib_is_native_abi; then
		mv "${ED}"/usr/include "${ED}"/usr/include2
		for t in "${tools[@]}" ; do
			ln -s "${t}-${ABI}" "${ED}/usr/bin/${t}" || die
		done
	else
		rm -rf "${ED}"/usr/include
	fi
}

multilib_src_install_all() {
	doman docs/_build/man/*.1
	use doc && dohtml -r docs/_build/html/

	insinto /usr/share/vim/vimfiles/syntax
	doins utils/vim/*.vim

	if use clang; then
		cd tools/clang || die

		if use static-analyzer ; then
			dobin tools/scan-build/ccc-analyzer
			dosym ccc-analyzer /usr/bin/c++-analyzer
			dobin tools/scan-build/scan-build

			insinto /usr/share/${PN}
			doins tools/scan-build/scanview.css
			doins tools/scan-build/sorttable.js
		fi

		python_inst() {
			if use static-analyzer ; then
				pushd tools/scan-view >/dev/null || die

				python_doscript scan-view

				touch __init__.py || die
				python_moduleinto clang
				python_domodule __init__.py Reporter.py Resources ScanView.py startfile.py

				popd >/dev/null || die
			fi

			if use python ; then
				pushd bindings/python/clang >/dev/null || die

				python_moduleinto clang
				python_domodule __init__.py cindex.py enumerations.py

				popd >/dev/null || die
			fi

			# AddressSanitizer symbolizer (currently separate)
			python_doscript "${S}"/projects/compiler-rt/lib/asan/scripts/asan_symbolize.py
		}
		python_foreach_impl python_inst
	fi
}
