//
//  FTPlayerViewModel.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 08/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPlayerViewModel: NSObject, ObservableObject {
    let recording: FTWatchRecording

    private var audioService:FTAudioService!
    private var audioActivity: FTAudioActivity?
    private var isObserversAdded: Bool = false
    private var playbackCurrentTime: Int = 0

    @Published var playDurationStr: String = "00:00"
    @Published var isPlaying: Bool = false
    @Published var progress: CGFloat = 0.0

    init(recording: FTWatchRecording) {
        self.recording = recording
        self.playDurationStr = self.recording.duration.formatSecondsToString()
    }

    func handlePlayTapAction() {
        guard let path = recording.filePath else {
            return
        }
        self.createAudioServiceIfNeeded()
        self.isPlaying.toggle()
        if self.audioActivity == nil || self.audioActivity?.audioServiceStatus == FTAudioServiceStatus.none {
            self.audioActivity = self.audioService.playAudioWithURL(audioURL: path, at: 0.0)
            self.addObservers()
        } else {
            guard let activity = self.audioActivity else {
                return
            }
            if activity.audioServiceStatus == .playing {
                self.audioService.pausePlayingAudio()
            } else {
                self.audioService.resumePlayingAudio()
            }
        }
    }

    func forwardPlayBy(_ seconds: Double) {
        guard let path = recording.filePath, Double(self.playbackCurrentTime) + seconds < recording.duration else {
            return
        }
        self.createAudioServiceIfNeeded()
        // If audio is not played
        if self.audioActivity == nil ||
            self.audioActivity?.audioServiceStatus == FTAudioServiceStatus.none {
            self.audioActivity = self.audioService.playAudioWithURL(audioURL: path, at: seconds)
            self.isPlaying = true
            self.addObservers()
        } else if let activity = self.audioActivity,
                  activity.audioServiceStatus == .playing || activity.audioServiceStatus == .playingPaused {
            self.audioService?.seekAudio(by: 15)
            self.isPlaying = true
        }
    }

    func backwardPlayBy(_ seconds: Double) {
        guard Double(self.playbackCurrentTime) - seconds > 0.0 else {
            return
        }
        self.createAudioServiceIfNeeded()
        if let activity = self.audioActivity,
           activity.audioServiceStatus == .playing || activity.audioServiceStatus == .playingPaused {
            self.audioService?.seekAudio(by: -15)
            self.isPlaying = true
        }
    }

    func resetPlay() {
        self.audioService?.stopPlayingAudio()
        self.removeObservers()
        self.playDurationStr = "00:00"
        self.isPlaying = false
        self.progress = 0.0
        self.playbackCurrentTime = 0
        self.audioService = nil
        self.audioActivity = nil
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if(keyPath == "currentTime") {
            self.updatePlayTime()
        }
    }
}

private extension FTPlayerViewModel {
    func createAudioServiceIfNeeded() {
        if(self.audioService == nil) {
            self.audioService = FTAudioService()
            self.audioService.delegate = self
        }
    }

    func addObservers() {
        if(self.isObserversAdded == false) {
            self.audioActivity?.addObserver(self, forKeyPath: "audioServiceStatus", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil);
            self.audioActivity?.addObserver(self, forKeyPath: "currentTime", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil);
            self.audioActivity?.addObserver(self, forKeyPath: "totalDuration", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil);
            self.isObserversAdded = true
        }
    }

    func removeObservers() {
        if(self.isObserversAdded == true) {
            self.audioActivity?.removeObserver(self, forKeyPath: "audioServiceStatus");
            self.audioActivity?.removeObserver(self, forKeyPath: "currentTime");
            self.audioActivity?.removeObserver(self, forKeyPath: "totalDuration");
            self.isObserversAdded = false
        }
    }

    func updatePlayTime() {
        if let activity = self.audioActivity, Double(self.playbackCurrentTime) < recording.duration {
            self.playbackCurrentTime = Int(activity.currentTime)
            self.playDurationStr = FTWatchUtils.timeFormatted(totalSeconds: UInt(self.playbackCurrentTime))
            self.progress = CGFloat(Double(self.playbackCurrentTime)/self.recording.duration)
        }
    }
}

extension FTPlayerViewModel: FTAudioServiceDelegate {
    func audioServiceDidFinishRecording(withURL audioURL: URL) {
    }
    
    func audioServiceDidFinishPlaying(withError error: Error?) {
        self.audioService = nil
        self.audioActivity = nil
        self.removeObservers()
        self.playDurationStr = self.recording.duration.formatSecondsToString()
        self.isPlaying = false
        self.progress = 0.0
        self.playbackCurrentTime = 0
    }
}
