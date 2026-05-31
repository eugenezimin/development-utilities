#!/usr/bin/swift
import CoreAudio
import Foundation

func getDeviceName(_ deviceID: AudioObjectID) -> String {
    var propAddr = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceNameCFString,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var name: Unmanaged<CFString>? = nil
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    AudioObjectGetPropertyData(deviceID, &propAddr, 0, nil, &size, &name)
    return name?.takeRetainedValue() as String? ?? ""
}

func getAvailableSampleRates(_ deviceID: AudioObjectID) -> [Float64] {
    var propAddr = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyAvailableNominalSampleRates,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var size: UInt32 = 0
    AudioObjectGetPropertyDataSize(deviceID, &propAddr, 0, nil, &size)
    let count = Int(size) / MemoryLayout<AudioValueRange>.size
    var ranges = [AudioValueRange](repeating: AudioValueRange(), count: count)
    AudioObjectGetPropertyData(deviceID, &propAddr, 0, nil, &size, &ranges)
    // For USB devices, mMinimum == mMaximum (discrete rates)
    return ranges.map { $0.mMinimum }
}

func getInputStreams(_ deviceID: AudioObjectID) -> [AudioObjectID] {
    var propAddr = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyStreams,
        mScope: kAudioObjectPropertyScopeInput,   // input scope = microphone
        mElement: kAudioObjectPropertyElementMain
    )
    var size: UInt32 = 0
    AudioObjectGetPropertyDataSize(deviceID, &propAddr, 0, nil, &size)
    let count = Int(size) / MemoryLayout<AudioObjectID>.size
    var streams = [AudioObjectID](repeating: 0, count: count)
    AudioObjectGetPropertyData(deviceID, &propAddr, 0, nil, &size, &streams)
    return streams
}

func getStreamSampleRate(_ streamID: AudioObjectID) -> Float64 {
    var propAddr = AudioObjectPropertyAddress(
        mSelector: kAudioStreamPropertyVirtualFormat,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var format = AudioStreamBasicDescription()
    var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
    AudioObjectGetPropertyData(streamID, &propAddr, 0, nil, &size, &format)
    return format.mSampleRate
}

func setStreamSampleRate(_ streamID: AudioObjectID, rate: Float64) -> OSStatus {
    var propAddr = AudioObjectPropertyAddress(
        mSelector: kAudioStreamPropertyVirtualFormat,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var format = AudioStreamBasicDescription()
    var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
    // Read current format first, then only change sample rate
    AudioObjectGetPropertyData(streamID, &propAddr, 0, nil, &size, &format)
    format.mSampleRate = rate
    return AudioObjectSetPropertyData(streamID, &propAddr, 0, nil, size, &format)
}

// --- Main ---

var propAddr = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDevices,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
)
var dataSize: UInt32 = 0
AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil, &dataSize)
let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
var devices = [AudioObjectID](repeating: 0, count: deviceCount)
AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil, &dataSize, &devices)

for deviceID in devices {
    let name = getDeviceName(deviceID)
    guard name.contains("C920") else { continue }

    let available = getAvailableSampleRates(deviceID)
    print("📷 \(name)")
    print("   Available rates: \(available.map { Int($0) })")

    let target: Float64 = available.contains(32000) ? 32000 : (available.contains(48000) ? 48000 : available.last ?? 44100)
    print("   Targeting: \(Int(target)) Hz")

    let streams = getInputStreams(deviceID)
    print("   Input streams: \(streams.count)")

    for streamID in streams {
        let before = getStreamSampleRate(streamID)
        let status = setStreamSampleRate(streamID, rate: target)
        let after = getStreamSampleRate(streamID)

        if status == noErr {
            print("   ✅ Stream \(streamID): \(Int(before)) → \(Int(after)) Hz")
        } else {
            let code = UInt32(bitPattern: status)
            let chars = (0..<4).map { Character(UnicodeScalar((code >> (24 - $0 * 8)) & 0xFF)!) }
            print("   ❌ Stream \(streamID): OSStatus \(status) ('\(String(chars))')")
        }
    }
}