# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

GRADLE_SLOT="9.7.0"

inherit desktop git-r3 gradle java-pkg-2 python-single-r1 xdg-utils

DESCRIPTION="A software reverse engineering (SRE) framework"
HOMEPAGE="https://ghidra-sre.org/ https://github.com/NationalSecurityAgency/ghidra"

EGIT_REPO_URI="https://github.com/NationalSecurityAgency/ghidra.git"

LICENSE="Apache-2.0 GPL-2+ GPL-3+"
SLOT="0"
KEYWORDS=""
IUSE="bsim +debugger doc eclipse +fidb +gui ida +jython lisa machine-learning +python +sarif server +z3"
RESTRICT="test"

REQUIRED_USE="
	python? ( ${PYTHON_REQUIRED_USE} )
	debugger? ( sarif python )
	lisa? ( sarif )
"

BDEPEND="
	app-arch/unzip
	dev-java/gradle-bin:${GRADLE_SLOT}
	dev-java/jflex
	sys-devel/bison
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			dev-python/pip[${PYTHON_USEDEP}]
			dev-python/setuptools[${PYTHON_USEDEP}]
			dev-python/wheel[${PYTHON_USEDEP}]
		')
	)
"

RDEPEND="
	>=virtual/jre-21:*
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			dev-python/jpype[${PYTHON_USEDEP}]
			dev-python/protobuf[${PYTHON_USEDEP}]
			dev-python/psutil[${PYTHON_USEDEP}]
		')
	)
	z3? ( sci-mathematics/z3 )
"

DEPEND="
	${RDEPEND}
	>=virtual/jdk-21:*
"

QA_PREBUILT="
	usr/share/ghidra/GPL/DemanglerGnu/os/*/demangler_gnu_*
	usr/share/ghidra/Ghidra/Features/Decompiler/os/*/decompile
	usr/share/ghidra/Ghidra/Features/Decompiler/os/*/sleigh
	usr/share/ghidra/Ghidra/Features/FileFormats/os/*/lzfse
	usr/share/ghidra/Ghidra/Features/FileFormats/data/sevenzipnativelibs/*/*.so
	usr/share/ghidra/Ghidra/Extensions/SymbolicSummaryZ3/os/*/*.so
"

ghidra_extensions() {
	use bsim && echo BSimElasticPlugin
	use jython && echo Jython
	use lisa && echo Lisa
	use machine-learning && echo MachineLearning
	use z3 && echo SymbolicSummaryZ3
	return 0
}

pkg_postinst() {
	use gui || return
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	use gui || return
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_setup() {
	java-pkg-2_pkg_setup
	use python && python-single-r1_pkg_setup
}

src_unpack() {
	git-r3_src_unpack

	# src_unpack is the only phase a live ebuild may use the network in
	gradle_setup_offline_repo

	# not upstream's "init": that task cannot configure an existing build
	cd "${S}" || die
	egradle -I gradle/support/fetchDependencies.gradle help

	gradle_resolve_online
}

src_prepare() {
	default

	# Windows only, and wants a prebuilt type library
	rm -rf Ghidra/Debug/Debugger-agent-dbgeng || die

	use fidb || rm -rf dependencies/fidb || die

	# Python configuration
	if use python; then
		sed -i "s/findPython3(true)/\"${EPYTHON}\"/" build.gradle || die
	else
		rm -rf Ghidra/Features/PyGhidra || die
	fi

	# Optional modules controlled by USE flags
	if ! use bsim; then
		rm -rf Ghidra/Features/BSim \
			Ghidra/Features/BSimFeatureVisualizer \
			Ghidra/Features/VersionTrackingBSim \
			Ghidra/Extensions/BSimElasticPlugin || die
	fi

	if ! use debugger; then
		sed -i "/includeProjects('Ghidra\/Debug')/d" settings.gradle || die
	fi

	if ! use eclipse; then
		sed -i "/includeProjects('GhidraBuild\/EclipsePlugins/d" settings.gradle || die
	fi

	if ! use ida; then
		sed -i "/includeProject('IDAPro'/d" settings.gradle || die
	fi

	if ! use jython; then
		rm -rf Ghidra/Extensions/Jython || die
	fi

	if ! use lisa; then
		rm -rf Ghidra/Extensions/Lisa || die
	fi

	if ! use machine-learning; then
		rm -rf Ghidra/Extensions/MachineLearning || die
	fi

	if ! use sarif; then
		rm -rf Ghidra/Features/Sarif || die
	fi

	if ! use server; then
		rm -rf Ghidra/Features/GhidraServer || die
	fi

	if ! use z3; then
		rm -rf Ghidra/Extensions/SymbolicSummaryZ3 || die
	fi
}

src_compile() {
	# the offline repository replaces every flatDir the build declares
	local GRADLE_FLATDIRS="
		${S}/dependencies/flatRepo
		${S}/GPL/DMG/data/lib
	"

	local gradle_args=( -x test -x check -x ip )

	use doc || gradle_args+=( -x createJavadocs -x createJsondocs )
	use python || gradle_args+=( -x createGhidraStubsWheel -x createPythonTypeStubs )

	egradle "${gradle_args[@]}" prepDev
	egradle "${gradle_args[@]}" assembleAll

	# assembleAll leaves Ghidra/Extensions empty
	local ext
	for ext in $(ghidra_extensions); do
		egradle "${gradle_args[@]}" ":${ext}:zipExtensions"
	done
}

src_install() {
	local dist_dirs=( "${S}"/build/dist/ghidra_* )
	local dist_dir="${dist_dirs[0]}"

	[[ -d "${dist_dir}" ]] || die "Build distribution directory not found: ${dist_dir}"

	local ext
	for ext in $(ghidra_extensions); do
		# the archive name carries the build date
		local zips=( "${S}"/build/dist/*_"${ext}".zip )
		[[ -f ${zips[0]} ]] || die "no extension archive built for ${ext}"
		unzip -q -o "${zips[0]}" -d "${dist_dir}/Ghidra/Extensions" || die
	done

	# Remove zip archives not needed for runtime
	find "${dist_dir}" -type f -name '*.zip' -exec rm -f {} +

	if ! use doc; then
		rm -rf "${dist_dir}/docs" || die
	fi

	insinto /usr/share/ghidra
	doins -r "${dist_dir}"/*

	# Fix executable permissions on launchers and native binaries
	fperms +x /usr/share/ghidra/ghidraRun
	fperms +x /usr/share/ghidra/support/launch.sh
	fperms +x /usr/share/ghidra/support/analyzeHeadless

	if use python; then
		[[ -f "${ED}/usr/share/ghidra/support/pyghidraRun" ]] && \
			fperms +x /usr/share/ghidra/support/pyghidraRun
	fi

	# Native executables
	local exe
	while IFS= read -r -d '' exe; do
		fperms +x "${exe#${ED}}"
	done < <(find "${ED}/usr/share/ghidra" -type f \
		\( -name "decompile" -o -name "sleigh" -o -name "demangler_gnu_*" \
			-o -name "lzfse" \) -print0)

	# Debugger scripts
	if use debugger; then
		local dbg_script
		while IFS= read -r -d '' dbg_script; do
			fperms +x "${dbg_script#${ED}}"
		done < <(find "${ED}/usr/share/ghidra/Ghidra/Debug" -type f -name "*.sh" -print0 2>/dev/null)
	fi

	# Symlinks in /usr/bin
	dosym -r /usr/share/ghidra/ghidraRun /usr/bin/ghidra
	dosym -r /usr/share/ghidra/support/analyzeHeadless /usr/bin/ghidra-headless

	# not /usr/bin/pyghidra: that is dev-python/pyghidra's
	if use python && [[ -f "${ED}/usr/share/ghidra/support/pyghidraRun" ]]; then
		dosym -r /usr/share/ghidra/support/pyghidraRun /usr/bin/ghidra-pyghidra
	fi

	if use server && [[ -f "${ED}/usr/share/ghidra/server/svrAdmin" ]]; then
		fperms +x /usr/share/ghidra/server/svrAdmin
		dosym -r /usr/share/ghidra/server/svrAdmin /usr/bin/ghidra-svrAdmin
	fi

	# Desktop integration
	if use gui; then
		local icon_path="${S}/GhidraDocs/GhidraClass/Beginner/Images/GhidraLogo64.png"
		if [[ -f "${icon_path}" ]]; then
			newicon -s 64 "${icon_path}" ghidra.png
		fi
		make_desktop_entry ghidra "Ghidra" ghidra "Development;Utility;"
	fi
}
