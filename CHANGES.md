# Amethyst iOS 2.0.1 — What's new

## 1. Voice Chat Mic now works

**Problem:** The mic didn't send any audio after you turned it on.  
**Fix:** Fixed a bug where the mic would start then immediately stop. Now the mic keeps running.

**Problem:** The app crashed with "SIGILL" when using voice chat.  
**Fix:** Stopped loading macOS-only audio libraries on iOS. Voice chat now uses a pure Java version instead.

## 2. iOS Audio Capture

Added a new way for Java apps to use the iPhone microphone through `javax.sound`.

| File | What it does |
|------|-------------|
| `NativeAudioCapture.java` | Connects Java to the iOS mic |
| `IOSTargetDataLine.java` | Handles audio input (16-bit mono) |
| `IOSAudioMixer.java` | Provides the microphone to Java apps |
| `IOSAudioMixerProvider.java` | Makes the mic discoverable |
| `audio_capture_bridge.m` | Captures mic audio using AVFoundation |
| `CMakeLists.txt` | Build setup for the mic module |

## 3. GitHub Actions fix

Updated build scripts to use the latest GitHub Actions (Node 24). Removed a Homebrew warning about untrusted taps.
