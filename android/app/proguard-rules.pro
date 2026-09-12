# Flutter ProGuard & R8 Obfuscation Rules

# Flutter Wrapper & Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve Flutter Entrypoint and Annotations
-keep @interface io.flutter.annotation.Keep
-keep @io.flutter.annotation.Keep class * { *; }
-keepclassmembers class * {
    @io.flutter.annotation.Keep *;
}

# Preserve native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve Generated Plugins Registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# WebView Flutter
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keep class android.webkit.** { *; }

# SQLite / Sqflite
-keep class com.tekartik.sqflite.** { *; }

# AudioPlayers
-keep class xyz.luan.audioplayers.** { *; }

# Don't warn on missing optional references
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
