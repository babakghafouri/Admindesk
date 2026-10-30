"""Pin the AdminDesk network endpoints in the hbb_common submodule at build time.

The upstream hbb_common repository is a Git submodule, so its checked-in upstream
commit is not edited from this repository. This script patches the build workspace
before compiling Windows and Android clients.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
HBB_SRC = ROOT / "libs" / "hbb_common" / "src"
CONFIG_SOURCE = HBB_SRC / "config.rs"
LIB_SOURCE = HBB_SRC / "lib.rs"

HOST = "Desk.admin98.ir"
PUBLIC_KEY = "lcUnP6wMPG9948IHDqLyKVoSMSq85xqUnlpNtuRZexM="
VERSION_CHECK_URL = f"https://{HOST}/version/latest"
UPSTREAM_DEFAULT_KEY = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw="


def replace_once(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, lambda _: replacement, text)
    if count != 1:
        raise SystemExit(f"Expected exactly one {label} match; got {count}")
    return updated


if not CONFIG_SOURCE.is_file() or not LIB_SOURCE.is_file():
    raise SystemExit(f"Missing hbb_common sources under: {HBB_SRC}")

config_text = CONFIG_SOURCE.read_text(encoding="utf-8")
config_text = replace_once(
    config_text,
    r'(?m)^pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[[^\n]*\];$',
    f'pub const RENDEZVOUS_SERVERS: &[&str] = &["{HOST}"];',
    "RENDEZVOUS_SERVERS",
)
config_text = replace_once(
    config_text,
    r'(?m)^pub const RS_PUB_KEY: &str = "[^"\n]*";$',
    f'pub const RS_PUB_KEY: &str = "{PUBLIC_KEY}";',
    "RS_PUB_KEY",
)

for name, port in (
    ("RENDEZVOUS_PORT", 21116),
    ("RELAY_PORT", 21117),
    ("WS_RENDEZVOUS_PORT", 21118),
    ("WS_RELAY_PORT", 21119),
):
    match = re.search(rf"(?m)^pub const {name}: i32 = (\d+);$", config_text)
    if not match or int(match.group(1)) != port:
        raise SystemExit(f"Unexpected {name}; refusing to build with unknown server ports")

if "rs-ny.rustdesk.com" in config_text or UPSTREAM_DEFAULT_KEY in config_text:
    raise SystemExit("Public RustDesk rendezvous defaults remain in hbb_common config")

lib_text = LIB_SOURCE.read_text(encoding="utf-8")
lib_text = replace_once(
    lib_text,
    r'(?m)^    const URL: &str = "https://api\.rustdesk\.com/version/latest";$',
    f'    const URL: &str = "{VERSION_CHECK_URL}";',
    "version-check endpoint",
)

# These are test fixtures only. Keep the submodule's websocket/NAT tests aligned
# with the AdminDesk host without changing the runtime generic-host logic.
socket_tests = HBB_SRC / "socket_client.rs"
socket_text = socket_tests.read_text(encoding="utf-8")
if "rustdesk.com" in socket_text:
    socket_text = socket_text.replace("rustdesk.com", HOST)
    socket_tests.write_text(socket_text, encoding="utf-8")

websocket_tests = HBB_SRC / "websocket.rs"
websocket_text = websocket_tests.read_text(encoding="utf-8")
if "rustdesk.com" in websocket_text:
    websocket_text = (
        websocket_text
        .replace("relay.rustdesk.com", HOST)
        .replace("api.rustdesk.com", HOST)
        .replace("rustdesk.com", HOST)
    )
    websocket_tests.write_text(websocket_text, encoding="utf-8")

if "api.rustdesk.com/version/latest" in lib_text:
    raise SystemExit("Public RustDesk version-check endpoint remains after patching")

CONFIG_SOURCE.write_text(config_text, encoding="utf-8")
LIB_SOURCE.write_text(lib_text, encoding="utf-8")
print(
    "Pinned AdminDesk rendezvous host, relay defaults, public key, and "
    "version-check endpoint; validated server ports."
)
