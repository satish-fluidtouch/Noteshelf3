//
//  FTWatchRecordNewController.swift
//  NS2Watch Extension
//
//  Created by Simhachalam on 29/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import WatchKit
import AVFoundation
import SpriteKit
import SceneKit

class FTWatchRecordNewController: WKInterfaceController, AVAudioRecorderDelegate, FTAudioServiceDelegate {
    
    let MAX_AUDIO_DURATION = 3599
    let ANIMAMATION_DURATION = 0.5
    var recordingSession: AVAudioSession!
    var recordingDuration:Int = 0

    @IBOutlet var pausedLabel : WKInterfaceLabel!
    @IBOutlet var pauseGroup : WKInterfaceGroup!
    
    @IBOutlet var recordButton : WKInterfaceButton!
    @IBOutlet var recordImageView : WKInterfaceImage!
    @IBOutlet var stopRecordImageView : WKInterfaceImage!
    
    //SKScene
    @IBOutlet var skInterface:WKInterfaceSCNScene?
    var audioVisualizer:FTCircularVisualizer!
    // AudioKit Nodes
    var audioService:FTAudioService?
    var audioActivity: FTAudioActivity?
    var isObserversAdded:Bool = false

    //MARK:- Life Cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        NotificationCenter.default.addObserver(self, selector: #selector(watchComplicationDidReceived), name: NSNotification.Name(rawValue: DID_WATCH_COMPLICATION_RECEIVED), object: nil)

        self.setTitle(NSLocalizedString("Record", comment: "Record"))
        self.recordImageView.setImage(UIImage(named: "record"))
        self.stopRecordImageView.setImage(UIImage(named: "stop"))

        self.pausedLabel.setText(NSLocalizedString("Paused", comment: "Paused"))
        self.pauseGroup.setAlpha(0.0)

        self.audioVisualizer = FTCircularVisualizer.init(withSceneSize: CGSize.init(width: screenWidth, height: screenWidth))
        self.skInterface?.scene = SCNScene()
        self.skInterface?.overlaySKScene = self.audioVisualizer            
        
        self.recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try self.recordingSession.setCategory(AVAudioSession.Category.playAndRecord,mode : .default);
            try self.recordingSession.setActive(true)
            self.recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if allowed {

                    } else {
                        // failed to record!
                    }
                }
            }
        } catch let error as NSError{
            debugPrint(error)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    //MARK:- Action Methods
    @IBAction func handleSwipeDown(_ gesture:WKSwipeGestureRecognizer){
        self.audioService?.pauseOrContinueRecording()
    }
    @IBAction func recordButtonClicked(_ sender:WKInterfaceButton){
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.recordingSession.requestRecordPermission() { [unowned self] allowed in
            DispatchQueue.main.async {
                if allowed
                {
                    if (self.audioService == nil){
                        self.audioService = FTAudioService()
                        self.audioService!.delegate = self
                        NotificationCenter.default.post(Notification.init(name: Notification.Name(rawValue: FTRecordingButtonDidClick)))
                    }
                    if self.audioActivity == nil || self.audioActivity?.audioServiceStatus == FTAudioServiceStatus.none
                    {
                        self.animate(withDuration: 0.2, animations: {
                            self.recordImageView.setAlpha(0.0)
                            self.recordImageView.setWidth(30.0)
                            self.recordImageView.setHeight(30.0)
                            self.stopRecordImageView.setAlpha(1.0)
                        })
                        
                        let newGUID = FTWatchRecordedAudio.getGUID()
                        let tempRecordingURL = FTWatchRecordedAudio.temporaryRecordingURL(withGUID: newGUID)
                        self.audioActivity = self.audioService?.recordAudio(atURL: tempRecordingURL, withVisualizer: self.audioVisualizer)
                        
                        self.addObservers()
                    }
                    else if( self.audioActivity != nil && self.audioActivity?.audioServiceStatus == .recording)
                    {
                        self.audioService?.stopRecording()
                    }
                    else if(self.audioActivity?.audioServiceStatus == .recordingPaused)
                    {
                        self.audioService?.pauseOrContinueRecording()
                    }
                }
                else
                {
                    let okAction:WKAlertAction = WKAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: WKAlertActionStyle.default) {
                        
                    }
                    
                    self.presentAlert(withTitle: "",
                                      message:NSLocalizedString("MicrophoneAccessInfo", comment: "Allow microphone access...") ,
                                      preferredStyle: WKAlertControllerStyle.alert,
                                      actions: [okAction])
                }
            }
        }
    }
    //MARK:- Observers
    fileprivate func addObservers()
    {
        if(self.isObserversAdded == false){
            self.audioActivity?.addObserver(self, forKeyPath: "audioServiceStatus", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil);
            self.audioActivity?.addObserver(self, forKeyPath: "currentTime", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil);
            self.audioActivity?.addObserver(self, forKeyPath: "totalDuration", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil);
            
            self.isObserversAdded = true
        }
    }
    fileprivate func removeObservers()
    {
        if(self.isObserversAdded == true){
            self.audioActivity?.removeObserver(self, forKeyPath: "audioServiceStatus");
            self.audioActivity?.removeObserver(self, forKeyPath: "currentTime");
            self.audioActivity?.removeObserver(self, forKeyPath: "totalDuration");
            
            self.isObserversAdded = false
        }
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if(keyPath == "currentTime"){
            self.updateRecordingTime()
        }
        else if(keyPath == "totalDuration"){

        }
        else if(keyPath == "audioServiceStatus"){
            if(audioServiceCurrentState == FTAudioServiceStatus.none){
                self.animate(withDuration: 0.2, animations: {
                    self.pauseGroup.setAlpha(0.0)
                    self.recordImageView.setAlpha(1.0)
                    self.stopRecordImageView.setAlpha(0.0)
                })
            }
            else if(audioServiceCurrentState == FTAudioServiceStatus.recording){
                self.animate(withDuration: 0.2, animations: {
                    self.pauseGroup.setAlpha(0.0)
                    self.recordImageView.setAlpha(0.0)
                    self.stopRecordImageView.setAlpha(1.0)
                })
            }
            else if(audioServiceCurrentState == FTAudioServiceStatus.recordingPaused){
                self.animate(withDuration: 0.2, animations: {
                    self.pauseGroup.setAlpha(1.0)
                    self.recordImageView.setAlpha(0.0)
                    self.stopRecordImageView.setAlpha(0.0)
                })
            }
        }
    }

    func updateRecordingTime(){
        self.recordingDuration = Int(self.audioActivity!.currentTime)
        let seconds:Int = self.recordingDuration % 60;
        let minutes:Int = (self.recordingDuration / 60) % 60;
        let hours:Int = (self.recordingDuration / 3600) % 60;
        var durationTitle: String = ""
        if(hours > 0){
            durationTitle = String.init(format: "%0.2ld:%0.2ld:%0.2ld",hours, minutes, seconds)
        }
        else
        {
            durationTitle = String.init(format: "%0.2ld:%0.2ld",minutes, seconds)
        }
        DispatchQueue.main.async {
            self.setTitle(durationTitle)
        }
    }
    //MARK:- FTAudioServiceDelegate 
    func audioServiceDidFinishRecording(withURL audioURL: URL) {
        self.setTitle(NSLocalizedString("Record", comment: "Record"))
        self.animate(withDuration: 0.2, animations: {
            self.recordImageView.setAlpha(1.0)
            self.recordImageView.setWidth(40.0)
            self.recordImageView.setHeight(40.0)
            self.stopRecordImageView.setAlpha(0.0)
        })

        self.removeObservers()
        self.audioService = nil
        
        let GUID = FTWatchRecordedAudio.getGUID()
        let duration = WKAudioFileAsset.init(url: audioURL).duration
        if(duration < 2.0){
            return
        }
        let newRecording: FTWatchRecordedAudio = FTWatchRecordedAudio.init(GUID: GUID, date: Date(), duration: duration)
        newRecording.filePath = audioURL
        FTWatchRecordingProvider.shared.addRecording(tempRecord: newRecording, onCompletion: { (newRecording, error) in
            if(error == nil){
                //TODO:: Handle Error
                FTWatchCommunicationManager.shared.wakeUpAudioPublisherIfNeeded()
            }
        })
    }
    
    func audioServiceDidFinishPlaying(withError error:Error?) {
    
    }
    //MARK:- Watch Complication Event
    @objc func watchComplicationDidReceived() {
        if(audioServiceCurrentState != FTAudioServiceStatus.recording){
            self.becomeCurrentPage()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.recordButtonClicked(self.recordButton)
            }
        }
    }
}
