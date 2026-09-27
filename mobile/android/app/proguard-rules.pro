-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Play Core is referenced by in-app-update / deferred-component-install but is
# not on the release classpath, so R8 fails the build on the unresolved
# references. We never call it, so silence them instead of shipping the lib.
-dontwarn com.google.android.play.core.**
