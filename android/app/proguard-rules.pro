# Keep the Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Keep just_audio and the proxy server
-keep class com.ryanheise.just_audio.** { *; }

# Keep the background audio service
-keep class com.ryanheise.audioservice.** { *; }

# Keep the actual media player engine (ExoPlayer)
-keep class com.google.android.exoplayer2.** { *; }

# Fix for Google Play Core missing classes
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Also add these to prevent future R8 warnings
-keep class com.google.android.play.core.** { *; }