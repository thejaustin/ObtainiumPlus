---
name: logcat_analyzer
description: An intelligent tool to analyze Android ADB Logcat output for dev.imranr.obtainium. It filters for errors and exceptions, parsing stack traces to find root causes in the codebase.
---

# Logcat Analyzer

This skill equips you with the ability to intelligently analyze Android system logs (Logcat) for the ObtainiumPlus application.
Instead of dealing with massive streams of unstructured text, use this skill to extract exactly what you need.

## Instructions
1. Run `adb shell pidof dev.imranr.obtainium` to get the process ID of the application.
2. If the app is running, use `adb logcat -d --pid=<PID> *:E` to dump all errors for this specific app.
3. If the app crashed and the PID is lost, use `adb logcat -d -b crash` to extract the crash buffer.
4. Analyze the stack trace lines that refer to `package:obtainium` to pinpoint the exact Dart file and line number causing the issue.
5. If the crash is native (Java/Kotlin/C++), cross-reference it with the `android-docs-mcp` to check for expected behavior or API limitations.

## When to use
- The app crashes unexpectedly on startup or during a specific user interaction.
- The user reports an ANR (Application Not Responding).
- You are trying to verify if a background task (like WorkManager or the AppUpdateService) threw a silent exception.
