//
//  FTAudioService.swift
//  Noteshelf3
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import WatchKit

private class FTAudioFileInfo: NSObject{
    var samplerRate: Double = 12000
    var fileLength: AVAudioFramePosition = AVAudioFramePosition(0);
    var currentFrame: AVAudioFramePosition?
    var duration: Double = 0.0
}

class FTAudioService: NSObject {
    var playerVolume: Float{
        set {
            UserDefaults.standard.setValue(newValue, forKey: "defaultVolume")
            UserDefaults.standard.synchronize()
        } get {
            return UserDefaults.standard.value(forKey: "defaultVolume") as! Float
        }
    }

    private var audioTimer:Timer!
    private var isRecording: Bool = false

    private var audioRecorder: AVAudioRecorder!
    private var audioEngine: AVAudioEngine!
    private var playerNode: AVAudioPlayerNode!
    private var audioFileBuffer: AVAudioPCMBuffer!
    private var audioFile : AVAudioFile!

    private var audioInfo = FTAudioFileInfo()
    private var audioActivity = FTAudioActivity()

    weak var delegate: FTAudioServiceDelegate?

    override init() {
        super.init()
        if(UserDefaults.standard.value(forKey: "defaultVolume") == nil){
            UserDefaults.standard.setValue(0.5, forKey: "defaultVolume")
            UserDefaults.standard.synchronize()
        }

        let sessionInstance = AVAudioSession.sharedInstance()
        do {
            try sessionInstance.setCategory(AVAudioSession.Category.playAndRecord,mode : .default)
            try sessionInstance.setActive(true)
        } catch let error as NSError{
            debugPrint(error)
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FTAudioService.handleInterruption(_:)),
                                               name: AVAudioSession.interruptionNotification,
                                               object: sessionInstance)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: WKExtension.applicationDidBecomeActiveNotification, object: nil)
        self.playerNode =  AVAudioPlayerNode()
        self.prepareEngine()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: WKExtension.applicationDidBecomeActiveNotification, object: nil)
    }

    @objc func applicationDidBecomeActive() {
        self.prepareEngine()
    }
}

private extension FTAudioService {
    func prepareEngine() {
        do {
            self.audioEngine = AVAudioEngine()
            self.audioEngine.attach(self.playerNode)
            self.audioEngine.connect(self.playerNode,
                                     to:self.audioEngine.mainMixerNode,
                                     format: AVAudioFormat(standardFormatWithSampleRate: 12000, channels: 1))
            self.audioEngine.prepare()
            try self.audioEngine.start()
        }
        catch (let error){
            print (error.localizedDescription)
        }
    }

    @objc func handleInterruption(_ notification: Notification) {
        let theInterruptionType = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
#if DEBUG
        NSLog("Session interrupted > --- %@ ---\n", theInterruptionType == AVAudioSession.InterruptionType.began.rawValue ? "Begin Interruption" : "End Interruption")
        NSLog("All userInfo: %@", notification.userInfo!)
#endif
        if(self.audioActivity.audioServiceStatus == .recording){
            self.delegate?.audioServiceDidInterrupted?(at: self.audioActivity.audioServiceStatus)
        }
        else if(self.audioActivity.audioServiceStatus == .playing){
            recentPlayedAudio["currentTime"] = Double(self.audioActivity.currentTime)
            self.stopPlayingAudio()
        }
    }

    @objc func updateAudioTimer() {
        if(self.audioActivity.audioServiceStatus == FTAudioServiceStatus.recording){
            self.audioActivity.currentTime = self.audioRecorder.currentTime
            self.audioActivity.totalDuration = 0
        }
        else if(self.audioActivity.audioServiceStatus == FTAudioServiceStatus.playing){
            self.audioActivity.currentTime = self.audioActivity.currentTime + 1.0
            if self.isAudioPlaybackCompleted() {
                self.handleAudioPlayCompletion()
            }
        }
    }

     func handleAudioPlayCompletion() {
        DispatchQueue.main.async {
            if self.audioTimer.isValid {
                self.audioTimer.invalidate()
                self.audioTimer = nil
            }
            if(audioServiceCurrentState != FTAudioServiceStatus.recording) {
                self.audioActivity.audioServiceStatus = FTAudioServiceStatus.none
                audioServiceCurrentState = FTAudioServiceStatus.none
            }
            self.delegate?.audioServiceDidFinishPlaying?(withError: nil)
        }
    }

    func currentTime() -> Double {
        guard self.playerNode.isPlaying else {
            return 0
        }
        if let lastRenderTime = self.playerNode.lastRenderTime,
           let playerTime = self.playerNode.playerTime(forNodeTime: lastRenderTime) {
            var currentTime = Double(playerTime.sampleTime) / playerTime.sampleRate
            if let currentFrame = self.audioInfo.currentFrame {
                let start = Double(currentFrame)/self.audioInfo.samplerRate
                currentTime += start
            }
            return floor(currentTime)
        }
        return 0
    }

    func isAudioPlaybackCompleted() -> Bool {
        let remainingTime = self.audioInfo.duration - self.audioActivity.currentTime
        let threshold: Double = 0.1
        return remainingTime <= threshold
    }
}

// MARK: AVAudioRecorderDelegate
extension FTAudioService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        self.finishRecording(success: true)
    }
}

// MARK: Recorder related
extension FTAudioService {
    func recordAudio(atURL audioURL:URL) -> FTAudioActivity {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC)
            , AVSampleRateKey: Int(12000)
        ]

        do {
            self.audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            self.audioRecorder.delegate = self
            self.audioRecorder.record()
            self.audioActivity.audioURL = audioURL
            self.audioActivity.audioServiceStatus = FTAudioServiceStatus.recording
            self.audioActivity.currentTime = 0
            self.audioActivity.totalDuration = 0
            self.audioTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateAudioTimer), userInfo: nil, repeats: true)
            return self.audioActivity
        }
        catch let error as NSError{
            let newError = NSError.init(domain: NSOSStatusErrorDomain, code: error.code, userInfo: nil)
#if DEBUG
            debugPrint(newError.description)
#endif
            finishRecording(success: false)
            return self.audioActivity
        }
    }

    func pauseOrContinueRecording() {
        if(self.audioRecorder != nil){
            if(self.audioRecorder.isRecording){
                self.audioRecorder.pause()
                self.audioActivity.audioServiceStatus = FTAudioServiceStatus.recordingPaused
            }
            else {
                self.audioRecorder.record()
                self.audioActivity.audioServiceStatus = FTAudioServiceStatus.recording
            }
        }
    }

    func stopRecording(){
        if(self.audioRecorder != nil){
            self.audioRecorder.stop()
            self.audioRecorder = nil

            if self.audioTimer.isValid{
                self.audioTimer.invalidate()
                self.audioTimer = nil
            }
        }
        else{
            self.finishRecording(success: false)
        }
    }

    func finishRecording(success: Bool) {
        self.audioActivity.audioServiceStatus = FTAudioServiceStatus.none
        if(success){
            self.delegate?.audioServiceDidFinishRecording?(withURL: self.audioActivity.audioURL!)
        }
    }
}

// MARK: - Player related
extension FTAudioService {
    func playAudioWithURL(audioURL:URL, at time: Double = 0.0) -> FTAudioActivity {
        self.audioFile = try? AVAudioFile.init(forReading: audioURL)
        self.audioInfo.samplerRate = self.audioFile.processingFormat.sampleRate
        self.audioInfo.fileLength = self.audioFile.length
        self.audioInfo.duration = floor(Double(self.audioInfo.fileLength)/self.audioInfo.samplerRate)
        
        let startFrame = AVAudioFramePosition(self.audioInfo.samplerRate * time)
        let framestoplay = self.audioInfo.fileLength - startFrame
        self.audioInfo.currentFrame = startFrame

        self.audioActivity.currentTime = time
        self.playerNode.scheduleSegment(self.audioFile,
                                        startingFrame: startFrame,
                                        frameCount: AVAudioFrameCount(framestoplay),
                                        at: nil,
                                        completionCallbackType: AVAudioPlayerNodeCompletionCallbackType.dataPlayedBack) { [weak self] (completionType) in
            guard let self else {
                return
            }
            if self.isAudioPlaybackCompleted() {
                self.handleAudioPlayCompletion()
            }
        }
        self.audioTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateAudioTimer), userInfo: nil, repeats: true)
        self.playerNode.play()
        self.playerNode.volume = self.playerVolume
        self.audioActivity.audioServiceStatus = FTAudioServiceStatus.playing
        return self.audioActivity
    }

    func seekAudio(by time: Double) {
        let sampleRate = self.audioInfo.samplerRate
        let currentTime = self.audioActivity.currentTime //self.currentTime()
        let timeToPlay = currentTime + time
        let framePosition = AVAudioFramePosition(timeToPlay * sampleRate)
        let songLengthSamples = audioFile.length
        let framesToPlay = songLengthSamples - framePosition
        self.playerNode.stop()

        self.audioInfo.currentFrame = framePosition
        self.playerNode.scheduleSegment(self.audioFile,
                                        startingFrame: framePosition,
                                        frameCount: AVAudioFrameCount(framesToPlay),
                                        at: nil,
                                        completionCallbackType: AVAudioPlayerNodeCompletionCallbackType.dataPlayedBack) { [weak self] (completionType) in
            guard let self else {
                return
            }
            if self.isAudioPlaybackCompleted() {
                self.handleAudioPlayCompletion()
            }
        }
        self.updateNodeVolume(self.playerVolume)
        self.playerNode.play()
        self.audioActivity.audioServiceStatus = FTAudioServiceStatus.playing
        self.audioActivity.currentTime = timeToPlay
    }

    func updateNodeVolume(_ volume: Float) {
        self.playerNode.volume = volume
        if volume != self.playerVolume {
            self.playerVolume = volume
        }
    }

    func pausePlayingAudio() {
        self.playerNode.pause()
        self.audioActivity.audioServiceStatus = .playingPaused
    }

    func resumePlayingAudio() {
        if self.audioActivity.audioServiceStatus == .playingPaused {
            self.playerNode.play()
            self.audioActivity.audioServiceStatus = .playing
        }
    }

    func stopPlayingAudio() {
        if self.playerNode.isPlaying{
            self.playerNode.stop()
        }
        DispatchQueue.main.async {
            if(self.audioTimer != nil && self.audioActivity.audioServiceStatus == .playing){
                if self.audioTimer.isValid{
                    self.audioTimer.invalidate()
                    self.audioTimer = nil
                }

                self.audioActivity.audioServiceStatus = .none
                self.delegate?.audioServiceDidFinishPlaying?(withError: nil)
            }
        }
    }
}
