# Flutter Engine & Plugin Registrant Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# App Activities & Entrypoints
-keep class com.vestora.app.MainActivity { *; }
-keep class com.smartwardrobe.smart_wardrobe.MainActivity { *; }

# Keep Kotlin coroutines & serialization metadata used by supabase_flutter / app_links
-keepattributes *Annotation*,InnerClasses,Signature,EnclosingMethod,SourceFile,LineNumberTable
-dontwarn kotlinx.coroutines.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Google Play Core deferred components (referenced conditionally by Flutter engine)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# AndroidX & Security Crypto
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**
-dontwarn androidx.**

# Flutter Secure Storage & Tink Cryptographic Library
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# Native Storage & Preferences Plugins
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-keep class com.llfbandit.app_links.** { *; }

# Preserve image_picker package classes, Pigeon platform channels, FileProvider, and Parcelables
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class dev.flutter.pigeon.image_picker_android.** { *; }
-keep class androidx.core.content.FileProvider { *; }
-keepclassmembers class * implements android.os.Parcelable {
    static android.os.Parcelable$Creator CREATOR;
}
