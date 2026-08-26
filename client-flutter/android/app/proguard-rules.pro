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

# Unity LevelPlay / ironSource
-keepclassmembers class com.ironsource.sdk.controller.IronSourceWebView$JSInterface { public *; }
-keepclassmembers class * implements android.os.Parcelable { public static final android.os.Parcelable$Creator *; }
-keep public class com.google.android.gms.ads.** { public *; }
-keep class com.ironsource.adapters.** { *; }
-keep class com.ironsource.unity.androidbridge.** { *; }
-dontwarn com.ironsource.mediationsdk.**
-dontwarn com.ironsource.adapters.**
-keepattributes JavascriptInterface
-keepclassmembers class * { @android.webkit.JavascriptInterface <methods>; }

# Mediated networks
-keep class com.unity3d.ads.** { *; }
-keep class com.unity3d.services.** { *; }
-dontwarn com.unity3d.services.**
-dontwarn com.ironsource.adapters.unityads.**
-keeppackagenames com.facebook.*
-keep public class com.facebook.ads.** { *; }
-dontwarn com.facebook.ads.internal.**
-keep public class com.applovin.sdk.AppLovinSdk { *; }
-keep public class com.applovin.sdk.AppLovin* { public protected *; }
-keep public class com.applovin.nativeAds.AppLovin* { public protected *; }
-keep public class com.applovin.adview.* { public protected *; }
-keep public class com.applovin.mediation.* { public protected *; }
-keep public class com.applovin.mediation.ads.* { public protected *; }
-keep class com.applovin.mediation.adapters.** { *; }
-keep class com.applovin.mediation.adapter.** { *; }
-keep class com.vungle.** { *; }
-dontwarn com.vungle.**
-keepattributes Signature,*Annotation*
-keep class com.mbridge.** { *; }
-keep interface com.mbridge.** { *; }
-dontwarn com.mbridge.**
-keep class **.R$* { public static final int mbridge*; }
-keep class com.bytedance.sdk.** { *; }
-keep class com.inmobi.** { *; }
-dontwarn com.inmobi.**
-dontwarn com.squareup.picasso.**
-keep class com.squareup.picasso.** { *; }
-keep class com.moat.** { *; }
-dontwarn com.moat.**
-keep class com.integralads.avid.library.* { *; }
-keep class com.chartboost.** { *; }
