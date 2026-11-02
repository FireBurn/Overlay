# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..15} )

inherit edo java-pkg-2 python-any-r1 toolchain-funcs

DESCRIPTION="Fast, scalable, multi-language and extensible build system"
HOMEPAGE="https://bazel.build/"
SRC_URI="https://github.com/bazelbuild/bazel/releases/download/${PV}/${P}-dist.zip"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# The Java sources only compile with JDK 21 (25 removes APIs they use)
JAVA_PKG_WANT_BUILD_VM="openjdk-21 openjdk-bin-21"
JAVA_PKG_WANT_SOURCE="21"
JAVA_PKG_WANT_TARGET="21"

# The binary is a launcher with the server jars appended; stripping it
# corrupts the archive.
RESTRICT="strip test"

RDEPEND=">=virtual/jre-21:*"
DEPEND="virtual/jdk:21"
BDEPEND="
	${PYTHON_DEPS}
	app-arch/unzip
"

QA_PREBUILT="usr/bin/bazel"

# python-any-r1 and java-pkg-2 both define pkg_setup
pkg_setup() {
	python-any-r1_pkg_setup
	java-pkg-2_pkg_setup
}

PATCHES=(
	"${FILESDIR}/${P}-strerror_r.patch"
)

src_prepare() {
	default
	java-pkg-2_src_prepare
}

src_compile() {
	tc-export CC CXX
	# bazel builds with its own flags and ignores these
	unset CFLAGS CXXFLAGS LDFLAGS
	export EMBED_LABEL="${PV}"
	export TMPDIR="${T}"
	export JAVA_HOME="$(java-config -g JAVA_HOME)"

	local cxxopts=()
	if [[ $($(tc-getCXX) -print-file-name=libstdc++.so) == libstdc++.so ]]; then
		# no libstdc++ on this system, so use the libc++ the compiler finds
		cxxopts+=( -stdlib=libc++ )
		export BAZEL_LINKOPTS="-stdlib=libc++"
		export BAZEL_LINKLIBS="-lc++:-lm"
	fi
	local IFS=:
	export BAZEL_CXXOPTS="${cxxopts[*]}"
	unset IFS

	# bazel finds lld or gold with the PATH it is started with, but runs the
	# compiler with its own short one, where a gcc then cannot find them
	export EXTRA_BAZEL_ARGS="--action_env=PATH --host_action_env=PATH"

	edo ./compile.sh
}

src_install() {
	dobin output/bazel
}
