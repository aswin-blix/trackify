# Trackify R8 / ProGuard rules.
# Flutter's own engine rules are injected by the Flutter Gradle plugin.

# flutter_local_notifications serialises scheduled notifications with Gson;
# obfuscating these classes breaks rescheduling after reboot.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod, InnerClasses
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.gson.**

# local_auth uses AndroidX Biometric via reflection-free APIs, but keep the
# fragment activity subclass name stable for the system credential flow.
-keep class com.blixcode.trackify.MainActivity { *; }

# Kotlin metadata used by several plugins.
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Google Play Core is referenced by Flutter's deferred-components support but
# is not bundled here.
-dontwarn com.google.android.play.core.**
