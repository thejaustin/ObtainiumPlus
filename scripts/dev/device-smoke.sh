#!/usr/bin/env bash
# Quick post-install smoke: launch the release app, wait, check it is alive and
# that logcat has no fatal errors from it. Usage: device-smoke.sh [package]
set -u
PKG="${1:-dev.thejaustin.obtainiumplus}"
adb get-state >/dev/null 2>&1 || { echo "no adb device (run: adb connect 127.0.0.1:5555)"; exit 2; }
adb shell pm path "$PKG" >/dev/null || { echo "$PKG not installed"; exit 2; }
adb logcat -c
adb shell am force-stop "$PKG"
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 12
pid=$(adb shell pidof "$PKG" | tr -d '\r')
fatal=$(adb logcat -d -b crash 2>/dev/null | command grep -c "$PKG")
ver=$(adb shell dumpsys package "$PKG" | command grep -m1 versionName | tr -d ' \r')
echo "package=$PKG $ver pid=${pid:-none} crash_lines=$fatal"
if [ -z "$pid" ] || [ "$fatal" -gt 0 ]; then echo "SMOKE FAIL"; exit 1; fi
echo "SMOKE OK"
