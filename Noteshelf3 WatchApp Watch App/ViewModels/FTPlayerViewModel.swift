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

    @Published var playDurationStr: String = "00: 00"
    @Published var isPlaying: Bool = false
    @Published var progress: CGFloat = 0.0

    init(recording: FTWatchRecording) {
        self.recording = recording
        self.playDurationStr = FTWatchUtils.timeFormatted(totalSeconds: UInt(self.recording.duration))
    }

    deinit {
        print("zzzz - deinit FTPlayerViewModel")
    }

    func handlePlayTapAction() {
        if(self.audioService == nil) {
            self.audioService = FTAudioService()
            self.audioService.delegate = self
        }

        if self.audioActivity == nil || self.audioActivity?.audioServiceStatus == FTAudioServiceStatus.none, let path = recording.filePath {
            self.audioActivity = self.audioService.playAudioWithURL(audioURL: path)
            if let recentAudioGUID = recentPlayedAudio["GUID"] as? String, recentAudioGUID != recording.GUID {
                recentPlayedAudio["currentTime"] = 0.0
                recentPlayedAudio["GUID"] = recording.GUID
            }
            recentPlayedAudio["currentTime"] = 0.0
            self.addObservers()
        } else if(self.audioActivity != nil && self.audioActivity?.audioServiceStatus == .playing) {
            self.audioService.stopPlayingAudio()
        }
    }

    func forwardPlayBy15Sec() {
        if let service = self.audioService {
            service.forwardAudio(bySeconds: 15)
        }
    }

    func backwardPlayBy15Sec() {
        if let service = self.audioService {
            service.backwardAudio(bySeconds: 15)
        }
    }

    func resetPlay() {
        self.audioService = nil
        self.audioActivity = nil
        self.removeObservers()
        self.playDurationStr = "00: 00"
        self.isPlaying = false
        self.progress = 0.0
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if(keyPath == "currentTime") {
            self.updatePlayTime()
        }
    }
}

private extension FTPlayerViewModel {
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
        self.playbackCurrentTime = Int(self.audioActivity!.currentTime)
        self.playDurationStr = FTWatchUtils.timeFormatted(totalSeconds: UInt(self.playbackCurrentTime))
        self.progress = CGFloat(Double(self.playbackCurrentTime)/self.recording.duration)
    }
}

extension FTPlayerViewModel: FTAudioServiceDelegate {
    func audioServiceDidFinishRecording(withURL audioURL: URL) {
    }
    
    func audioServiceDidFinishPlaying(withError error: Error?) {
        self.audioService = nil
        self.audioActivity = nil
#if DEBUG
        debugPrint("audioServiceDidFinishPlaying")
#endif
        self.removeObservers()
        self.playDurationStr = self.recording.duration.formatSecondsToString()
        self.isPlaying = false
        self.progress = 0.0
    }
}
