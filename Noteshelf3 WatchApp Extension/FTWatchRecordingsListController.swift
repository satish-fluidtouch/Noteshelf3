//
//  InterfaceController.swift
//  NS2Watch Extension
//
//  Created by Simhachalam on 29/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import WatchKit
import Foundation
import SpriteKit
import WatchConnectivity
class FTWatchRecordingsListController: WKInterfaceController,FTAudioServiceDelegate, FTRecentAudioCircleDelegate {

    var recordings: [FTWatchRecording] = []
    private var isDigitalCrownRotated:Bool{
        get{
            return UserDefaults.standard.bool(forKey: "hasLearntCrownRotation")
        }
        set{
            UserDefaults.standard.set(true, forKey: "hasLearntCrownRotation")
            UserDefaults.standard.synchronize()
        }
    }
    //UI
    @IBOutlet var playButton : WKInterfaceButton!
    @IBOutlet var playImageView : WKInterfaceImage!
    @IBOutlet var durationLabel : WKInterfaceLabel!
    @IBOutlet var dateLabel : WKInterfaceLabel!
    @IBOutlet var noMoreLabel : WKInterfaceLabel!
    
    @IBOutlet var infoLabel : WKInterfaceLabel!
    @IBOutlet var audioInfoGroup : WKInterfaceGroup!
    @IBOutlet var digitalCrownGroup : WKInterfaceGroup!
    
    @IBOutlet var crownTryItNowLabel : WKInterfaceLabel!
    @IBOutlet var crownUsageInfoLabel : WKInterfaceLabel!

    //SKScene
    @IBOutlet var recentRingInteface:WKInterfaceSCNScene?
    @IBOutlet var playerVisualizationInteface:WKInterfaceSCNScene?
    var currentAudioIndex:Int = 0
    var recentCircle:FTRecentAudioCircle!
    var playerVisualizer:FTPlayerVisualizer!

    // AudioKit Nodes
    var audioService:FTAudioService!
    var audioActivity: FTAudioActivity?
    var isObserversAdded:Bool = false
    var playbackCurrentTime:Int = 0
    
    //MARK:- LifeCycle

    deinit {

    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        self.playImageView.setImage(UIImage(named: "Play-Smaller"))
        NotificationCenter.default.addObserver(self, selector: #selector(didClickOnRecording(_:)), name: NSNotification.Name(rawValue: FTRecordingButtonDidClick), object: nil)
        self.crownTryItNowLabel.setText(NSLocalizedString("TryItNow", comment: "Try it Now!"));
        self.crownUsageInfoLabel.setText(NSLocalizedString("CrownUsageInfo", comment: "Use the digital..."));
        self.noMoreLabel.setText(NSLocalizedString("NoMoreRecordings", comment: "No more recordings"));
        
        //138, 204, 234
        self.recentCircle = FTRecentAudioCircle.init(withSceneSize: CGSize.init(width: screenWidth, height: screenWidth))
        self.recentCircle.circleDelegate = self
        self.recentRingInteface?.scene = SCNScene()
        self.recentRingInteface?.overlaySKScene = self.recentCircle
        
        self.playerVisualizer = FTPlayerVisualizer.init(withSceneSize: CGSize.init(width: screenWidth, height: screenWidth))
        self.playerVisualizationInteface?.scene = SCNScene()
        self.playerVisualizationInteface?.overlaySKScene = self.playerVisualizer
        self.playerVisualizationInteface?.setAlpha(0.0)

        reloadAudioFileContents(isToReset: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadContents(_:)), name: NSNotification.Name(FTRecordingCollectionUpdatedNotification), object: nil)

    }
    
    @objc func reloadContents(_ notification:Notification) {
        self.reloadAudioFileContents(isToReset: false)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.crownSequencer.delegate = self
        self.crownSequencer.focus()
        self.handleInfoMessageDisplay()        
        self.setTitle(NSLocalizedString("Recents", comment: "Recents"))
    }
    
    func handleInfoMessageDisplay(){
        self.clearAllMenuItems()
        if (self.recordings.count > 0){
            if(audioServiceCurrentState == FTAudioServiceStatus.none){
                self.audioInfoGroup.setHidden(false)
                self.infoLabel.setHidden(true)
                self.recentRingInteface?.setHidden(false)
                self.playerVisualizationInteface?.setHidden(false)
                
                if(self.recordings.count > 1 && self.isDigitalCrownRotated == false){
                    self.audioInfoGroup.setHidden(true)
                    self.digitalCrownGroup.setHidden(false)
                }
                else
                {
                    self.digitalCrownGroup.setHidden(true)
                }
                self.addMenuItem(with: WKMenuItemIcon.trash, title: NSLocalizedString("Delete", comment: "Delete"), action: #selector(FTWatchRecordingsListController.deleteButtonTapped))
                if #available(watchOSApplicationExtension 6.0, *) {
                    if WCSession.default.isCompanionAppInstalled {
                        self.addMenuItem(with: WKMenuItemIcon.share, title: NSLocalizedString("SendToPhone", comment: "Send To iPhone"), action: #selector(FTWatchRecordingsListController.sendButtonTapped))
                    }
                }
                else{
                    self.addMenuItem(with: WKMenuItemIcon.share, title: NSLocalizedString("SendToPhone", comment: "Send To iPhone"), action: #selector(FTWatchRecordingsListController.sendButtonTapped))
                }
            }
            else
            {
                self.audioInfoGroup.setHidden(false)
                self.infoLabel.setHidden(true)
                self.digitalCrownGroup.setHidden(true)
                self.recentRingInteface?.setHidden(false)
                self.playerVisualizationInteface?.setHidden(false)

                var infoString = NSLocalizedString("Recording", comment: "Recording...");
                switch(audioServiceCurrentState.rawValue) {
                case FTAudioServiceStatus.recording.rawValue:
                    fallthrough
                case FTAudioServiceStatus.recordingPaused.rawValue:
                    self.audioInfoGroup.setHidden(true)
                    self.recentRingInteface?.setHidden(true)
                    self.playerVisualizationInteface?.setHidden(true)
                    self.infoLabel.setHidden(false)
                case FTAudioServiceStatus.none.rawValue:
                    infoString = NSLocalizedString("NoRecordings", comment: "No recordings")
                case FTAudioServiceStatus.playing.rawValue:
                    infoString = "Playing..."
                default:
                    infoString = NSLocalizedString("NoRecordings", comment: "No recordings")
                }
                self.infoLabel.setText(infoString)
            }
        }
        else
        {
            self.audioInfoGroup.setHidden(true)
            self.digitalCrownGroup.setHidden(true)
            self.recentRingInteface?.setHidden(true)
            self.playerVisualizationInteface?.setHidden(true)
            self.infoLabel.setHidden(false)
            if(audioServiceCurrentState == FTAudioServiceStatus.recording){
                self.infoLabel.setText(NSLocalizedString("Recording", comment: "Recording..."))
            }
            else
            {
                self.infoLabel.setText(NSLocalizedString("NoRecordings", comment: "No recordings"))
            }
        }
    }
    func reloadAudioFileContents(isToReset:Bool) {
        weak var weakSelf = self

        FTWatchRecordingProvider.shared.allRecordings({ (allRecordings) in
            weakSelf?.recordings = allRecordings
            self.recentCircle.refreshNodesWithCount((weakSelf?.recordings.count)!)
            if (allRecordings.count > 0){
                #if DEBUG
                debugPrint("New record added: \(allRecordings[0].duration)");
                #endif
                
                if(isToReset == false){
                    self.currentAudioIndex = min(self.currentAudioIndex, self.recordings.count-1)
                    self.recentCircle.setSelectedIndex(self.currentAudioIndex)
                    
                    self.durationLabel.setText(self.recordings[self.currentAudioIndex].duration.formatSecondsToString())
                    self.dateLabel.setText(self.recordings[self.currentAudioIndex].audioTitle)
                }
                else
                {
                    self.durationLabel.setText(allRecordings[0].duration.formatSecondsToString())
                    self.dateLabel.setText(allRecordings[0].audioTitle)
                }
            }
            weakSelf?.handleInfoMessageDisplay()
        })
    }

    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    //MARK:- Action Methods
    @IBAction func playButtonClicked(_ sender:WKInterfaceButton){
        if(
            self.recordings.isEmpty
            || audioServiceCurrentState == .recording
            || (self.recordings.count > 1 && self.isDigitalCrownRotated == false)
            ) {
            return
        }
        
        if(self.audioService == nil){
            self.audioService = FTAudioService()
            self.audioService.delegate = self
        }

        if self.audioActivity == nil || self.audioActivity?.audioServiceStatus == FTAudioServiceStatus.none
        {
            self.animate(withDuration: 0.3, animations: {
                self.audioInfoGroup.setAlpha(0.0)
                self.recentRingInteface?.setAlpha(0.0)
                self.playerVisualizationInteface?.setAlpha(1.0)
            })
            
            self.audioActivity = self.audioService.playAudioWithURL(audioURL: self.recordings[self.recentCircle.currentIndex].filePath!, withVisualizer:self.playerVisualizer)

            if(recentPlayedAudio["GUID"] as! String != self.recordings[self.recentCircle.currentIndex].GUID){
                recentPlayedAudio["currentTime"] = 0.0
                recentPlayedAudio["GUID"] = self.recordings[self.recentCircle.currentIndex].GUID
            }
            self.playerVisualizer.startAudioProgress(withDuration: self.recordings[self.recentCircle.currentIndex].duration)
            recentPlayedAudio["currentTime"] = 0.0
            
            self.addObservers()
        }
        else if( self.audioActivity != nil && self.audioActivity?.audioServiceStatus == .playing)
        {
            self.audioService.stopPlayingAudio()
        }
    }
    @IBAction func deleteButtonTapped() {
        weak var weakSelf = self

        let deletedGUID =  self.recordings[self.currentAudioIndex].GUID
        let yesAction:WKAlertAction = WKAlertAction.init(title: NSLocalizedString("Delete", comment: "Delete"),
                                                         style: WKAlertActionStyle.destructive) {
            FTWatchRecordingProvider.shared.deleteRecording(item: (weakSelf?.recordings[weakSelf!.currentAudioIndex])!, onCompletion: { (error) in
                if(error == nil){
                    var deletedGUIDs:[String] = UserDefaults.standard.value(forKey: FTDeletedGUIDDefaultsKey) as! [String]
                    deletedGUIDs.insert(deletedGUID, at: 0)
                    UserDefaults.standard.setValue(deletedGUIDs, forKey: FTDeletedGUIDDefaultsKey)
                    UserDefaults.standard.synchronize()
                    weakSelf?.reloadAudioFileContents(isToReset: false)
                }
            })
        }
        let noAction:WKAlertAction = WKAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: WKAlertActionStyle.default) {
        }
        
        self.presentAlert(withTitle: "", message: NSLocalizedString("DeleteRecording", comment: "Delete this recording?"), preferredStyle: WKAlertControllerStyle.sideBySideButtonsAlert, actions: [yesAction, noAction])
    }
    @IBAction func sendButtonTapped() {
        let recording = self.recordings[self.currentAudioIndex]
        recording.syncStatus = FTWatchSyncStatus.notSynced
        FTWatchRecordingProvider.shared.updateRecording(item: recording) { (error) in
            FTWatchCommunicationManager.shared.wakeUpAudioPublisherIfNeeded()
        }
    }

    //MARK:- Observers
    fileprivate func addObservers()
    {
        if(self.isObserversAdded == false){
            self.clearAllMenuItems()
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
    }
    
    func updateRecordingTime(){
        self.playbackCurrentTime = Int(self.audioActivity!.currentTime)
        let seconds:Int = self.playbackCurrentTime % 60;
        let minutes:Int = (self.playbackCurrentTime / 60) % 60;
        let hours:Int = (self.playbackCurrentTime / 3600) % 60;
        
        if(hours > 0){
            self.setTitle(String.init(format: "%0.2ld:%0.2ld:%0.2ld",hours, minutes, seconds))
        }
        else
        {
            self.setTitle(String.init(format: "%0.2ld:%0.2ld",minutes, seconds))
        }
    }
    //MARK:- FTAudioServiceDelegate
    func audioServiceDidFinishRecording(withURL audioURL: URL) {
        
    }
    func audioServiceDidFinishPlaying(withError error:Error?) {
        self.audioService = nil
        self.audioActivity = nil
        
        self.setTitle(NSLocalizedString("Recents", comment: "Recents"))
        #if DEBUG
        debugPrint("audioServiceDidFinishPlaying")
        #endif
        
        self.removeObservers()
        self.recentCircle.refreshNodesWithCount(self.recordings.count)
        self.animate(withDuration: 0.3, animations: {
            self.recentRingInteface?.setAlpha(1.0)
            self.playerVisualizationInteface?.setAlpha(0.0)
            self.audioInfoGroup.setAlpha(1.0)
        })
        
        self.currentAudioIndex = min(self.currentAudioIndex, self.recordings.count-1)
        self.recentCircle.setSelectedIndex(self.currentAudioIndex)
        
        self.durationLabel.setText(self.recordings[self.currentAudioIndex].duration.formatSecondsToString())
        self.dateLabel.setText(self.recordings[self.currentAudioIndex].audioTitle)
        
        self.handleInfoMessageDisplay()
    }
    //MARK:- FTRecentAudioCircleDelegate
    func recentAudioCircleDidChange(withIndex audioIndex: Int) {
        self.currentAudioIndex = min(audioIndex, self.recordings.count-1)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(FTWatchRecordingsListController.handleCrownIdleState), object: nil)
        self.handleCrownIdleState()
        
        if(self.isDigitalCrownRotated == false){
            self.isDigitalCrownRotated = true
            
            self.audioInfoGroup.setHidden(false)
            self.audioInfoGroup.setAlpha(0.0)
            self.animate(withDuration: 1.0, animations: {
                self.digitalCrownGroup.setAlpha(0.0)
                self.audioInfoGroup.setAlpha(1.0)
                self.handleInfoMessageDisplay()
            })
        }
        self.durationLabel.setText(self.recordings[audioIndex].duration.formatSecondsToString())
        self.dateLabel.setText(self.recordings[audioIndex].audioTitle)
    }
    func recentAudioCircleDidCrossMinLimit() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(FTWatchRecordingsListController.handleCrownIdleState), object: nil)
        self.handleCrownIdleState()
    }
    func recentAudioCircleDidCrossMaxLimit() {
        self.animate(withDuration: 0.6) {
            self.noMoreLabel.setAlpha(1.0)
        }
        self.animate(withDuration: 0.3) {
            self.durationLabel.setAlpha(0.0)
            self.dateLabel.setAlpha(0.0)
            self.playImageView.setAlpha(0.0)
        }
    }
    @objc func didClickOnRecording(_ notification:Notification){
        if(audioServiceCurrentState == FTAudioServiceStatus.playing){
            self.audioService.stopPlayingAudio()
        }
    }
    @IBAction func handleLongpress(){
        //For simulator delete recording
    }
}
extension FTWatchRecordingsListController: WKCrownDelegate{
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        if(audioServiceCurrentState == .playing){
            NSObject.cancelPreviousPerformRequests(withTarget: self.audioService, selector: #selector(FTAudioService.didCrownBecomeIdle), object: nil)
            self.audioService?.didChangeCrownDelta(rotationalDelta)
        }
        else
        {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(FTWatchRecordingsListController.handleCrownIdleState), object: nil)
            self.recentCircle.didChangeCrownDelta(rotationalDelta)
        }
    }
    func crownDidBecomeIdle(_ crownSequencer: WKCrownSequencer?) {
        #if DEBUG
        debugPrint("Idle")
        #endif
        if(audioServiceCurrentState == .playing){
            if(self.audioService != nil){
                NSObject.cancelPreviousPerformRequests(withTarget: self.audioService, selector: #selector(FTAudioService.didCrownBecomeIdle), object: nil)
                self.audioService.perform(#selector(FTAudioService.didCrownBecomeIdle), with: nil, afterDelay: 1.0)
            }
        }
        else
        {
            self.recentCircle.didCrownBecomeIdle()

            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(FTWatchRecordingsListController.handleCrownIdleState), object: nil)
            self.perform(#selector(FTWatchRecordingsListController.handleCrownIdleState), with: nil, afterDelay: 1.0)
        }
    }
    @objc func handleCrownIdleState(){
        self.animate(withDuration: 0.3) {
            self.noMoreLabel.setAlpha(0.0)
        }
        self.animate(withDuration: 0.6) {
            self.durationLabel.setAlpha(1.0)
            self.dateLabel.setAlpha(1.0)
            self.playImageView.setAlpha(1.0)
        }
    }
}
