"""Pin the Windows RustDesk core to the AdminDesk rendezvous infrastructure.

Only the vendored hbb_common source used in the build workspace is modified.
The upstream submodule reference and other platforms remain untouched.
This ports the relevant build-time server/key replacement from rdgen.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "libs" / "hbb_common" / "src" / "config.rs"
HOST = "desk.admin98.ir"
PUBLIC_KEY = "lcUnP6wMPG9948IHDqLyKVoSMSq85xqUnlpNtuRZexM="

if not SOURCE.is_file():
    raise SystemExit(f"Missing hbb_common config source: {SOURCE}")

text = SOURCE.read_text(encoding="utf-8")
replacements = (
    (r"(?m)^pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[[^\n]*\];$",
     f'pub const RENDEZVOUS_SERVERS: &[&str] = &["{HOST}"];'),
    (r'(?m)^pub const RS_PUB_KEY: &str = "[^"\n]*";$',
     f'pub const RS_PUB_KEY: &str = "{PUBLIC_KEY}";'),
)
for pattern, replacement in replacements:
    text, count = re.subn(pattern, lambda _: replacement, text)
    if count != 1:
        raise SystemExit(f"Expected exactly one hbb_common match for {pattern}; got {count}")

for name, port in (
    ("RENDEZVOUS_PORT", 21116), ("RELAY_PORT", 21117),
    ("WS_RENDEZVOUS_PORT", 21118), ("WS_RELAY_PORT", 21119),
):
    match = re.search(rf"(?m)^pub const {name}: i32 = (\d+);$", text)
    if not match or int(match.group(1)) != port:
        raise SystemExit(f"Unexpected {name}; refusing to build with unknown server ports")

SOURCE.write_text(text, encoding="utf-8")
print("Pinned Windows rendezvous host and matching public key; checked all ports.")
