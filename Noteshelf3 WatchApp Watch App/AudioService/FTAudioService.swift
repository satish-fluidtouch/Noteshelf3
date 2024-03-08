//
//  FTAudioService.swift
//  Noteshelf3
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import WatchKit

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
    private var audioActivity = FTAudioActivity()

    private var audioRecorder: AVAudioRecorder!
    private var audioEngine: AVAudioEngine!
    private var playerNode: AVAudioPlayerNode!
    private var audioFileBuffer: AVAudioPCMBuffer!
    private var audioFile : AVAudioFile!

    weak var delegate: FTAudioServiceDelegate?

    override init() {
        super.init()
        if(UserDefaults.standard.value(forKey: "defaultVolume") == nil){
            UserDefaults.standard.setValue(0.5, forKey: "defaultVolume")
            UserDefaults.standard.synchronize()
        }

        let sessionInstance = AVAudioSession.sharedInstance()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FTAudioService.handleInterruption(_:)),
                                               name: AVAudioSession.interruptionNotification,
                                               object: sessionInstance)

        self.audioEngine = AVAudioEngine.init()
        do
        {
            self.playerNode =  AVAudioPlayerNode()
            self.audioEngine.attach(self.playerNode)
            self.audioEngine.connect(self.playerNode, to:self.audioEngine.mainMixerNode, format: AVAudioFormat.init(standardFormatWithSampleRate: 12000, channels: 1))
            self.audioEngine.prepare()
            try self.audioEngine.start()
        }
        catch (let error){
            print (error.localizedDescription)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }
}

extension FTAudioService: AVAudioRecorderDelegate{
    //MARK:- AudioRecording
    @objc internal func handleInterruption(_ notification: Notification) {
        let theInterruptionType = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
#if DEBUG
        NSLog("Session interrupted > --- %@ ---\n", theInterruptionType == AVAudioSession.InterruptionType.began.rawValue ? "Begin Interruption" : "End Interruption")
        NSLog("All userInfo: %@", notification.userInfo!)
#endif
        if(self.audioActivity.audioServiceStatus == .recording){
            self.stopRecording()
        }
        else if(self.audioActivity.audioServiceStatus == .playing){
            recentPlayedAudio["currentTime"] = Double(self.audioActivity.currentTime)
            self.stopPlayingAudio()
        }
    }

    func recordAudio(atURL audioURL:URL) -> FTAudioActivity {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC)]

        do {
            self.audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            self.audioRecorder.delegate = self
            self.audioRecorder.record()
            self.audioActivity.audioURL = audioURL
            self.audioActivity.audioServiceStatus = FTAudioServiceStatus.recording
            self.audioActivity.currentTime = 0
            self.audioActivity.totalDuration = 0
            WKInterfaceDevice.current().play(.click)

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

    @objc func updateAudioTimer(){
        if(self.audioActivity.audioServiceStatus == FTAudioServiceStatus.recording){
            self.audioActivity.currentTime = self.audioRecorder.currentTime
            self.audioActivity.totalDuration = 0
        }
        else if(self.audioActivity.audioServiceStatus == FTAudioServiceStatus.playing){
            self.audioActivity.currentTime = self.audioActivity.currentTime + 1.0
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
        WKInterfaceDevice.current().play(.click)
        if(success){
            self.delegate?.audioServiceDidFinishRecording(withURL: self.audioActivity.audioURL!)
        }
    }

    //MARK:- AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            self.finishRecording(success: true)
        } else {
            self.finishRecording(success: true)// Just to save recording
        }
    }
}

extension FTAudioService{
    //MARK:- AudioPlaying
    func playAudioWithURL(audioURL:URL, at time: Double = 0.0) -> FTAudioActivity {
        self.audioFile = try? AVAudioFile.init(forReading: audioURL)
        weak var weakSelf = self

        let sampleRate = self.playerNode.outputFormat(forBus: 0).sampleRate
        let newsampletime = AVAudioFramePosition(sampleRate * max((recentPlayedAudio["currentTime"] as! Double)-1.0, time))
        let framestoplay = self.audioFile.length - newsampletime
        self.audioActivity.currentTime = max((recentPlayedAudio["currentTime"] as! Double)-1.0, time)

        self.playerNode.scheduleSegment(self.audioFile, startingFrame: newsampletime, frameCount: AVAudioFrameCount(framestoplay), at: nil, completionCallbackType: AVAudioPlayerNodeCompletionCallbackType.dataPlayedBack) { (completionType) in
            print("zzzz - completion type: \(completionType)")
            DispatchQueue.main.async {
                if(weakSelf?.audioActivity.audioServiceStatus == FTAudioServiceStatus.playing){

                    if self.audioTimer.isValid{
                        self.audioTimer.invalidate()
                        self.audioTimer = nil
                    }
                    if(audioServiceCurrentState != FTAudioServiceStatus.recording){
                        weakSelf?.audioActivity.audioServiceStatus = FTAudioServiceStatus.none
                        audioServiceCurrentState = FTAudioServiceStatus.none
                    }
                    weakSelf?.delegate?.audioServiceDidFinishPlaying(withError: nil)
                }
            }
        }

        self.audioActivity.totalDuration = 0
        self.audioTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateAudioTimer), userInfo: nil, repeats: true)
        self.playerNode.play()
        self.playerNode.volume = self.playerVolume
        self.audioActivity.audioServiceStatus = FTAudioServiceStatus.playing
        return self.audioActivity
    }

    func pausePlayingAudio() {
        if self.playerNode.isPlaying {
            self.playerNode.pause()
            self.audioActivity.audioServiceStatus = .playingPaused
        }
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
                self.delegate?.audioServiceDidFinishPlaying(withError: nil)
            }
        }
    }
}
