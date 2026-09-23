# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 optfeature pypi

DESCRIPTION="Model Context Protocol SDK"
HOMEPAGE="
	https://modelcontextprotocol.io/
	https://github.com/modelcontextprotocol/python-sdk
	https://pypi.org/project/mcp/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# cryptography via pyjwt[crypto]
# typer and python-dotenv are the cli extra, required by the mcp console script
RDEPEND="
	>=dev-python/anyio-4.10.0[${PYTHON_USEDEP}]
	>=dev-python/cryptography-3.4.0[${PYTHON_USEDEP}]
	>=dev-python/httpx2-2.5.0[${PYTHON_USEDEP}]
	>=dev-python/jsonschema-4.20.0[${PYTHON_USEDEP}]
	~dev-python/mcp-types-${PV}[${PYTHON_USEDEP}]
	>=dev-python/opentelemetry-api-1.28.0[${PYTHON_USEDEP}]
	>=dev-python/pydantic-2.12.0[${PYTHON_USEDEP}]
	>=dev-python/pyjwt-2.10.1[${PYTHON_USEDEP}]
	>=dev-python/python-dotenv-1.0.0[${PYTHON_USEDEP}]
	>=dev-python/python-multipart-0.0.9[${PYTHON_USEDEP}]
	>=dev-python/sse-starlette-3.0.0[${PYTHON_USEDEP}]
	>=dev-python/starlette-0.48.0[${PYTHON_USEDEP}]
	>=dev-python/typer-0.16.0[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.13.0[${PYTHON_USEDEP}]
	>=dev-python/typing-inspection-0.4.1[${PYTHON_USEDEP}]
	>=dev-python/uvicorn-0.31.1[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		dev-python/annotated-types[${PYTHON_USEDEP}]
		>=dev-python/coverage-7.10.7[${PYTHON_USEDEP}]
		>=dev-python/dirty-equals-0.9.0[${PYTHON_USEDEP}]
		>=dev-python/inline-snapshot-0.23.0[${PYTHON_USEDEP}]
		>=dev-python/opentelemetry-sdk-1.39.1[${PYTHON_USEDEP}]
		>=dev-python/referencing-0.28.4[${PYTHON_USEDEP}]
		>=dev-python/trio-0.26.2[${PYTHON_USEDEP}]
	)
"

EPYTEST_PLUGINS=( anyio inline-snapshot )
EPYTEST_XDIST=1
distutils_enable_tests pytest

src_prepare() {
	distutils-r1_src_prepare

	# dev-python/logfire is not in Gentoo
	eapply "${FILESDIR}/tests-optional-logfire.patch"
}

python_compile() {
	local -x UV_DYNAMIC_VERSIONING_BYPASS=${PV}
	distutils-r1_python_compile
}

python_test() {
	local EPYTEST_IGNORE=(
		# Requires dev-python/pytest-examples, which is not in Gentoo
		tests/test_examples.py
		# Requires the zensical/mkdocs docs toolchain, not in Gentoo
		tests/docs
		# Requires dev-python/mcp-example-stories, a dev-only workspace member
		tests/examples
		# Requires dev-python/logfire, which is not in Gentoo
		tests/server/test_otel.py
		tests/docs_src/test_opentelemetry.py
	)
	local EPYTEST_DESELECT=(
		# Requires dev-python/logfire's capfire fixture
		tests/shared/test_otel.py::test_client_and_server_spans
	)

	epytest
}

pkg_postinst() {
	optfeature "colorized log output" dev-python/rich
}
