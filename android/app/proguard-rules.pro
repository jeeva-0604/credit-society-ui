# Your generated rules (Paste them here)
-dontwarn com.oney.WebRTCModule.**
-dontwarn org.webrtc.**
-dontwarn com.oney.WebRTCModule.EglUtils
-dontwarn com.oney.WebRTCModule.WebRTCModuleOptions
-dontwarn com.oney.WebRTCModule.WebRTCModulePackage
-dontwarn com.oney.WebRTCModule.webrtcutils.H264AndSoftwareVideoEncoderFactory
-dontwarn com.oney.WebRTCModule.webrtcutils.SoftwareVideoDecoderFactoryProxy
-dontwarn org.webrtc.AudioTrackSink
-dontwarn org.webrtc.DataPacketCryptor$EncryptedPacket
-dontwarn org.webrtc.DataPacketCryptor
-dontwarn org.webrtc.DataPacketCryptorFactory
-dontwarn org.webrtc.ExternalAudioProcessingFactory$AudioProcessing
-dontwarn org.webrtc.ExternalAudioProcessingFactory
-dontwarn org.webrtc.FrameCryptor$FrameCryptionState
-dontwarn org.webrtc.FrameCryptor$Observer
-dontwarn org.webrtc.FrameCryptor
-dontwarn org.webrtc.FrameCryptorAlgorithm
-dontwarn org.webrtc.FrameCryptorFactory
-dontwarn org.webrtc.FrameCryptorKeyProvider
-dontwarn org.webrtc.RtcError
-dontwarn org.webrtc.RtpCapabilities$CodecCapability
-dontwarn org.webrtc.RtpCapabilities$HeaderExtensionCapability
-dontwarn org.webrtc.RtpCapabilities
-dontwarn org.webrtc.WrappedVideoDecoderFactory
-dontwarn org.webrtc.audio.JavaAudioDeviceModule$PlaybackSamplesReadyCallback

# 🚀 Add these manually to protect your Voice Call functionality
-keep class org.webrtc.** { *; }
-keep interface org.webrtc.** { *; }
-keep class com.cloudwebrtc.** { *; }
-keep class io.github.webrtc-sdk.** { *; }
-keepclassmembers class * {
    @org.webrtc.CalledByNative <methods>;
    native <methods>;
}