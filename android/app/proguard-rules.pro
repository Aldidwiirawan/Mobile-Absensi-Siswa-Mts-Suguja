# ==============================================================================
# Flutter & Android Proguard / R8 Optimization Rules
# ==============================================================================

# 1. Flutter Framework & Embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 2. OneSignal Push Notification SDK
-dontwarn com.onesignal.**
-keep class com.onesignal.** { *; }
-keep interface com.onesignal.** { *; }
-keepclassmembers class com.onesignal.** { *; }

# 3. Mobile Scanner & Google ML Kit Barcode Processing
-keep class dev.steenbakker.mobile_scanner.** { *; }
-dontwarn dev.steenbakker.mobile_scanner.**
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# 4. Networking, WebSockets & Security
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.conscrypt.**

# 5. Core Enums and Data Models
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
