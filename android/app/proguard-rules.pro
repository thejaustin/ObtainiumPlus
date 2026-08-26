# R8/ProGuard rules for release builds (minifyEnabled/shrinkResources were
# never on before — these keep rules are conservative on purpose, favoring
# "don't strip" over squeezing out the last few KB, since a wrong strip here
# means a runtime crash rather than a build failure.

# The Flutter Gradle plugin already injects its own default rules for
# io.flutter.** at build time; nothing needed here for the engine itself.

# --- Sentry ---------------------------------------------------------------
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# --- Shizuku (shizuku_apk_installer) — AIDL-generated binder classes ------
-keep class rikka.shizuku.** { *; }
-keep interface rikka.shizuku.** { *; }
-dontwarn rikka.shizuku.**

# --- flutter_local_notifications -------------------------------------------
-keep class com.dexterous.** { *; }

# --- home_widget — broadcast receiver / provider classes are already kept
# via the manifest-components default rules in proguard-android-optimize.txt,
# but the plugin's own bridging classes use reflection to find widget data.
-keep class es.antonborri.home_widget.** { *; }

# --- background_fetch / flutter_foreground_task — background service
# classes referenced only from AndroidManifest.xml or reflectively.
-keep class com.transistorsoft.** { *; }
-keep class com.pravera.flutter_foreground_task.** { *; }

# --- General reflection/serialization safety net --------------------------
# Several plugins (and Play Services libs pulled in transitively) use Gson
# or similar reflection-based (de)serialization; keep field names/generic
# signatures so that isn't silently broken by renaming.
-keepattributes Signature,*Annotation*,InnerClasses,EnclosingMethod
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# --- This app's own native bridge (MainActivity.kt) ------------------------
# Reflection targets there (PackageInstaller APIs) are platform classes,
# not app code, so no keep needed for them specifically — but keep the
# activity itself and any Kotlin data classes it exposes over MethodChannel.
-keep class dev.thejaustin.obtainiumplus.** { *; }
