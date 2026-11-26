# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: chromium-rust.eclass
# @MAINTAINER:
# Mike Lothian <fireburn@gentoo.org>
# @SUPPORTED_EAPIS: 8
# @PROVIDES: rust cargo
# @BLURB: System Rust and Crubit integration for Chromium

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: unsupported EAPI ${EAPI}" ;;
esac

if [[ -z ${_CHROMIUM_RUST_ECLASS} ]]; then
_CHROMIUM_RUST_ECLASS=1

# @ECLASS_VARIABLE: CHROMIUM_CRUBIT_VERSION
# @PRE_INHERIT
# @REQUIRED
# @DESCRIPTION:
# Crubit source revision corresponding to Chromium's pinned revision.
[[ -n ${CHROMIUM_CRUBIT_VERSION} ]] || die "CHROMIUM_CRUBIT_VERSION is required"
# @ECLASS_VARIABLE: CRUBIT_COMMIT
# @PRE_INHERIT
# @DESCRIPTION:
# Crubit commit to build. Defaults to the one the older Chromium releases pin;
# set it, with CRUBIT_CRATES and CHROMIUM_CRUBIT_VERSION, for a release that
# pins another.
: "${CRUBIT_COMMIT:=69b85cba43f85a6439dc0be86a6fe424bb07a100}"

# @ECLASS_VARIABLE: CRUBIT_CRATES
# @PRE_INHERIT
# @DESCRIPTION:
# Registry crates of the Crubit commit, in CRATES format. Defaults to the list
# for the default CRUBIT_COMMIT.
: "${CRUBIT_CRATES:="
	aho-corasick@1.1.4 anstream@1.0.0 anstyle@1.0.14
	anstyle-parse@1.0.0 anstyle-query@1.1.5 anstyle-wincon@3.0.11
	anyhow@1.0.104 autocfg@1.5.1 base64@0.22.1 bitflags@2.13.1
	camino@1.2.4 cargo-platform@0.3.3 cargo_metadata@0.23.1 cc@1.4.1
	cfg-if@1.0.4 clap@4.6.4 clap-cargo@0.18.3 clap_builder@4.6.2
	clap_derive@4.6.4 clap_lex@1.1.0 colorchoice@1.0.5 either@1.16.0
	errno@0.3.14 fastrand@2.5.0 find-msvc-tools@0.1.10 flagset@0.4.7
	getrandom@0.4.3 googletest@0.14.3 googletest_macro@0.14.3 heck@0.5.0
	indenter@0.3.4 is_terminal_polyfill@1.70.2 itertools@0.13.0 itoa@1.0.18
	jobserver@0.1.35 libc@0.2.189 linux-raw-sys@0.12.1 memchr@2.8.3
	num-traits@0.2.19 once_cell@1.21.4 once_cell_polyfill@1.70.2 paste@1.0.15
	phf@0.11.3 phf_generator@0.11.3 phf_macros@0.11.3 phf_shared@0.11.3
	proc-macro2@1.0.107 protobuf@4.33.0-release protobuf-codegen@4.33.0-release
	protobuf-macros@4.33.0-release quote@1.0.47 r-efi@6.0.0 rand@0.8.7
	rand_core@0.6.4 regex@1.13.1 regex-automata@0.4.16 regex-syntax@0.8.11
	rustc-stable-hash@0.1.2 rustix@1.1.4 rustversion@1.0.23 semver@1.0.28
	serde@1.0.229 serde_core@1.0.229 serde_derive@1.0.229 serde_json@1.0.151
	shlex@2.0.1 siphasher@1.0.3 static_assertions@1.1.0 strsim@0.11.1
	syn@2.0.119 syn@3.0.3 tempfile@3.27.0 thiserror@2.0.19
	thiserror-impl@2.0.19 unicode-ident@1.0.24 utf8parse@0.2.2
	windows-link@0.2.1 windows-sys@0.61.2 zmij@1.0.23
"}"
# @ECLASS_VARIABLE: CRUBIT_EXTRA_BINS
# @PRE_INHERIT
# @DESCRIPTION:
# Additional Crubit workspace binaries to build and install into the
# rust-toolchain bin dir, e.g. rs_bindings_from_cc for Chromium 160.
CRUBIT_EXTRA_BINS="${CRUBIT_EXTRA_BINS:-}"
CRATES=${CRUBIT_CRATES}

# @ECLASS_VARIABLE: RUST_REQ_USE
# @PRE_INHERIT
# @DESCRIPTION:
# Additional Rust features required by Chromium, appended to compiler development requirements.
RUST_REQ_USE="${RUST_REQ_USE:+${RUST_REQ_USE},}rustc-dev(-),rust-src,system-llvm"
# Chromium's rustc_private consumers require the source Rust package.
RUST_SOURCE_ONLY=1
CARGO_OPTIONAL=1
inherit rust cargo

chromium_rust_unpack_crubit() {
	local crate A="crubit-${CHROMIUM_CRUBIT_VERSION}.tar.gz"
	for crate in ${CRATES}; do
		A+=" ${crate/@/-}.crate"
	done
	cargo_src_unpack
}

# @FUNCTION: chromium_rust_build_crubit
# @DESCRIPTION:
# Build Chromium's pinned Crubit revision against the selected system Rust.
chromium_rust_build_crubit() (
	local rust_prefix crubit_src target_dir native_dir lib llvm_prefix
	rust_prefix=$(get_rust_path "${BROOT}" "${RUST_SLOT}" "${RUST_TYPE}") || die
	llvm_prefix=$(get_llvm_prefix -b)
	crubit_src=${WORKDIR}/crubit-${CRUBIT_COMMIT}
	# Not in ${T}: emerge wipes it, so a resumed build would lose the tool.
	target_dir=${WORKDIR}/crubit-target
	[[ -f ${crubit_src}/Cargo.toml ]] || die "Missing Crubit source"
	export RUSTC_BOOTSTRAP=1
	export RUSTC="${rust_prefix%/}/bin/rustc"
	export LD_LIBRARY_PATH="${rust_prefix%/}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
	export ABSL_INCLUDE_PATH="${BROOT}/usr/include"
	export CLANG_INCLUDE_PATH="${llvm_prefix}/include"
	export CC="clang-${LLVM_SLOT}" CXX="clang++-${LLVM_SLOT}"
	# Crubit's C++ code selects Clang API branches by LLVM commit date.
	# LLVM 23 has the PointerUnion-based getRawCommentNoCache API (>= 20260527
	# branch) but not the newer Sema/SemaProxy APIs (< 20260818, < 20261022).
	if [[ ${LLVM_SLOT} -lt 24 ]]; then
		export CXXFLAGS="-DCRUBIT_LLVM_DEV_DATE=20260601${CXXFLAGS:+ ${CXXFLAGS}}"
	else
		die "Set CXXFLAGS=-DCRUBIT_LLVM_DEV_DATE=<YYYYMMDD> for LLVM ${LLVM_SLOT}"
	fi
	native_dir=${T}/crubit-native
	mkdir -p "${native_dir}/absl" "${native_dir}/llvm" || die
	for lib in "${BROOT}/usr/$(get_libdir)"/libabsl*.so; do
		[[ -f ${lib} ]] || continue
		ln -sf "${lib}" "${native_dir}/absl/${lib##*/}" || die
	done
	for lib in "${llvm_prefix}/$(get_libdir)"/*.so; do
		[[ -f ${lib} && ${lib##*/} != LLVMgold.so ]] || continue
		ln -sf "${lib}" "${native_dir}/llvm/${lib##*/}" || die
	done
	export ABSL_LIB_STATIC_PATH="${native_dir}/absl" CLANG_LIB_STATIC_PATH="${native_dir}/llvm"
	export LIBRARY_PATH="${llvm_prefix}/$(get_libdir):${BROOT}/usr/$(get_libdir)${LIBRARY_PATH:+:${LIBRARY_PATH}}"
	RUSTFLAGS="${RUSTFLAGS} -Lnative=${llvm_prefix}/$(get_libdir) -C link-arg=-Wl,-rpath,${rust_prefix%/}/lib"
	export RUSTFLAGS
	cargo_gen_config
	local -a bins=( --bin cc_bindings_from_rs )
	local bin
	for bin in ${CRUBIT_EXTRA_BINS}; do
		bins+=( --bin "${bin}" )
	done
	"${rust_prefix%/}/bin/cargo" build --release --locked --offline "${bins[@]}" \
		--manifest-path "${crubit_src}/Cargo.toml" --target-dir "${target_dir}" || die "Crubit build failed"
	for bin in cc_bindings_from_rs ${CRUBIT_EXTRA_BINS}; do
		if [[ ${bin} == cc_bindings_from_rs ]]; then
			env -u LD_LIBRARY_PATH "${target_dir}/release/${bin}" --help >/dev/null ||
				die "Crubit cannot load the selected compiler libraries"
		else
			# absl flags make --help exit non-zero; check the libraries resolve
			env -u LD_LIBRARY_PATH ldd "${target_dir}/release/${bin}" | grep -q "not found" &&
				die "Crubit cannot load the selected compiler libraries"
		fi
	done
)

chromium_rust_prepare_crubit() {
	pushd "${WORKDIR}/crubit-${CRUBIT_COMMIT}" >/dev/null || die
	# Later Crubit commits already handle newer compilers
	if [[ ${CRUBIT_COMMIT} == 69b85cba43f85a6439dc0be86a6fe424bb07a100 ]]; then
		eapply "${FILESDIR}/cr153-crubit-return-error-invalid-trait-name.patch"
		eapply "${FILESDIR}/crubit-defkind-added-by-newer-rustc.patch"
		ver_test "${RUST_SLOT}" -ge 1.100.0 && eapply "${FILESDIR}/crubit-rustc-1.100-api.patch"
	fi
	# Newer Crubit commits moved the constant to paths.rs; patch every file that defines it.
	sed -i 's/const LIB_EXTENSION: &str = "a";/const LIB_EXTENSION: \&str = "so";/' \
		cargo/build/absl.rs cargo/build/clang.rs cargo/build/paths.rs || die
	# The scanner uses lstat, which skips the symlinks we create to system libraries.
	sed -i 's/let Ok(meta) = entry.metadata() else { continue };/let Ok(meta) = entry.path().metadata() else { continue };/' \
		cargo/build/paths.rs || die
	# CommentOptions::RetainCommentsFromSystemHeaders is an LLVM 24 API; older
	# system LLVMs have no such flag, so comments from system headers are dropped.
	sed -i 's/comment_options.RetainCommentsFromSystemHeaders/false/g' \
		rs_bindings_from_cc/importer.cc || die
	# LLVM 23's DenseMap copy-list-initialization picks the explicit
	# reserve-count ctor, so `= {}` does not compile; default-construct instead.
	sed -i '/DenseMap/s/= {};/;/' rs_bindings_from_cc/ir_from_cc.h || die
	sed -i ':a;N;$!ba;s/\(DenseMap<[^;]*\) =\n *{};/\1;/' rs_bindings_from_cc/ir_from_cc.h || die
	# isPFPField is a member function until LLVM 24, where it became static.
	sed -i -e 's/clang::ASTContext::isPFPField(field_decl)/field_decl->getASTContext().isPFPField(field_decl)/' \
		-e 's/clang::ASTContext::isPFPField(field)/ast_context.isPFPField(field)/' \
		rs_bindings_from_cc/importers/function.cc || die
	# Same DenseMap `= {}` issue in a function parameter default.
	sed -i 's/virtual_headers_contents_for_testing = {});/virtual_headers_contents_for_testing = llvm::DenseMap<HeaderName, std::string>());/' \
		rs_bindings_from_cc/generate_bindings_and_metadata.h || die
	popd >/dev/null || die
}

# @FUNCTION: chromium_rust_prepare_toolchain
# @DESCRIPTION:
# Provide upstream's toolchain layout and regenerate stdlib rules offline.
chromium_rust_prepare_toolchain() {
	local rust_prefix
	rust_prefix=$(get_rust_path "${BROOT}" "${RUST_SLOT}" "${RUST_TYPE}") || die
	local crubit_src=${WORKDIR}/crubit-${CRUBIT_COMMIT}
	local toolchain=${S}/third_party/rust-toolchain
	local rustc=${RUSTC:-${rust_prefix}/bin/rustc}
	local version=$("${rustc}" -vV) || die
	export LD_LIBRARY_PATH="${rust_prefix%/}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
	[[ ${version} == *$'\n'"LLVM version: ${LLVM_SLOT}."* ]] || die "Rust LLVM backend does not match LLVM ${LLVM_SLOT}"

	[[ -d ${rust_prefix}/lib/rustlib/src/rust/library/vendor ]] || die "Missing vendored rust-src"
	[[ -d ${crubit_src}/support ]] || die "Missing Crubit support tree"
	[[ ! -e ${toolchain} ]] || rm -r "${toolchain}" || die
	mkdir -p "${toolchain}/bin" "${toolchain}/lib/third_party" "${toolchain}/lib/rustlib/src" || die
	local tool
	for tool in rustc rustfmt; do
		ln -s "${rust_prefix%/}/bin/${tool}" "${toolchain}/bin/${tool}" || die
	done
	ln -s "${WORKDIR}/crubit-target/release/cc_bindings_from_rs" "${toolchain}/bin/cc_bindings_from_rs" || die
	local bin
	for bin in ${CRUBIT_EXTRA_BINS}; do
		ln -s "${WORKDIR}/crubit-target/release/${bin}" "${toolchain}/bin/${bin}" || die
	done
	ln -s "${crubit_src}" "${toolchain}/lib/third_party/crubit" || die
	ln -s "${rust_prefix%/}/lib/rustlib/src/rust" "${toolchain}/lib/rustlib/src/rust" || die
	printf 'rustc %s\n' "${RUST_SLOT}" > "${toolchain}/VERSION" || die
	mkdir -p "${T}/gnrt-cargo" || die
	CARGO_HOME="${T}/gnrt-cargo" CARGO_NET_OFFLINE=true \
		"${BROOT}/usr/bin/gnrt" gen --for-std=third_party/rust-toolchain/lib/rustlib/src/rust || die "Stdlib GN generation failed"
}

fi
