# AdminDesk — Code signing policy (approval-pending draft)

**Status: approval-pending.** This page documents the project's proposed release-signing policy, not an issued certificate. On 2026-11-22 the project owner submitted a SignPath Foundation application and received acknowledgment of receipt, **not acceptance**. Currently published AdminDesk 1.5.2 EXE/MSI artifacts are not claimed to have a trusted Authenticode signature.

## Project and source

- Project: **AdminDesk**, public AGPL-3.0 fork of RustDesk
- Source repository: https://github.com/babakghafouri/Admindesk
- Parent: https://github.com/rustdesk/rustdesk
- Public releases: https://github.com/babakghafouri/Admindesk/releases
- Proposed privacy policy: [Privacy Policy — draft](ADMIN_DESK_PRIVACY_POLICY.md) (under maintainer review)

## SignPath Foundation program attribution

**Required attribution if and when approved:** “Free code signing provided by SignPath.io, certificate by SignPath Foundation”.

This attribution describes the planned free signing program. It **must not be interpreted as proof that the current AdminDesk executables are signed by SignPath Foundation**. Before approval and an actual verified signature, releases must prominently say `Unsigned`.

## Team roles and release approvals

Repository owner account: [babakghafouri](https://github.com/babakghafouri). This identifies the account that controls the repo, **not proof of the owner's legal identity or a complete list of trusted maintainers**.

- **Authors/committers:** repo members with write permission, subject to mandatory MFA. The owner must verify/record this roster.
- **Reviewers:** trusted repo collaborators assigned to review external contributions and security-sensitive workflow/script changes. The owner must identify these reviewers or document a single-maintainer process acceptable to SignPath.
- **Approvers:** team members approved to authorize each SignPath signing request. The owner must assign them in SignPath. No signing approval or SignPath permission has yet been established.

## Release and signing rules

1. Develop and review changes in the public repository. Do not sign third-party or opaque artifacts unrelated to the reviewed source.
2. Use the documented GitHub Actions build on an approved, reviewed release commit. Preserve immutable provenance of unsigned artifacts.
3. Review included upstream RustDesk binaries and dependencies for SignPath Foundation eligibility. A modified upstream fork is potentially eligible only under its published policy and approval.
4. Require human approval for every signing request, using the approved SignPath organization and artifact configuration. Never store keys or API tokens in repository source or logs.
5. Authenticate the approved release binary provenance; enforce consistent AdminDesk product name/version metadata in signed artifacts and assess the independently versioned RustDesk engine components.
6. Verify each final EXE/MSI signature and timestamp with Windows Authenticode validation (`Get-AuthenticodeSignature`, `signtool verify /pa /v`), check SHA-256 hashes and provide hashes on the release page.
7. **Fail closed:** do not label unsigned artifacts as signed or silently fall back to publishing an unsigned artifact under a signed release label. Existing unsigned preview release workflows remain separate until a signing workflow has been approved.
8. Maintain reproducible audit history of reviewed source commit, signing approver, verification and public release.
9. Require clear installation notices regarding system configuration changes and a documented uninstallation route.
10. Do not state that a valid signature guarantees removal of Microsoft Defender SmartScreen reputation warnings.

## Operational requirements before approval

- [ ] SignPath has accepted AdminDesk as eligible for its Foundation certificate.
- [ ] Source and bundled binary licensing and modified-upstream conditions verified.
- [ ] Privacy policy finalized, published and linked from home/download pages.
- [ ] Installation privacy notice and any required options to disable non-user-directed telemetry/ads implemented and tested.
- [ ] Team roles assigned and MFA verified.
- [ ] Code-signing policy is linked as **Code signing policy** on both project home and download/release pages.
- [ ] Signed binaries have the SignPath-enforced product name/version metadata.
- [ ] Signing workflow runs only after explicit approver authorization and verifies SignPath signature and timestamp before publishing.

## References

- SignPath Foundation conditions: https://signpath.org/terms
- Project onboarding plan: [SignPath application and eligibility checklist](ADMIN_DESK_SIGNPATH_APPLICATION.md)
