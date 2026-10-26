# Flutter Engine & Plugin Registrant Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Kotlin coroutines & serialization metadata used by supabase_flutter / app_links
-keepattributes *Annotation*,InnerClasses,Signature,EnclosingMethod
-dontwarn kotlinx.coroutines.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Google Play Core deferred components (referenced conditionally by Flutter engine)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# AndroidX & Security Crypto
-dontwarn androidx.security.crypto.**
-dontwarn androidx.**

