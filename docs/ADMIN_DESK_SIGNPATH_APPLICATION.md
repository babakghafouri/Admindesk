# AdminDesk — SignPath Foundation application and release-signing readiness

**Status: preparation only. Not approved, not signed, and not integrated with SignPath.**

AdminDesk is a public, modified fork of [RustDesk](https://github.com/rustdesk/rustdesk) at [babakghafouri/Admindesk](https://github.com/babakghafouri/Admindesk), currently publishing Windows AdminDesk 1.5.2 installer artifacts. The repository includes the AGPL-3.0 license. We are requesting an eligibility review for free code signing by the SignPath Foundation; the Foundation makes the final decision.

## Application draft (submit by the repository owner)

- **Project:** AdminDesk
- **Repository:** https://github.com/babakghafouri/Admindesk
- **Upstream:** https://github.com/rustdesk/rustdesk (visible GitHub fork)
- **License:** AGPL-3.0 (repository `LICENCE`)
- **Downloads:** https://github.com/babakghafouri/Admindesk/releases
- **Project website:** https://admindesk.ir/
- **Requested formats:** Windows x64 EXE and MSI; x86 Sciter EXE, if eligible.
- **Description:** AdminDesk is a Persian-language, right-to-left remote support and remote desktop client based on the open-source RustDesk project. It includes localized dashboard, device-management and settings interfaces. Windows installers are built from public GitHub source via GitHub Actions.
- **Signing objective:** Publicly verifiable Authenticode signatures on releases originating from the repository, with controlled manual release approval.
- **Build source:** `.github/workflows/admindesk-windows-release.yml`, reusable `.github/workflows/flutter-build.yml`.
- **Current status:** CI builds and publishes EXE/MSI without a configured trusted code-signing certificate. A green CI run does **not** certify a signed installer.
- **Maintainer / requester contact:** To be filled in by the repository owner in the Foundation's application form. Do not place a personal email or API token in this repository.

**Application:** https://signpath.org/apply

## Eligibility and security review BEFORE submission

The SignPath Foundation [terms](https://signpath.org/terms) require more than an OSS license. All of these must be assessed by the owner:

- [x] Public GitHub repository is visibly a fork of RustDesk.
- [x] Repository has an OSI-approved AGPL-3.0 license.
- [x] Public Windows releases exist.
- [ ] Confirm the upstream project's normally signed release branches and that AdminDesk's signing branches are based on them. Confirm the policy for this **modified upstream fork** with SignPath.
- [ ] Audit **every component shipped in the signed package** for allowed open-source licensing, including any Flutter/Rust/Sciter runtime binaries, installed drivers and bundled third-party files. Do not assume all included files are eligible.
- [ ] Publish an AdminDesk-specific download/feature description (current README primarily documents upstream RustDesk).
- [ ] Publish an accurate privacy policy. Account for remote-connection services, telemetry (if any), the WordPress advertising endpoint, notifications and update checks; disclose which network requests happen automatically and which are user-initiated. Confirm any required installation notices/opt-outs.
- [ ] Document the code-signing roles: repository committers/authors, reviewers, and release/signing approvers. Require MFA on GitHub and SignPath.
- [ ] Confirm software installation/uninstallation options and warning for system configuration changes.
- [ ] Review SignPath's prohibitions and the project's remote-access/security-diagnostic behavior with the Foundation.
- [ ] Define artifact configuration and metadata restrictions for AdminDesk version **1.5.2**. The RustDesk engine remains separately versioned at 1.5.1. Confirm mixed upstream/internal metadata can comply with SignPath's product-name constraints.
- [ ] Confirm branch protection, review policy, and manual signing approval for every release.
- [ ] Once approved, publish the exact SignPath-required “Code signing policy” page and link it from the repository README and download page. Include approved team roles, privacy-policy link and the required attribution **“Free code signing provided by SignPath.io, certificate by SignPath Foundation”**. Do not present this attribution as an active signing claim before approval.

## Integration plan AFTER SignPath approval

1. Have the owner create/activate the SignPath organization and project; configure the GitHub trusted-build-system connector and SignPath GitHub App according to the [official instructions](https://docs.signpath.io/trusted-build-systems/github).
2. Store the **SignPath API token** in GitHub Actions secrets (never in code, release notes, workflows or console output). Supply the approved organization ID, project slug, signing policy and artifact configuration.
3. Create a separate, protected **manual release/signing workflow** tied to the approved source commit and using GitHub-hosted runners. Do not change the existing application's RTL UI or networking. Keep scheduled Nightly Build disabled.
4. Upload the exact unsigned EXE/MSI artifacts produced from the trusted build as GitHub workflow artifacts. Use `signpath/github-action-submit-signing-request@v3` with the artifact ID and approved parameters; configure the right ZIP/artifact layout for EXE/MSI. SignPath must verify build origin.
5. Require the foundation's/SignPath's manual signing approval where applicable. Download signed artifacts to a fresh output directory. Confirm filename, SHA256, release metadata, product version, publisher identity, signature status and timestamp. Do **not** overwrite unsiged artifacts in place or publish unsigned releases under a “signed” label.
6. Fail the signed release if signing or signature validation fails. On Windows, validate with `Get-AuthenticodeSignature` and the Windows SDK's `signtool verify /pa /v` on each final EXE/MSI. An Authenticode signature does not guarantee SmartScreen reputation.
7. Only after these checks, publish a distinctly labeled **signed** release. Do not use an unsupported self-signed certificate to imply Windows trust.

## Existing build caution

The existing script `.github/scripts/sign-windows-artifacts.ps1` exits successfully when the two PFX secrets are absent, leaving release artifacts unsigned. This remains unchanged by this documentation-only preparation. Before a signed release is advertised, the signing workflow must enforce a **fail-closed** check (separately, once the signing provider and approved artifact layout are configured). Do not add a public release trigger that assumes SignPath approval.

## Official references

- SignPath Foundation eligibility and signing policy: https://signpath.org/terms
- Application: https://signpath.org/apply
- GitHub integration: https://docs.signpath.io/trusted-build-systems/github
- Artifact configuration: https://docs.signpath.io/projects
