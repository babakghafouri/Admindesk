# AdminDesk Privacy Policy — review draft

**Status:** Draft for maintainer and infrastructure review, dated 2026-11-22. This document is public as a disclosure draft but is **not yet an approved or complete privacy policy** for release or a claim of SignPath compliance. The repo cannot establish server-side retention, legal controller identity, or all upstream RustDesk data flows by itself.

**Product:** AdminDesk, an AGPL-3.0 open-source modified fork of RustDesk. Source: https://github.com/babakghafouri/Admindesk . Website: https://admindesk.ir/ . The policy is intended to cover the AdminDesk desktop client and its AdminDesk-operated services, not third-party websites.

## 1. Remote desktop connection data

AdminDesk is remote access software. Users may configure rendezvous/relay hosts and connect to other devices. During remote sessions, network participants and infrastructure may receive connection metadata such as IP addresses, identifiers, timestamps and session routing information, and session content may be transmitted to the selected remote device and/or through the configured relay. Actual data flows, encryption, logs, retention and any fallback/default RustDesk servers **must be verified and described by the maintainer** before this becomes a final policy. AdminDesk must not claim that it never processes remote session data without a verified network review.

## 2. Automatic requests to AdminDesk services (confirmed in current Flutter source)

- **Advertising:** The desktop promotional carousel requests ad categories, images and ad data from `https://admindesk.ir/wp-json/admindesk/v1/ads/*` at startup and refreshes about every five minutes while foregrounded. It stores the chosen business/category option locally (`admindesk_ads_category`).
- **Ad event reporting:** For served ads, the client sends POST requests to `https://admindesk.ir/wp-json/admindesk/v1/ads/events` with ad ID, event type (impression/click), random event ID and selected category. Requests to this endpoint inherently expose network metadata such as the public source IP address to the receiving web infrastructure. Whether the server logs, stores, correlates or forwards this metadata, and retention periods, **remain to be audited**.
- **Notifications:** The desktop title bar requests public announcements from `https://admindesk.ir/wp-json/admindesk/v1/notifications?audience=all` on startup and about every five minutes. Read/unread notification IDs are maintained in the local application support directory, in `admindesk_notifications.json`.
- **Connectivity checks:** The desktop server health widget may make HTTPS requests to the notifications endpoint and `https://update.admindesk.ir/` and attempt TCP reachability checks to configured rendezvous and relay hosts. The exact trigger/timing of these checks must be verified.
- **Updates:** The client may check for releases/updates using its configured update service. The specific request parameters and version identifiers must be reviewed from the complete Rust/native code before the final policy is approved.

The client-side code above confirms outbound traffic; it does **not** establish what server-side access logs or analytics are retained, or by whom.

## 3. Information that may be stored locally

The client may store server addresses, device identifiers, saved devices, credentials or authentication-related settings, notification read IDs and selected advertising category according to user configuration. Some credentials may be protected using operating system or application mechanisms. Do not claim that all credentials are encrypted at rest until independently verified. Removing or uninstalling the client may not erase every user profile/support file automatically; the maintainer must document supported deletion steps.

## 4. User-initiated external links

When a user selects an advertisement, the client may open the advertiser's external URL in the operating system browser. The destination's privacy policy applies to that visit. The advertiser destination is not necessarily controlled by AdminDesk.

## 5. Purposes and recipients

The described processing supports remote connectivity, application announcements, service availability checks, updates and advertising operations. Recipients may include the user-selected remote endpoint and rendezvous/relay infrastructure, AdminDesk-operated web services and the provider(s) hosting them, and external advertised sites when opened. **Actual hosting providers, legal jurisdictions, data controller identity, subprocessors and retention periods are not yet confirmed.**

## 6. Choices and controls — implementation gap

Users choose their remote access endpoints and may select an advertising category. Current inspected desktop carousel code does not show a clear user opt-out for ad/notification background requests or impression reporting. A final policy must identify effective controls actually shipped, not invent them. The maintainer must review whether to add notice and opt-out choices during installation and/or before first use.

**SignPath Foundation requirement:** If the application collects user data and transmits it to systems not specified by the user, SignPath requires a privacy policy, that policy displayed during installation, and installation options to disable those transmissions. This remains an outstanding compliance task, not completed by publishing this draft. See https://signpath.org/terms .

## 7. Security

The project builds from its public GitHub repository and uses HTTPS for the specified WordPress/update endpoints. HTTPS alone does not establish end-to-end confidentiality of remote sessions. The maintainer must verify transport security, operational logging and incident reporting arrangements before making broader security claims.

## 8. Retention, access and deletion requests — details needed

**To be supplied by the accountable operator before publication as final:** legal name and contact address; applicable law and legal basis; web/relay logs and their retention; advertising event retention; access and deletion request procedure; optional analytics, cookies and third-party hosting disclosures; and the date of the most recent completed audit.

Public repository for technical issues: https://github.com/babakghafouri/Admindesk/issues . This is not represented as a private channel for sensitive personal information.

## 9. Changes

The policy should carry an effective date and change history once reviewed. Changes affecting user data or automatic network requests should be disclosed before release.

## Technical evidence inspected

- `flutter/lib/desktop/widgets/promo_carousel.dart` (categories, ad retrieval, event POST and refresh behavior)
- `flutter/lib/desktop/widgets/admindesk_titlebar.dart` (notifications, local read-state, connectivity probes)
- `flutter/lib/desktop/pages/desktop_setting_page.dart` (configurable options)

**Before publishing on admindesk.ir as an operative privacy policy:** verify all open items with the operator and complete server-side and upstream RustDesk network-data audit. Do not use this draft's GitHub URL as proof of SignPath privacy compliance.
