#!/bin/bash
# record.sh APK PACKAGE OUT_BASE [SECONDS]
# Installs the APK, starts it, records the screen with scrcpy, keeps the Godot log and closes the app.
# The phone must be unlocked and in landscape. Count the fault frames after:
#   python3 scan_still.py OUT_BASE.mp4 OUT_BASE.scan && python3 tally.py OUT_BASE.scan
set -u
ADB=${ADB:-adb}; export ADB
apk=$1; pkg=$2; out=$3; secs=${4:-90}
$ADB install -r "$apk" | tail -1
$ADB logcat -c
$ADB logcat -v epoch godot:V '*:S' > "$out.log" & logcat_pid=$!
$ADB shell monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
sleep "${WARMUP:-15}"
scrcpy --no-window --no-control --capture-orientation=@270 --time-limit="$secs" --record="$out.mp4" > /dev/null 2>&1
$ADB shell am force-stop "$pkg"
kill $logcat_pid 2> /dev/null
