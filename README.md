# xiaomi — MiTV4I debloat and launcher

Living Room TV (Xiaomi MiTV4I, Android TV 9) at `192.168.1.18`, debloated over ADB and running a
clean Apple TV style home screen. Built on [tv-vibehack](https://github.com/Gathin23/tv-vibehack)
(MIT, see `LICENSE-tv-vibehack`), with its scripts switched to the Windows `adb` binary.

## What was done

1. **Uninstalled for user 0** (`pm uninstall --user 0`): Xiaomi-pushed streaming apps, the autoinstall
   configs, Xiaomi and Sensara tracking, retired Google apps and some Play Store apps. The full list
   is in [`removed-packages.txt`](removed-packages.txt).
2. **Disabled** (`pm disable-user`): PatchWall, recommendation rows, TV Manager, the update service,
   Mi Cast, Mi Music and Mi Gallery. See
   [`examples/xiaomi-mitv4i/debloat.txt`](examples/xiaomi-mitv4i/debloat.txt).
3. **Installed the launcher** (`com.gathin.tvhome`) as home and disabled the stock Google TV
   launcher.

Kept: voice assistant, Chromecast, Play Store and Play Services, Live TV and HDMI inputs, the
Bluetooth remote pairing guide and parental lock.

A backup of the package list, props and settings from before the changes is in `backup/` (not
committed).

## Requirements

- `adb` (`winget install Google.PlatformTools`), USB debugging on in the TV's Developer options
- To build the launcher: JDK 17 (`winget install EclipseAdoptium.Temurin.17.JDK`) and the Android
  SDK with `platforms;android-34` and `build-tools;34.0.0` in `%LOCALAPPDATA%\Android\Sdk`

## Common tasks

Change the dock order, hidden apps or columns in
[`launcher/app/src/main/res/values/config.xml`](launcher/app/src/main/res/values/config.xml), then:

```powershell
powershell -ExecutionPolicy Bypass -File launcher\build-and-install.ps1
```

Re-enable one disabled app:

```powershell
adb -s 192.168.1.18:5555 shell pm enable com.xiaomi.mitv.updateservice
```

Bring back one uninstalled app:

```powershell
adb -s 192.168.1.18:5555 shell cmd package install-existing com.spotify.tv.android
```

Undo the debloat and go back to the stock launcher:

```powershell
powershell -ExecutionPolicy Bypass -File tools\restore.ps1 examples\xiaomi-mitv4i\debloat.txt
```

Turn on the matching Clock screensaver:

```powershell
adb -s 192.168.1.18:5555 shell "settings put secure screensaver_components com.gathin.tvhome/.ClockDream; settings put secure screensaver_enabled 1"
```

Check for a firmware update: re-enable `com.xiaomi.mitv.updateservice`, update from Settings, then
disable it again. Updates can re-enable packages, so re-run `tools\disable.ps1` afterwards.

## Remote control without ADB

[`tv.py`](tv.py) talks to the TV over the Android TV Remote protocol (paired once with
[`pair.py`](pair.py); keys live in `certs/`, not committed):

```powershell
.venv\Scripts\python.exe tv.py key VOLUME_UP
.venv\Scripts\python.exe tv.py open https://www.youtube.com
```
