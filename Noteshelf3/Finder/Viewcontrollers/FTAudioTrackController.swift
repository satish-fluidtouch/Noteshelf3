//
//  FTAudioTrackController.swift
//  Noteshelf3
//
//  Created by Sameer on 25/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import CoreMedia
import FTCommon

enum FTSourceMode {
    case finder
    case notebook
}

class FTAudioTrackController: UIViewController, FTCustomPresentable {
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: true)
    @IBOutlet weak var titleLabel: FTCustomLabel!
    private var audioFileName = ""
    var canUpdate = false
    var selectedAnnotation: FTAudioAnnotation?
    @IBOutlet var tableView: UITableView?
    var audioAnnotations = [FTAudioAnnotation]()
    var mode = FTSourceMode.notebook
    
    override func viewDidLoad() {
        let nib = UINib.init(nibName: "FTAudioTrackHeaderView", bundle: nil);
        self.tableView?.register(nib, forHeaderFooterViewReuseIdentifier: "FTAudioTrackHeaderView");
        super.viewDidLoad()
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.layer.cornerRadius = 10
        tableView?.layer.masksToBounds = true
        self.canUpdate = true
        addAudioSessionNotifications()
        titleLabel.text = "AudioRecordings".localized
        tableView?.tableFooterView = UIView(frame: .zero)
        if let selectedAnnotation = selectedAnnotation,  let index = self.audioAnnotations.firstIndex(of: selectedAnnotation) {
//            let rect = tableView.rectForHeader(inSection: index)
            //Section header rect is coming incorrect, hence caluclating offset based on index
            let offSet = index * 66
            let contentOffset = CGPoint(x: 0, y: CGFloat(offSet))
            runInMainThread {
                self.tableView?.setContentOffset(contentOffset, animated: false)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let model = FTAudioSessionManager.sharedSession().activeSession().audioRecording,
            let audioAnnotation = getAudioAnnotationFor(model),
            audioAnnotation.recordingModel.currentAudioSessionState() != .stateNone {
            let time = FTAudioSessionManager.sharedSession().activeSession().currentPlaybackTime()
            let currentSeekTime = CMTimeGetSeconds(time)
            let model = audioAnnotation.recordingModel.model(forDuration: currentSeekTime)
            let cell = self.getCellForRecording(model, audioAnnotation: audioAnnotation)
            if let cell = cell {
                var indexPathToShow = self.tableView?.indexPath(for: cell)
                if FTAudioSessionManager.sharedSession().activeSessionState() == .stateRecording {
                    let section = audioAnnotations.firstIndex(of: audioAnnotation)
                    indexPathToShow = IndexPath(row: audioAnnotation.recordingModel.audioTracks().count, section: section ?? 0)
                }
                if let indexPathToShow = indexPathToShow ,let cell = self.tableView?.cellForRow(at: indexPathToShow) as? FTAudioSessionCell {
                    cell.updateUI(currentSeekTime, state: FTAudioSessionManager.sharedSession().activeSessionState())
                }
            }
        }
    }
    
    private func getAudioModel(for index: Int, audioAnnotation: FTAudioAnnotation) -> FTAudioTrackModel? {
        var model: FTAudioTrackModel?
        if let recordingModel = audioAnnotation.recordingModel {
            if (recordingModel.audioTracks().count) > index {
                model = recordingModel.audioTracks()[index] as? FTAudioTrackModel
            }
        }
        return model
    }
    
    private func getAudioAnnotationFor(_ model: FTAudioRecordingModel) -> FTAudioAnnotation? {
        var annotation: FTAudioAnnotation? = nil
        for audio in audioAnnotations {
            if  audio.recordingModel.fileName == model.fileName {
                annotation = audio
                break
            }
        }
        return annotation
    }
    
    class func showAsPopover(fromSourceView sourceView:UIView,
                             overViewController viewController:UIViewController, with size: CGSize, annotations: [FTAudioAnnotation], mode: FTSourceMode, selectedAnnotation: FTAudioAnnotation?) {
        let audioVc = FTAudioTrackController.instantiate(fromStoryboard: .finder)
        audioVc.audioAnnotations = annotations
        audioVc.customTransitioningDelegate.sourceView = sourceView
        audioVc.mode = mode
        audioVc.selectedAnnotation = selectedAnnotation
        viewController.ftPresentModally(audioVc, contentSize: size, animated: true, completion: nil)
    }
}

extension FTAudioTrackController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        if !audioAnnotations.isEmpty {
            let audioAnnotation = audioAnnotations[section]
            let isCollapsed = UserDefaults.standard.bool(forKey: "collapsed_\(audioAnnotation.uuid)")
            if isCollapsed {
                return 0
            }
            count = audioAnnotation.recordingModel.audioTracks().count
            if (audioAnnotation.recordingModel.isCurrentAudioRecording()) {
                count += 1
            }
            if count >= 1 {
                count += 1
            }
        }
        return count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return audioAnnotations.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "FTAudioTrackHeaderView") as? FTAudioTrackHeaderView {
            headerView.headerDelegate = self;
            let annotation = audioAnnotations[section]
            headerView.cofigure(with: annotation)
            return headerView;
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FTAudioSessionCell", for: indexPath)
        let audioAnnotation = audioAnnotations[indexPath.section]
        var tracksCount = audioAnnotation.recordingModel.audioTracks().count
        if audioAnnotation.recordingModel.isCurrentAudioRecording() {
            tracksCount += 1
        }
        if let cell = cell as? FTAudioSessionCell {
            if tracksCount > indexPath.row {
                let model = self.getAudioModel(for: indexPath.row, audioAnnotation: audioAnnotation)
                cell.configureCell(with: model, index: indexPath.row + 1, del: self, isLastCell: false)
            } else {
                cell.configureCell(with: nil, index: indexPath.row + 1, del: self, isLastCell: true)
            }
        }
        cell.selectionStyle = .none
        cell.separatorInset = .zero
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let audioAnnotation = audioAnnotations[indexPath.section]
        let tracksCount = audioAnnotation.recordingModel.audioTracks().count
        if tracksCount > indexPath.row, let model = getAudioModel(for: indexPath.row, audioAnnotation: audioAnnotation) {
            let session = FTAudioSessionManager.sharedSession().activeSession()
            if audioAnnotation.recordingModel.isCurrentAudioPlaying() && audioFileName ==  model.audioFileName {
                session?.pausePlayback()
            } else {
                self.playTrack(with: audioAnnotation)
                if model.audioFileName != self.audioFileName {
                    let seekTime = audioAnnotation.recordingModel.startSeekTime(forTrack: model)
                    let time = CMTimeMakeWithSeconds(seekTime, preferredTimescale: Int32(Double(NSEC_PER_SEC)))
                    session?.seekTime(time)
                    self.audioFileName = model.audioFileName
                }
            }
        } else {
            self.didTapOnRecording(with:  audioAnnotation)
        }
    }
    
    func playTrack(with audioAnnotation: FTAudioAnnotation) {
        if let session = FTAudioSessionManager.sharedSession().activeSession() {
            let isSamewindow = true
//            if session.windowHash() != view.window.hashValue {
//                session.resetSession()
//                isSamewindow = false
//            }
            if session.audioSessionState() == AudioSessionState.stateRecording {
                session.stopRecording()
            }
           if !isSamewindow || !audioAnnotation.recordingModel.isAudioConfiguredInSession() {
               self.stopAudioSessionProcess()
               session.setAudioRecordingModel(audioAnnotation.recordingModel, for: self.view.window)
           }
            session.startPlayback()
        }
    }
    
    func addAudioSessionNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionDidChange(_:)), name: NSNotification.Name.FTAudioSessionEventChange, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionDidProgress(_:)), name: NSNotification.Name.FTAudioSessionProgress, object: nil)
    }
    
    @objc func audioSessionDidChange(_ notification: Notification) {
//        if !isSameWindow(notification) {
//            return
//        }
        runInMainThread {
            if let userinfo = notification.userInfo {
                let value = (userinfo[FTAudioSessionEventNotificationKey] as? Int) ?? 0
                let state =  FTAudioSessionEvent.init(rawValue: UInt(value))
                if let audioModel = userinfo[FTAudioSessionAudioRecordingNotificationKey] as? FTAudioRecordingModel, let audioAnnotation = self.getAudioAnnotationFor(audioModel) {
                    let sessionId = audioModel.fileName;
                    if  audioAnnotation.recordingModel.fileName == sessionId {
                        if FTAudioSessionDidStartRecording == state || FTAudioSessionDidStopRecording == state ||
                            FTAudioSessionDidFinishPlayback == state {
                            self.tableView?.reloadData()
                        }
                    }
                }
                self.updateCell(notification)
            }
        }

    }
    
    @objc func audioSessionDidProgress(_ notification: Notification) {
//        if !isSameWindow(notification) {
//            return
//        }
        if canUpdate {
            updateCell(notification)
        }
    }
    
   private func updateCell(_ notification: Notification) {
        if let userInfo = notification.userInfo,  let model = userInfo[FTAudioSessionAudioRecordingNotificationKey] as? FTAudioRecordingModel,  let audioAnnotation = getAudioAnnotationFor(model) {
            let currentSeekTime = userInfo[FTAudioSessionCurrentTimeNotificationKey] as? Double ?? 0
            let duration = audioAnnotation.recordingModel.audioDuration()
            let number = userInfo[FTAudioSessionStateNotificationKey] as? Int ?? 0
            var state = AudioSessionState(rawValue: number) ?? AudioSessionState.stateNone
            var cell: FTAudioSessionCell?
            var header: FTAudioTrackHeaderView?

            let model = audioAnnotation.recordingModel.model(forDuration: currentSeekTime)
            var index = -1
            if state == .stateNone, audioFileName != "" {
                for (_index, eachModel) in audioAnnotation.recordingModel.audioTracks().enumerated() {
                    if let model = eachModel as? FTAudioTrackModel ,model.audioFileName == self.audioFileName {
                        index = _index
                        break
                    }
                }
                let section = audioAnnotations.firstIndex(of: audioAnnotation)
                if let _cell = self.tableView?.cellForRow(at: IndexPath(row: index, section: section ?? 0)) as? FTAudioSessionCell {
                    cell = _cell
                }
            } else {
                self.audioFileName = model?.audioFileName ?? ""
                cell = self.getCellForRecording(model, audioAnnotation: audioAnnotation)
            }
        
            let currentlyActive = audioAnnotation.recordingModel.isAudioConfiguredInSession()
            if(!currentlyActive) {
                state = .stateNone;
            }
            if let section = audioAnnotations.firstIndex(of: audioAnnotation)  {
                header = tableView?.headerView(forSection: section) as? FTAudioTrackHeaderView
            }
            if state == .stateRecording {
                if cell == nil {
                    cell = self.getRecordingCell()
                }
                cell?.isSelected = true
                cell?.updateUI((currentSeekTime - duration), state: state)
                header?.updateUI(currentSeekTime, state: state)
            } else if state == .statePlaying {
                if let cell = cell, !cell.isSelected {
                    tableView?.selectRow(at: tableView?.indexPath(for: cell), animated: false, scrollPosition: .none)
                }
                cell?.updateUI(currentSeekTime, state: state)
                header?.updateUI(currentSeekTime, state: state)
            } else {
                cell?.updateUI(CGFloat(cell?.model?.duration() ?? 0), state: state)
                header?.updateUI(duration, state: state)
            }
        }
    }
    
    private func getCellForRecording(_ trackModel: FTAudioTrackModel?, audioAnnotation: FTAudioAnnotation) -> FTAudioSessionCell? {
        var index: Int?
        if let trackModel = trackModel {
            index = audioAnnotation.recordingModel.audioTracks().firstIndex(where: { eachModel in
                return (eachModel as? FTAudioTrackModel == trackModel)
            })
        }
        if let index = index, let section = audioAnnotations.firstIndex(of: audioAnnotation) {
            return tableView?.cellForRow(at: IndexPath(row: index, section: section)) as? FTAudioSessionCell
        }
        return nil
    }
    
    private func getRecordingCell() -> FTAudioSessionCell? {
        var cell: FTAudioSessionCell?
        if let model = FTAudioSessionManager.sharedSession().activeSession().audioRecording, let audioAnnotation = getAudioAnnotationFor(model) {
            let count = audioAnnotation.recordingModel.audioTracks().count
            if audioAnnotation.recordingModel.isCurrentAudioRecording() {
              cell = tableView?.cellForRow(at: IndexPath(row: count, section: 0)) as? FTAudioSessionCell
          }
        }
        return cell
    }
    
    private func stopAudioSessionProcess() {
        if let session = FTAudioSessionManager.sharedSession().activeSession() {
            if session.audioSessionState() == .statePlaying {
                session.stopPlayback()
            } else if session.audioSessionState() == .stateRecording {
                session.stopRecording()
            }
        }
    }
    
    private func isSameWindow(_ notification: Notification?) -> Bool {
        let userinfo = notification?.userInfo
        let windowHash = Int((userinfo?[FTRefreshWindowKey] as? NSNumber)?.uintValue ?? 0)
        let currentWindowHash = view.window.hashValue

        if windowHash != currentWindowHash {
            return false
        }
        return true
    }
}

extension FTAudioTrackController : FTAudioHeaderViewDelegate, FTAudioSessionDelegate {
    func didTapToggleButton(isCollapsed: Bool, annotation: FTAudioAnnotation) {
        if let index = audioAnnotations.firstIndex(of: annotation) {
            let sectionToReload = IndexSet(integer: index)
            self.tableView?.reloadSections(sectionToReload, with: .automatic)
        }
    }
    
    func didTapPlayCompleteAudio(with annotation: FTAudioAnnotation) {
        guard  let session = FTAudioSessionManager.sharedSession().activeSession() else {
            return
        }
        var isSameWindow = true
//        if session.windowHash() != self.view.window.hashValue {
//            session.resetSession()
//            isSameWindow = false
//        }
        if annotation.recordingModel.isCurrentAudioPlaying() {
            session.pausePlayback()
        } else {
            if session.audioSessionState() == .stateRecording {
                session.stopRecording()
            }
            if !isSameWindow || !annotation.recordingModel.isAudioConfiguredInSession() {
                self.stopAudioSessionProcess()
                session.setAudioRecordingModel(annotation.recordingModel, for: self.view.window)
            }
            session.startPlayback()
        }
    }
    
    func didTapOnPlay(with model: FTAudioTrackModel, cell: UITableViewCell) {
        guard let tableView = tableView, let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        self.canUpdate = false
        let session = FTAudioSessionManager.sharedSession().activeSession()
        let audioAnnotation = audioAnnotations[indexPath.section]

        if audioAnnotation.recordingModel.isCurrentAudioPlaying() && audioFileName ==  model.audioFileName {
            session?.pausePlayback()
        } else {
            self.playTrack(with: audioAnnotation)
            if model.audioFileName != self.audioFileName {
                let seekTime = audioAnnotation.recordingModel.startSeekTime(forTrack: model)
                let time = CMTimeMakeWithSeconds(seekTime, preferredTimescale: Int32(Double(NSEC_PER_SEC)))
                session?.seekTime(time)
                self.audioFileName = model.audioFileName
            }
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: { [weak self] in
            self?.canUpdate = true
        })
    }
    
    func didTapOnRecording(with audioAnnotation: FTAudioAnnotation) {
        guard let session = FTAudioSessionManager.sharedSession().activeSession() else {
            return
        }
        var isSameWindow = true
        //TODO:  Window hash is not working, need to check this
//        if session.windowHash() != self.view.window.hashValue {
//            session.resetSession()
//            isSameWindow = false
//        }
        if session.audioSessionState() == .stateRecording {
            session.stopRecording()
        }
        if session.audioSessionState() == .statePlaying {
            session.stopPlayback()
        }
        if !isSameWindow || audioAnnotation.recordingModel.isAudioConfiguredInSession() {
            self.stopAudioSessionProcess()
            session.setAudioRecordingModel(audioAnnotation.recordingModel, for: self.view.window)
        }
        FTPermissionManager.isMicrophoneAvailable(onViewController: self) { [weak self] success in
            if success {
                session.startRecording()
                self?.dismiss(animated: true)
            }
        }
//        self.tableView?.reloadData()
    }
}
