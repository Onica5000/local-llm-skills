---
name: android-adb
description: Use to inspect, debug, or control an Android phone from this PC â€” adb (shell, logcat, packages, diagnostics), fastboot (bootloader/recovery), and scrcpy (mirror & control the phone screen).
---

# android-adb

Android platform-tools 37 installed at `D:\Programs\AndroidSDK\platform-tools\` (on PATH).

## Setup / connect
1. On the phone: enable Developer Options â†’ USB debugging.
2. Plug in USB, then approve the prompt on the phone.
```powershell
adb devices            # confirm the phone shows as "device" (not "unauthorized")
adb kill-server; adb start-server   # if it won't connect
```

## adb â€” diagnostics & control
```powershell
adb shell dumpsys battery            # battery health/level
adb shell dumpsys meminfo            # memory
adb shell pm list packages           # installed packages
adb shell pm list packages -3        # third-party apps only
adb logcat                            # live log (Ctrl-C to stop)
adb logcat -d > log.txt               # dump log to file
adb pull /sdcard/DCIM ./DCIM          # copy files off the phone
adb push file.txt /sdcard/            # copy files to the phone
adb install app.apk                   # install an APK
adb shell screencap -p /sdcard/s.png; adb pull /sdcard/s.png   # screenshot
adb reboot                            # reboot (also: adb reboot recovery / bootloader)
```

## fastboot â€” bootloader / recovery (only when phone is in fastboot mode)
```powershell
fastboot devices
fastboot flash recovery recovery.img
fastboot reboot
```

## scrcpy 4.0 â€” see & control the screen on your PC
```powershell
scrcpy                 # USB mirror + control
scrcpy --record file.mp4   # mirror and record
```

## Rules
- Use `scrcpy` when the problem is visual (UI, touch). Use `adb shell` for data/diagnostics.
- fastboot/flashing is risky â€” confirm with the user and the exact image before flashing anything.

