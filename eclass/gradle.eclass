# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: gradle.eclass
# @MAINTAINER:
# Mike Lothian <mike@fireburn.co.uk>
# @SUPPORTED_EAPIS: 8
# @BLURB: Build with Gradle offline, from artifacts listed in the ebuild
# @DESCRIPTION:
# Serves the Maven artifacts listed in GRADLE_DEPS back to Gradle from a
# repository assembled in ${T}, so a build resolves nothing over the
# network. Generate the list with scripts/gradle-deps.py.
#
# @EXAMPLE:
# @CODE
# GRADLE_DEPS="
# 	org.ow2.asm:asm:9.6:asm-9.6.jar
# 	org.ow2.asm:asm:9.6:asm-9.6.pom
# "
# GRADLE_SLOT="9.7.0"
#
# inherit gradle
#
# SRC_URI="https://example.org/${P}.tar.gz ${GRADLE_DEP_URIS}"
#
# src_compile() {
# 	egradle assemble
# }
# @CODE

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_GRADLE_ECLASS} ]]; then
_GRADLE_ECLASS=1

inherit edo multiprocessing

# @ECLASS_VARIABLE: GRADLE_DEPS
# @DEFAULT_UNSET
# @PRE_INHERIT
# @DESCRIPTION:
# The Maven artifacts the build resolves, one per line. Empty means resolve
# online instead, which only a live ebuild may do, from src_unpack. Each
# entry is:
# @CODE
# group:artifact:version:filename[:repository]
# @CODE
# The filename is as the repository serves it; every .pom, .module and .jar
# a build reads needs listing. The repository is "central" (the default),
# "plugins" or "google".

# @ECLASS_VARIABLE: GRADLE_SLOT
# @DEFAULT_UNSET
# @PRE_INHERIT
# @DESCRIPTION:
# The dev-java/gradle-bin slot to build with.

# @ECLASS_VARIABLE: GRADLE_FLATDIRS
# @DEFAULT_UNSET
# @DESCRIPTION:
# Directories of loose jars to offer as Gradle flatDir repositories. List
# every directory the build passes to flatDir, including ones over jars
# that ship in its own tarball: its own are replaced along with the rest.

# @ECLASS_VARIABLE: GRADLE_DEP_URIS
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# The SRC_URI fragment for GRADLE_DEPS, set when the eclass is inherited.

# @FUNCTION: _gradle_repo_base
# @USAGE: <repository name>
# @INTERNAL
# @DESCRIPTION:
# Base URL of a repository a GRADLE_DEPS entry can name.
_gradle_repo_base() {
	case ${1} in
		central|"") echo "https://repo1.maven.org/maven2" ;;
		plugins) echo "https://plugins.gradle.org/m2" ;;
		google) echo "https://dl.google.com/dl/android/maven2" ;;
		*) die "${ECLASS}: unknown repository ${1}" ;;
	esac
}

# @FUNCTION: _gradle_set_dep_uris
# @INTERNAL
# @DESCRIPTION:
# Fills GRADLE_DEP_URIS from GRADLE_DEPS.
_gradle_set_dep_uris() {
	local entry group artifact version file repo parts oldifs=${IFS}
	GRADLE_DEP_URIS=

	for entry in ${GRADLE_DEPS}; do
		# a here-string would write to /tmp, which metadata generation denies
		IFS=':'
		parts=( ${entry} )
		IFS=${oldifs}
		[[ ${#parts[@]} -ge 4 ]] ||
			die "${ECLASS}: malformed GRADLE_DEPS entry: ${entry}"
		group=${parts[0]} artifact=${parts[1]} version=${parts[2]}
		file=${parts[3]} repo=${parts[4]:-central}

		GRADLE_DEP_URIS+=" $(_gradle_repo_base "${repo}")/${group//.//}/${artifact}/${version}/${file}"
		GRADLE_DEP_URIS+=" -> ${group}-${file}"
	done
}

_gradle_set_dep_uris

# @FUNCTION: _gradle_set_java_home
# @INTERNAL
# @DESCRIPTION:
# Keeps Gradle and the JVMs it forks inside the build directory.
_gradle_set_java_home() {
	export GRADLE_USER_HOME="${T}/gradle-home"
	mkdir -p "${GRADLE_USER_HOME}" || die

	# the JVM takes user.home from the password database, not HOME, and
	# _JAVA_OPTIONS reaches the JVMs a build forks where GRADLE_OPTS does not
	export _JAVA_OPTIONS="${_JAVA_OPTIONS-} -Duser.home=${GRADLE_USER_HOME} -Djava.io.tmpdir=${T}"
}

# @FUNCTION: gradle_setup_offline_repo
# @DESCRIPTION:
# Assembles the repository in ${T} and the init script pointing at it.
# Called by egradle.
gradle_setup_offline_repo() {
	debug-print-function ${FUNCNAME} "$@"

	[[ -n ${_GRADLE_REPO_READY} ]] && return

	local repo="${T}/gradle-repo"
	local entry group artifact version file dir parts oldifs=${IFS}
	local distdir=${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}

	if [[ -z ${GRADLE_DEPS//[[:space:]]/} ]]; then
		_gradle_set_java_home
		_GRADLE_REPO_READY=1
		_GRADLE_ONLINE=1
		einfo "No GRADLE_DEPS listed, letting the build resolve its own"
		return
	fi

	for entry in ${GRADLE_DEPS}; do
		IFS=':'
		parts=( ${entry} )
		IFS=${oldifs}
		group=${parts[0]} artifact=${parts[1]} version=${parts[2]} file=${parts[3]}
		dir="${repo}/${group//.//}/${artifact}/${version}"
		mkdir -p "${dir}" || die
		# copied, not linked: Gradle makes what it serves writable
		cp --reflink=auto "${distdir}/${group}-${file}" "${dir}/${file}" || die
		chmod u+w "${dir}/${file}" || die
	done

	local flatdirs=
	local d
	for d in ${GRADLE_FLATDIRS}; do
		flatdirs+="            flatDir { dirs '${d}' }"$'\n'
	done

	# PREFER_SETTINGS makes Gradle ignore the repositories a project declares
	# for itself. Do not pass --offline as well: it refuses any repository
	# Gradle has not already cached, including a local one.
	cat > "${T}/gradle-offline.gradle" <<-EOF || die
		beforeSettings { settings ->
		    settings.pluginManagement {
		        repositories {
		            clear()
		            maven { url = uri('file://${repo}') }
		        }
		    }
		    settings.dependencyResolutionManagement {
		        repositoriesMode = org.gradle.api.initialization.resolve.RepositoriesMode.PREFER_SETTINGS
		        repositories {
		            maven { url = uri('file://${repo}') }
		${flatdirs}        }
		    }
		}
	EOF

	_gradle_set_java_home

	_GRADLE_REPO_READY=1
	einfo "Offline Maven repository with $(echo ${GRADLE_DEPS} | wc -w) artifacts at ${repo}"
}

# @FUNCTION: gradle_resolve_online
# @USAGE: [<gradle arguments>]
# @DESCRIPTION:
# Resolves everything the build declares into the Gradle home it then runs
# from. For a live ebuild, from src_unpack: the one phase portage leaves
# the network available in.
gradle_resolve_online() {
	debug-print-function ${FUNCNAME} "$@"

	gradle_setup_offline_repo

	cat > "${T}/gradle-resolve.gradle" <<-'EOF' || die
		allprojects {
		    tasks.register("gentooResolveAll") {
		        doLast {
		            configurations.findAll { it.canBeResolved }.each { c ->
		                try {
		                    c.resolve()
		                } catch (Exception e) {
		                    logger.lifecycle("could not resolve ${c.name}: ${e.message}")
		                }
		            }
		        }
		    }
		}
	EOF

	egradle --init-script "${T}/gradle-resolve.gradle" gentooResolveAll "$@"
}

# @FUNCTION: egradle
# @USAGE: <gradle arguments>
# @DESCRIPTION:
# Runs Gradle against the repository gradle_setup_offline_repo built.
egradle() {
	debug-print-function ${FUNCNAME} "$@"

	[[ -n ${GRADLE_SLOT} ]] || die "${ECLASS}: GRADLE_SLOT is not set"

	gradle_setup_offline_repo

	local gradle="${BROOT}/usr/bin/gradle-bin-${GRADLE_SLOT}"
	[[ -x ${gradle} ]] || gradle="${BROOT}/usr/share/gradle-bin-${GRADLE_SLOT}/bin/gradle"
	[[ -x ${gradle} ]] ||
		die "${ECLASS}: no dev-java/gradle-bin:${GRADLE_SLOT} installed"

	local args=(
		--no-daemon
		--console=plain
		--max-workers="$(makeopts_jobs)"
	)
	[[ -z ${_GRADLE_ONLINE} ]] &&
		args+=( --init-script "${T}/gradle-offline.gradle" )

	edo "${gradle}" "${args[@]}" "$@"
}

fi
