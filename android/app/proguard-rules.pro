# Flutter Framework and Engine Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Keep native methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Flutter plugins
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# AndroidX & Datastore
-dontwarn androidx.**
-keep class androidx.datastore.** { *; }
-keep class androidx.preference.** { *; }

# Google Play Core (optional deferred components referenced by Flutter embedding)
-dontwarn com.google.android.play.core.**

# Prevent obfuscation of generated plugin registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
