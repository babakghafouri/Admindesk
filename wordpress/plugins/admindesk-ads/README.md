# AdminDesk Ads (WordPress)

This feature uses only the existing AdminDesk WordPress installation at `admindesk.ir`.
It does not use Admin98.ir or any legacy advertising server.

## WordPress plugin

Install the separately packaged `admindesk-ads.zip` plugin in the same WordPress site where **AdminDesk Control Center** is installed. It adds its campaign and category screens below the existing AdminDesk dashboard menu.

## REST API

- `GET /wp-json/admindesk/v1/ads/categories`
- `GET /wp-json/admindesk/v1/ads?category=<slug>`
- `POST /wp-json/admindesk/v1/ads/events`

Read endpoints return only published campaigns assigned to the requested category and inside their configured schedule. When the API returns no matching campaign, the client retains its bundled public AdminDesk slides.

Event requests contain only an ad ID, event type, event UUID and category slug. No device identity, personal data, connection IDs, remote-session data or passwords are sent.

## Client behavior

- Industry slug is stored in the existing local AdminDesk configuration store.
- On first use, the user chooses an industry from WordPress categories.
- The user can change the industry from the carousel category icon.
- The client refreshes the feed every five minutes.
- Only HTTPS images hosted on `admindesk.ir` are accepted.
- Ad clicks open the target in the system's default browser.
- Network and analytics failures never block remote desktop features.
- No Rust core, FFI, notification or update code is modified.

## WordPress campaign setup

1. Create categories under **AdminDesk → مدیریت اصناف**.
2. Add a campaign under **AdminDesk → تبلیغات**.
3. Set a featured image, destination URL, optional copy, schedule and priority.
4. Assign one or more industry categories.
5. Publish the campaign.

The plugin's public API never falls back to unrelated campaigns. The client displays its built-in public slides if no matching campaign is returned.
