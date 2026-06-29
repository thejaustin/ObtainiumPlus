---
name: apk_analyzer
description: An intelligent tool to analyze Android APK builds for size, dex count, and manifest permissions.
---

# APK Analyzer

This skill equips you to thoroughly examine built APK files to catch bloat and security issues.

## Instructions
1. After running `flutter build apk --release`, locate the generated APK (usually in `build/app/outputs/flutter-apk/app-release.apk`).
2. Use the Android `apkanalyzer` CLI tool (if available in the environment) to inspect the APK.
3. Check the APK size. If the size jumped significantly compared to previous builds, drill down into `lib/` and `res/` sizes.
4. Dump the `AndroidManifest.xml` from the APK to verify that no unwanted or dangerous permissions were accidentally injected by third-party Flutter plugins.
5. If you find excessive DEX methods or unused resources, recommend ProGuard/R8 optimizations in `app/build.gradle`.

## When to use
- Right before finalizing a major release to ensure the binary is lean and secure.
- When debugging issues where third-party packages silently declare unwanted Android permissions.
- When investigating slow app startup times.
