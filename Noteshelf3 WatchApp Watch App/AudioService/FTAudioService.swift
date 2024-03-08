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

    var audioTimer:Timer!
    weak var delegate: FTAudioServiceDelegate?
    var audioDataProcessor: FTAudioDataProcessor!
    var isVisualizerActive: Bool = false //To stop/resume processing when app goes background/foregorund state
    var isRecording: Bool = false

    var audioActivity = FTAudioActivity()
    var audioRecorder: AVAudioRecorder!
    var audioEngine: AVAudioEngine!
    var playerNode: AVAudioPlayerNode!
    var audioFileBuffer: AVAudioPCMBuffer!
    var audioFile : AVAudioFile!

    override init() {
        super.init()
        //        self.audioDataProcessor = FTAudioDataProcessor.service(with: FTVisualizationSettings.histogramVisualizerSettings())
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
//            self.audioDataProcessor.engine = self.audioEngine
        }
        catch (let error){
            print (error.localizedDescription)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }

    //MARK:- Visualization
    func startVisualization(){
        self.startProcessingAudioData()
        self.isVisualizerActive = true
    }

    func stopVisualization(){
        self.isVisualizerActive = false
        self.stopProcessingAudioData()
    }

    private func startProcessingAudioData(){
        //        self.audioDataProcessor.startProcessingAudioData(self.isVisualizerActive)
    }

    private func stopProcessingAudioData(){
        //        self.audioDataProcessor.stopProcessingAudioData()
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
            self.startVisualization()
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
#if DEBUG
        debugPrint("self.audioActivity.currentTime:: \(self.audioActivity.currentTime)")
#endif
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
        self.stopVisualization()
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
    func playAudioWithURL(audioURL:URL) -> FTAudioActivity {
        self.audioFile = try? AVAudioFile.init(forReading: audioURL)
        weak var weakSelf = self

        let sampleRate = self.playerNode.outputFormat(forBus: 0).sampleRate
        let newsampletime = AVAudioFramePosition(sampleRate * max((recentPlayedAudio["currentTime"] as! Double)-1.0, 0.0))
        let framestoplay = self.audioFile.length - newsampletime
        self.audioActivity.currentTime = max((recentPlayedAudio["currentTime"] as! Double)-1.0, 0.0)

        self.playerNode.scheduleSegment(self.audioFile, startingFrame: newsampletime, frameCount: AVAudioFrameCount(framestoplay), at: nil, completionCallbackType: AVAudioPlayerNodeCompletionCallbackType.dataPlayedBack) { (completionType) in

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
                    weakSelf?.stopVisualization()
                    weakSelf?.delegate?.audioServiceDidFinishPlaying(withError: nil)
                }
            }
        }

        self.audioActivity.totalDuration = 0

        self.audioTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateAudioTimer), userInfo: nil, repeats: true)

        self.playerNode.play()
        self.playerNode.volume = self.playerVolume
        //WKInterfaceDevice.current().play(.click)

        self.audioActivity.audioServiceStatus = FTAudioServiceStatus.playing
        //        self.audioDataProcessor.engine = self.audioEngine
        //        self.audioDataProcessor.audioTapNode = self.playerNode
        //        self.startVisualization()

        return self.audioActivity
    }

    func stopPlayingAudio() {
        if self.playerNode.isPlaying{
            self.playerNode.stop()
        }
        DispatchQueue.main.async {
            if(self.audioTimer != nil && self.audioActivity.audioServiceStatus == FTAudioServiceStatus.playing){
                if self.audioTimer.isValid{
                    self.audioTimer.invalidate()
                    self.audioTimer = nil
                }

                self.audioActivity.audioServiceStatus = FTAudioServiceStatus.none
                self.stopVisualization()
                self.delegate?.audioServiceDidFinishPlaying(withError: nil)
            }
        }
    }

    func forwardAudio(bySeconds seconds: TimeInterval) {

    }

    func backwardAudio(bySeconds seconds: TimeInterval) {

    }
}
