import Flutter
import UIKit
import AVFoundation

public class SwiftFlutterVoiceProcessorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var bufferEventSink: FlutterEventSink?
    private let audioInputEngine: AudioInputEngine = AudioInputEngine()        
    private var isListening = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftFlutterVoiceProcessorPlugin()
        
        let methodChannel = FlutterMethodChannel(name: "flutter_voice_processor_methods", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        
        let eventChannel = FlutterEventChannel(name: "flutter_voice_processor_events", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            let args = call.arguments as! [String : Any]
            let frameLength:Int = args["frameLength"] as! Int
            let sampleRate:Int = args["sampleRate"] as! Int
            let didStart:Bool = self.start(frameLength: frameLength, sampleRate: sampleRate)
            result(didStart)
        case "stop":
            let didStop:Bool = self.stop()
            result(didStop)
        case "hasRecordAudioPermission":
            let hasRecordAudioPermission:Bool = self.checkRecordAudioPermission()
            result(hasRecordAudioPermission)
        default: result(FlutterMethodNotImplemented)
            
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.bufferEventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {        
        self.bufferEventSink = nil
        return nil
    }
    
    public func start(frameLength: Int, sampleRate: Int) -> Bool {
        
        guard !isListening else {
            NSLog("Audio engine already running.")
            return true
        }
        
        audioInputEngine.audioInput = { [weak self] audio in
            
            guard let `self` = self else {
                return
            }
            
            let buffer = UnsafeBufferPointer(start: audio, count: frameLength);            
            self.bufferEventSink?(Array(buffer)) 
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission == .denied {
            NSLog("Recording permission denied")
            return false
        }
        
        do{
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            try audioInputEngine.start(frameLength:frameLength, sampleRate:sampleRate)
        }
        catch{
            NSLog("Unable to start audio engine");
            return false;
        }
        
        isListening = true
        return true
    }
    
    private func stop() -> Bool{
        guard isListening else {
            return true
        }
        
        self.audioInputEngine.stop()
        
        isListening = false
        return true
    }
    
    private func checkRecordAudioPermission() -> Bool{
        return AVAudioSession.sharedInstance().recordPermission != .denied
    }
    
    
    private class AudioInputEngine {
        private let numBuffers = 3
        private var audioQueue: AudioQueueRef?
        
        var audioInput: ((UnsafePointer<Int16>) -> Void)?
        
        func start(frameLength:Int, sampleRate:Int) throws {
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
                var bufferRef: AudioQueueBufferRef? = nil
                AudioQueueAllocateBuffer(queue, bufferSize, &bufferRef)
                if let buffer = bufferRef {
                    AudioQueueEnqueueBuffer(queue, buffer, 0, nil)
                }
            }
            
            AudioQueueStart(queue, nil)
        }
        
        func stop() {
            guard let audioQueue = audioQueue else {
                return
            }
            AudioQueueStop(audioQueue, true)
            AudioQueueDispose(audioQueue, false)
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
