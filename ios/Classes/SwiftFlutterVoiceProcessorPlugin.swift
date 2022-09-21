//
// Copyright 2020-2021 Picovoice Inc.
//
// You may not use this file except in compliance with the license. A copy of the license is located in the "LICENSE"
// file accompanying this source.
//
// Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//

import Flutter
import UIKit
import AVFoundation

public class SwiftFlutterVoiceProcessorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var settingsTimer: Timer?
    private var settingsLock = NSLock()
    private var bufferEventSink: FlutterEventSink?
    private var errorEventSink: FlutterEventSink?
    private let audioInputEngine: AudioInputEngine = AudioInputEngine()
    private var isListening = false
    private var isSettingsErrorReported = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftFlutterVoiceProcessorPlugin()

        let methodChannel = FlutterMethodChannel(name: "flutter_voice_processor_methods", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(name: "flutter_voice_processor_events", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)

        let errorEventChannel = FlutterEventChannel(name: "flutter_voice_processor_error_events", binaryMessenger: registrar.messenger())
        errorEventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "start":
                if let args = call.arguments as? [String : Any] {
                    if let frameLength = args["frameLength"] as? Int,
                        let sampleRate = args["sampleRate"] as? Int {
                        self.start(frameLength: frameLength, sampleRate: sampleRate, result: result)
                    }
                    else {
                        result(FlutterError(code: "PV_INVALID_ARGUMENT", message: "Invalid argument provided to VoiceProcessor.start", details: nil))
                    }
                } else {
                    result(FlutterError(code: "PV_INVALID_ARGUMENT", message: "Invalid argument provided to VoiceProcessor.start", details: nil))
                }
            case "stop":
                self.stop()
                result(true)
            case "hasRecordAudioPermission":
                let hasRecordAudioPermission:Bool = self.checkRecordAudioPermission()
                result(hasRecordAudioPermission)
            default: result(FlutterMethodNotImplemented)

        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if let type = arguments as? String {
            if type == "buffer" {
                self.bufferEventSink = events

            }
            else if type == "error" {
                self.errorEventSink = events
            }
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let type = arguments as? String {
            if type == "buffer" {
                self.bufferEventSink = nil
            }
            else if type == "error" {
                self.errorEventSink = nil
            }
        }
        return nil
    }

    public func start(frameLength: Int, sampleRate: Int, result: @escaping FlutterResult) -> Void {

        guard !isListening else {
            NSLog("Audio engine already running.")
            result(true)
            return
        }

        audioInputEngine.audioInput = { [weak self] audio in

            guard let `self` = self else {
                return
            }

            let buffer = UnsafeBufferPointer(start: audio, count: frameLength);
            self.bufferEventSink?(Array(buffer))
        }

        do{

            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSession.Category.playAndRecord,
                options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            try audioInputEngine.start(frameLength:frameLength, sampleRate:sampleRate)
        }
        catch{
            NSLog("Unable to start audio engine: \(error)");
            result(FlutterError(code: "PV_AUDIO_RECORDER_ERROR", message: "Unable to start audio engine: \(error)", details: nil))
            return
        }

        settingsTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(monitorSettings),
            userInfo: nil,
            repeats: true)
        isSettingsErrorReported = false
        isListening = true
        result(true)
    }

    @objc func monitorSettings() {
        settingsLock.lock()

        if isListening && AVAudioSession.sharedInstance().category != AVAudioSession.Category.playAndRecord {
            if !isSettingsErrorReported {
                errorEventSink?("ERROR: Audio settings have been changed and Picovoice is no longer receiving microphone audio.")
                isSettingsErrorReported = true
            }
        }

        settingsLock.unlock()
    }

    private func stop() -> Void{
        guard isListening else {
            return
        }

        self.audioInputEngine.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        catch {
            errorEventSink?("Unable to stop audio engine: \(error)")
            return
        }

        settingsTimer?.invalidate()
        isSettingsErrorReported = false
        isListening = false
    }

    private func checkRecordAudioPermission() -> Bool{
        return AVAudioSession.sharedInstance().recordPermission != .denied
    }


    private class AudioInputEngine {

        private let numBuffers = 3
        private var audioQueue: AudioQueueRef?
        private var bufferRef: AudioQueueBufferRef?
        private var started = false

        var audioInput: ((UnsafePointer<Int16>) -> Void)?

        func start(frameLength:Int, sampleRate:Int) throws {
            if started {
                return
            }

            var format = AudioStreamBasicDescription(
                mSampleRate: Float64(sampleRate),
                mFormatID: kAudioFormatLinearPCM,
                mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
                mBytesPerPacket: 2,
                mFramesPerPacket: 1,
                mBytesPerFrame: 2,
                mChannelsPerFrame: 1,
                mBitsPerChannel: 16,
                mReserved: 0)
            let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            AudioQueueNewInput(&format, createAudioQueueCallback(), userData, nil, nil, 0, &audioQueue)

            guard let queue = audioQueue else {
                return
            }

            let bufferSize = UInt32(frameLength) * 2
            for _ in 0..<numBuffers {
                AudioQueueAllocateBuffer(queue, bufferSize, &bufferRef)
                if let buffer = bufferRef {
                    AudioQueueEnqueueBuffer(queue, buffer, 0, nil)
                }
            }

            AudioQueueStart(queue, nil)
            started = true
        }

        func stop() {
            guard self.started else {
                return
            }
            guard let audioQueue = audioQueue else {
                return
            }
            AudioQueueFlush(audioQueue)
            AudioQueueStop(audioQueue, true)
            AudioQueueDispose(audioQueue, true)
            audioInput = nil
            started = false
        }

        private func createAudioQueueCallback() -> AudioQueueInputCallback {
            return { userData, queue, bufferRef, startTimeRef, numPackets, packetDescriptions in

                // `self` is passed in as userData in the audio queue callback.
                guard let userData = userData else {
                    return
                }
                let `self` = Unmanaged<AudioInputEngine>.fromOpaque(userData).takeUnretainedValue()

                let pcm = bufferRef.pointee.mAudioData.assumingMemoryBound(to: Int16.self)

                if let audioInput = self.audioInput {
                    audioInput(pcm)
                }

                AudioQueueEnqueueBuffer(queue, bufferRef, 0, nil)
            }
        }

    }

}
