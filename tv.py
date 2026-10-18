"""Control the paired Xiaomi TV.

Usage:
  python tv.py key HOME [BACK DPAD_UP ...]   send remote keys (KEYCODE_ names without prefix)
  python tv.py open https://youtube.com      open a link / app deep link
  python tv.py info                          show power, current app and volume
"""
import asyncio
import pathlib
import sys

from androidtvremote2 import AndroidTVRemote

HOST = "192.168.1.18"
CERTS = pathlib.Path(__file__).parent / "certs"


async def main(args: list[str]) -> None:
    remote = AndroidTVRemote("Paridhi PC", str(CERTS / "cert.pem"), str(CERTS / "key.pem"), HOST)
    await remote.async_connect()
    try:
        cmd, rest = args[0], args[1:]
        if cmd == "key":
            for key in rest:
                remote.send_key_command(key.upper())
                await asyncio.sleep(0.3)
        elif cmd == "open":
            remote.send_launch_app_command(rest[0])
        elif cmd == "info":
            await asyncio.sleep(1)
            print(f"on={remote.is_on} app={remote.current_app} volume={remote.volume_info}")
        else:
            sys.exit(__doc__)
        await asyncio.sleep(0.5)
    finally:
        remote.disconnect()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    asyncio.run(main(sys.argv[1:]))
