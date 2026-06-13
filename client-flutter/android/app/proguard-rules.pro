-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Google Play Core — referenced by Flutter split-install classes but not used in our app
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Suppress all R8 missing-class warnings from flutter_tools internals
-dontwarn io.flutter.app.FlutterPlayStoreSplitApplication
