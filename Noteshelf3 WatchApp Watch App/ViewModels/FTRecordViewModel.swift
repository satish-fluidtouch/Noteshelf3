//
//  FTRecordViewModel.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import AVFAudio
import WatchKit
import SwiftUI
import WidgetKit

class FTRecordViewModel: NSObject, ObservableObject {
    private let recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var audioService:FTAudioService?
    private var audioActivity: FTAudioActivity?
    private var isObserversAdded:Bool = false
    private var recordingDuration:Int = 0
    
    @Published var showPermissionAlert = false
    @Published var durationStr: String = "00:00"

    @Published var isRecording = false {
        didSet {
            FTWidgetDefaults.shared().isRecording = isRecording
        }
    }

    var showCustomAlert: Binding<Bool> {
        Binding<Bool>(
            get: {
                self.showPermissionAlert
            },
            set: { newValue in
                self.showPermissionAlert = newValue
            }
        )
    }

    override init() {
        super.init()
        FTWidgetDefaults.resetRecording()
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        do {
            try self.recordingSession.setCategory(AVAudioSession.Category.playAndRecord,mode : .default)
            try self.recordingSession.setActive(true)
        } catch let error as NSError{
            debugPrint(error)
        }
    }

    deinit {
        FTWidgetDefaults.resetRecording()
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    func handleRecordTapAction() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.recordingSession.requestRecordPermission() { [unowned self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.handleRecording()
                } else {
                    self.showPermissionAlert = true
                }
            }
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
            }
            else if(audioServiceCurrentState == FTAudioServiceStatus.recording){
            }
            else if(audioServiceCurrentState == FTAudioServiceStatus.recordingPaused){
            }
        }
    }
}

private extension FTRecordViewModel {
    func handleRecording() {
        if (self.audioService == nil) {
            self.audioService = FTAudioService()
            self.audioService!.delegate = self
        }

        if self.audioActivity == nil ||
            self.audioActivity?.audioServiceStatus == FTAudioServiceStatus.none {
            let newGUID = FTWatchRecordedAudio.getGUID()
            let tempRecordingURL = FTWatchRecordedAudio.temporaryRecordingURL(withGUID: newGUID)
            self.audioActivity = self.audioService?.recordAudio(atURL: tempRecordingURL)
            self.addObservers()
            self.isRecording = true
        } else if (self.audioActivity != nil &&
                   self.audioActivity?.audioServiceStatus == .recording) {
            self.audioService?.stopRecording()
            self.isRecording = false
            self.recordingDuration = 0
            self.durationStr = "00:00"
        }
    }

    func updateRecordingTime() {
        DispatchQueue.main.async {
            self.recordingDuration = Int(self.audioActivity!.currentTime)
            self.durationStr = FTWatchUtils.timeFormatted(totalSeconds: UInt(self.recordingDuration))
        }
    }

     func addObservers() {
        if(self.isObserversAdded == false) {
            self.audioActivity?.addObserver(self, forKeyPath: "audioServiceStatus", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil)
            self.audioActivity?.addObserver(self, forKeyPath: "currentTime", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil)
            self.audioActivity?.addObserver(self, forKeyPath: "totalDuration", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil)
            self.isObserversAdded = true
        }
    }

    func removeObservers() {
        if(self.isObserversAdded == true) {
            self.audioActivity?.removeObserver(self, forKeyPath: "audioServiceStatus")
            self.audioActivity?.removeObserver(self, forKeyPath: "currentTime")
            self.audioActivity?.removeObserver(self, forKeyPath: "totalDuration")
            self.isObserversAdded = false
        }
    }

    //MARK:- Watch Complication Event
    @objc func watchComplicationDidReceived() {
        if(audioServiceCurrentState != FTAudioServiceStatus.recording){
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.handleRecordTapAction()
            }
        }
    }
}

extension FTRecordViewModel: FTAudioServiceDelegate {
    func audioServiceDidFinishRecording(withURL audioURL: URL) {
        self.removeObservers()
        self.audioService = nil
        let GUID = FTWatchRecordedAudio.getGUID()
        let duration = WKAudioFileAsset(url: audioURL).duration
        if(duration < 2.0) {
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
    
    func audioServiceDidFinishPlaying(withError error: Error?) {
    }
}
