# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Multi-account switcher for Claude Code"
HOMEPAGE="
	https://github.com/realiti4/claude-swap
	https://pypi.org/project/claude-swap/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/textual-8.2.8[${PYTHON_USEDEP}]
	<dev-python/textual-9[${PYTHON_USEDEP}]
	>=dev-python/truststore-0.10.4[${PYTHON_USEDEP}]
"

EPYTEST_PLUGINS=( pytest-asyncio )
EPYTEST_XDIST=1
distutils_enable_tests pytest

EPYTEST_DESELECT=(
	# the build path contains "claude-swap", tripping the real store guard
	tests/test_real_store_guard.py::test_arbitrary_claude_config_dir_is_not_dropped_by_the_hint_prefilter
	tests/test_real_store_guard.py::test_a_relative_candidate_that_already_carries_a_hint_is_still_joined
)
