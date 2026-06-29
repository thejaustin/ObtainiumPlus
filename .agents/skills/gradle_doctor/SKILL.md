---
name: gradle_doctor
description: An intelligent tool to diagnose and fix Gradle build errors in Android/Flutter projects.
---

# Gradle Doctor

This skill makes you an expert at resolving Gradle dependency conflicts, build failures, and configuration errors.

## Instructions
1. If an APK build fails (e.g. `flutter build apk`), capture the exact error output.
2. If the error is a dependency resolution failure (like "Could not resolve all files for configuration ':app:debugRuntimeClasspath'"):
   a. Check `android/build.gradle` for `minSdkVersion` and `compileSdkVersion`.
   b. Use your web search tool to find the exact Maven package version needed.
   c. Adjust the versions in `pubspec.yaml` or `android/app/build.gradle`.
3. If the error mentions missing SDKs or NDKs, run `flutter doctor -v` and check the Android toolchain status.
4. For persistent cache issues, you can recommend or run `cd android && ./gradlew clean`.

## When to use
- The Flutter build fails during the Gradle assembly phase.
- There are AndroidX migration or compatibility errors.
- You encounter dependency version mismatch errors between plugins.
