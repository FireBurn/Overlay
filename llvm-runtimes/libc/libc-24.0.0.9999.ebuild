# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )
inherit cmake llvm.org python-any-r1 toolchain-funcs

DESCRIPTION="LLVM's implementation of the C standard library"
HOMEPAGE="https://libc.llvm.org/"
# getent is the one Alpine wrote for musl, the same file sys-libs/musl installs.
# llvm.org_set_globals adds the LLVM sources to this further down.
GETENT_COMMIT="93a08815f8598db442d8b766b463d0150ed8e2ab"
GETENT_FILE="musl-getent-${GETENT_COMMIT}.c"
SRC_URI="
	https://gitlab.alpinelinux.org/alpine/aports/-/raw/${GETENT_COMMIT}/main/musl/getent.c
		-> ${GETENT_FILE}
"

# getent is BSD-2.
LICENSE="Apache-2.0-with-LLVM-exceptions || ( UoI-NCSA MIT ) BSD-2"
SLOT="${LLVM_MAJOR}"
IUSE="test"
RESTRICT="!test? ( test )"

# A runtimes build takes its cmake modules from the tree it is building, so
# there is nothing here for an installed LLVM of the same slot to provide.
# Any clang recent enough to build the tree will do, and need not match: the
# 24 series builds with 23.
BDEPEND="
	|| (
		llvm-core/clang:${LLVM_MAJOR}
		>=llvm-core/clang-23:*
	)
	${PYTHON_DEPS}
"
DEPEND="virtual/os-headers"

# The libc is built through the runtimes directory rather than on its own, so
# that scudo can be taken from compiler-rt in the same configure.
LLVM_COMPONENTS=( libc runtimes cmake llvm/cmake compiler-rt third-party/siphash )
llvm.org_set_globals

pkg_pretend() {
	# This is the C library of the system it goes on: it owns the headers in
	# /usr/include and installs a loader and libc.so of its own. On a system
	# already running glibc or musl it would take their place, so it refuses.
	[[ ${MERGE_TYPE} == buildonly ]] && return
	local lib
	for lib in "${EROOT}"/{,usr/}lib{,64}/{libc.so.6,ld-musl-*.so.1}; do
		[[ -e ${lib} ]] &&
			die "${lib#"${EROOT}"} belongs to another C library, which ${PN} would replace"
	done
}

pkg_setup() {
	# The library is written for clang: it uses builtins and attributes GCC
	# does not have, and the headers it generates are meant for clang.
	tc-is-clang || die "llvm-libc must be built with clang, set CC=clang"
	python-any-r1_pkg_setup
}

src_configure() {
	CMAKE_USE_DIR=${WORKDIR}/runtimes

	local libdir=$(get_libdir)
	local mycmakeargs=(
		-DLLVM_ENABLE_RUNTIMES="libc;compiler-rt"

		# A full build owns the headers as well as the library, which is the
		# only way it can be the C library of the system rather than a set of
		# functions layered over another one.
		-DLLVM_LIBC_FULL_BUILD=ON
		-DLIBC_ENABLE_SHARED=ON
		# scudo is the allocator. Without it malloc and the rest are only
		# declared, and nothing implements them.
		-DLLVM_LIBC_INCLUDE_SCUDO=ON
		# scudo is compiled against the headers of the libc it goes into, not
		# those of whatever C library the build machine has.
		-DCOMPILER_RT_BUILD_SCUDO_STANDALONE_WITH_LLVM_LIBC=ON

		# The libraries, startup files and loader go in the platform's libdir
		# like any other C library, and not in a directory per target.
		-DLLVM_LIBDIR_SUFFIX=${libdir#lib}
		-DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF

		# The entrypoints behind this are the ones which are implemented but
		# not yet in the default list, which is most of what a distribution
		# needs from it today.
		-DLLVM_LIBC_ENABLE_EXPERIMENTAL_ENTRYPOINTS=ON

		-DLLVM_INCLUDE_TESTS=$(usex test)

		# Of compiler-rt, only scudo is wanted.
		-DCOMPILER_RT_SANITIZERS_TO_BUILD=scudo_standalone
		-DCOMPILER_RT_BUILD_GWP_ASAN=OFF
		-DCOMPILER_RT_BUILD_BUILTINS=OFF
		-DCOMPILER_RT_BUILD_XRAY=OFF
		-DCOMPILER_RT_BUILD_LIBFUZZER=OFF
		-DCOMPILER_RT_BUILD_PROFILE=OFF
		-DCOMPILER_RT_BUILD_CTX_PROFILE=OFF
		-DCOMPILER_RT_BUILD_MEMPROF=OFF
		-DCOMPILER_RT_BUILD_ORC=OFF
	)

	cmake_src_configure
}

src_compile() {
	# The library, its loader, startup files and headers, and nothing else.
	# Configuring scudo also puts compiler-rt's sanitizer_common into the
	# default target, and that does not build against this library's headers.
	# The empty libdl, libpthread and the rest are made along with libc.
	cmake_build libc libc-shared libm libm-shared libmvec libmvec-shared \
		libc-startup libc-loader generate-libc-headers

	# getent is built against the library just built rather than the one
	# installed, which may be too old to have everything it calls.
	local libc_build=${BUILD_DIR}/libc
	"$(tc-getCC)" ${CPPFLAGS} -isystem "${libc_build}/include" ${CFLAGS} \
		${LDFLAGS} -L"${libc_build}/lib" -o "${T}"/getent \
		"${DISTDIR}/${GETENT_FILE}" || die "building getent failed"
}

src_test() {
	cmake_build check-libc
}

src_install() {
	# Only the library and its headers. compiler-rt is configured alongside it
	# for scudo, which ends up inside libc.so, and a plain install would put
	# compiler-rt's own files into clang's resource directory as well.
	local component
	for component in libc libc-headers; do
		DESTDIR="${D}" cmake --install "${BUILD_DIR}" --component "${component}" ||
			die "installing ${component} failed"
	done

	# The loader looks under the directories /etc/ld-llvm-libc-<arch>.path
	# lists, and env-update keeps ld.so.conf current from env.d, so the one
	# file is a link to the other.
	local arch=${CHOST%%-*}
	[[ ${arch} == riscv* ]] && arch=riscv
	dosym ld.so.conf "/etc/ld-llvm-libc-${arch}.path"

	dobin "${T}"/getent
}
