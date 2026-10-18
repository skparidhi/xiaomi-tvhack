"""Pair this PC with the Xiaomi TV via the Android TV Remote protocol.

Starts pairing (the TV shows a 6-character code), then waits for the code to
appear in pairing_code.txt and finishes pairing. Certs are saved in ./certs.
"""
import asyncio
import pathlib
import sys

from androidtvremote2 import AndroidTVRemote

HOST = "192.168.1.18"
HERE = pathlib.Path(__file__).parent
CERTS = HERE / "certs"
CODE_FILE = HERE / "pairing_code.txt"


async def main() -> None:
    CERTS.mkdir(exist_ok=True)
    CODE_FILE.unlink(missing_ok=True)
    remote = AndroidTVRemote("Paridhi PC", str(CERTS / "cert.pem"), str(CERTS / "key.pem"), HOST)
    await remote.async_generate_cert_if_missing()
    await remote.async_start_pairing()
    print("Pairing started: the TV should now show a code.", flush=True)

    for _ in range(600):  # wait up to 5 minutes
        if CODE_FILE.exists() and (code := CODE_FILE.read_text().strip()):
            await remote.async_finish_pairing(code)
            CODE_FILE.unlink()
            print("Paired successfully.", flush=True)
            return
        await asyncio.sleep(0.5)
    sys.exit("Timed out waiting for the pairing code.")


asyncio.run(main())
