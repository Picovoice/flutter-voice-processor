//
// Copyright 2020-2024 Picovoice Inc.
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

import ios_voice_processor

public class SwiftFlutterVoiceProcessorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private let voiceProcessor = VoiceProcessor.instance

    private var settingsTimer: Timer?
    private var settingsLock = NSLock()
    private var frameEventSink: FlutterEventSink?
    private var errorEventSink: FlutterEventSink?
    private var isSettingsErrorReported = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftFlutterVoiceProcessorPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "flutter_voice_processor_methods",
            binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let frameEventChannel = FlutterEventChannel(
            name: "flutter_voice_processor_frame_events",
            binaryMessenger: registrar.messenger())
        frameEventChannel.setStreamHandler(instance)

        let errorEventChannel = FlutterEventChannel(
            name: "flutter_voice_processor_error_events",
            binaryMessenger: registrar.messenger())
        errorEventChannel.setStreamHandler(instance)
    }

    public override init() {
        super.init()
        voiceProcessor.addFrameListener(VoiceProcessorFrameListener({ frame in
            DispatchQueue.main.async {
                self.frameEventSink?(Array(frame))
            }
        }))

        voiceProcessor.addErrorListener(VoiceProcessorErrorListener({ error in
            DispatchQueue.main.async {
                self.errorEventSink?(error.errorDescription)
            }
        }))
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            guard let args = call.arguments as? [String: Any]
            else {
                result(FlutterError(
                    code: "PV_INVALID_ARGUMENT",
                    message: "Invalid argument provided to VoiceProcessor.start",
                    details: nil))
                return
            }
            guard let frameLength = args["frameLength"] as? UInt32, let sampleRate = args["sampleRate"] as? UInt32
            else {
                result(FlutterError(
                    code: "PV_INVALID_ARGUMENT",
                    message: "Invalid argument provided to VoiceProcessor.start",
                    details: nil))
                return
            }

            self.start(frameLength: frameLength, sampleRate: sampleRate, result: result)
        case "stop":
            self.stop(result: result)
        case "isRecording":
            result(self.voiceProcessor.isRecording)
        case "hasRecordAudioPermission":
            self.checkRecordAudioPermission(result: result)
        default: result(FlutterMethodNotImplemented)

        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if let type = arguments as? String {
            if type == "frame" {
                self.frameEventSink = events

            } else if type == "error" {
                self.errorEventSink = events
            }
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let type = arguments as? String {
            if type == "frame" {
                self.frameEventSink = nil
            } else if type == "error" {
                self.errorEventSink = nil
            }
        }
        return nil
    }

    public func start(frameLength: UInt32, sampleRate: UInt32, result: @escaping FlutterResult) {

        do {
            try voiceProcessor.start(frameLength: frameLength, sampleRate: sampleRate)
        } catch {
            result(FlutterError(
                code: "PV_AUDIO_RECORDER_ERROR",
                message: "Unable to start audio recording: \(error)",
                details: nil))
            return
        }

        settingsTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(monitorSettings),
            userInfo: nil,
            repeats: true)
        isSettingsErrorReported = false

        result(true)
    }

    @objc func monitorSettings() {
        settingsLock.lock()

        if voiceProcessor.isRecording &&
            AVAudioSession.sharedInstance().category != AVAudioSession.Category.playAndRecord {
            if !isSettingsErrorReported {
                errorEventSink?(
                    "Audio settings have been changed and Picovoice is no longer receiving microphone audio."
                )
                isSettingsErrorReported = true
            }
        }

        settingsLock.unlock()
    }

    private func stop(result: @escaping FlutterResult) {
        do {
            try voiceProcessor.stop()
        } catch {
            result(FlutterError(
                code: "PV_AUDIO_RECORDER_ERROR",
                message: "Unable to stop audio recording: \(error)",
                details: nil))
            return
        }
        settingsTimer?.invalidate()
        isSettingsErrorReported = false
        result(true)
    }

    private func checkRecordAudioPermission(result: @escaping FlutterResult) {
        if VoiceProcessor.hasRecordAudioPermission {
            result(true)
        } else {
            VoiceProcessor.requestRecordAudioPermission({ isGranted in
                result(isGranted)
            })
        }
    }
}
