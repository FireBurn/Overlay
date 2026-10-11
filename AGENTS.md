# FireBurn overlay

## Communication

- Be brief, direct and factual.
- Do not use mannered prose, AI jargon, em dashes or running commentary.
- Do not narrate routine actions. Report results, failures and decisions that matter.
- Keep code and ebuild comments sparse. Comment only when the reason is not clear from the code.
- Ask before making a material choice that is not settled by the repository or the request.

## Ebuilds

- Follow the surrounding package and category style.
- Build from source when source is available. Do not replace source builds with upstream binaries or separate dependency bundles.
- Declare fetched dependencies in the ebuild so Portage fetches and verifies them through the Manifest.
- Depend only on Gentoo and this overlay. If adopting an ebuild from another overlay, copy it here, retain its maintainer metadata and credit its source in the commit.
- New versions start with testing keywords such as `~amd64`; do not copy stable keywords from an older ebuild.
- Preserve unrelated Manifest entries. Regenerate the Manifest only when distfiles change.
- Use proper patch headers and real paths. Do not add fabricated `index 0000000` lines.
- Use the system toolchain and the package's configured Portage environment. ROCm packages on this host use LLVM and `/etc/portage/env/clango3lto.conf` unless the package requires a documented exception.
- Test with a normal `emerge` by default. It builds in the tmpfs-backed `/var/tmp/portage` and is faster than writing builds to disk.
- After fixing a failed build, use the appropriate `ebuild` phase commands so the build resumes from the last completed phase when possible. Clean the work directory only when the change requires a fresh build.
- Use `/home/fireburn` for large checkouts and `PORTAGE_TMPDIR=/home/fireburn/portage-tmp` only for builds that genuinely do not fit in the tmpfs Portage directory.

## Validation

- Complete validation with a real `emerge`, not only configure, compile or dependency checks.
- Do not claim a build passed until emerge has completed successfully and the package is installed.
- Inspect the build log and fix the cause of failures. Clean stale Portage work directories before retesting changed patches, compilers or CMake options.
- Run relevant smoke tests after installation.
- Run `pkgcheck scan --repo . --commits` before finalising commits or pushing.
- Check relevant Gentoo bugs, upstream changes and review comments when adding or updating versions.
- Do not push untested work. Do not push unless the user asks.

## Git

- Inspect `git status -sb` before editing history or committing. Preserve unrelated user changes.
- Stage explicit paths and inspect the staged diff before every commit.
- Use one commit per package. Do not group changes for different packages in one commit.
- Use short subject-only messages in the existing `category/package: summary` style. Add a body only when essential.
- Do not add `Co-Authored-By`, assistant attribution or session trailers. Do not take credit for work adopted from elsewhere.
- Do not amend or rewrite commits that may already be pushed without checking the branch and remote state.
- Do not commit `AGENTS.md` or add it to `.gitignore`.
