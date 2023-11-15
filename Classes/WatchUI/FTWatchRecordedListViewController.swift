//
//  FTWatchRecordedListViewController.swift
//  Noteshelf
//
//  Created by Simhachalam on 31/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import CoreMedia
import FTCommon
import AVFoundation

@objc protocol FTWatchRecordedListViewControllerDelegate : NSObjectProtocol {
    func recordingViewController(_ recordingsViewController: FTWatchRecordedListViewController, didSelectRecording recordedAudio:FTWatchRecordedAudio, forAction actionType:FTAudioActionType);
}

@objc class FTWatchRecordedListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate,FTWatchAudioActionsDelegate, UIPopoverPresentationControllerDelegate, FTCustomPresentable {

    let customTransitioningDelegate = FTCustomTransitionDelegate(with: .presentation)

    @IBOutlet weak var tableView : UITableView?
    @IBOutlet weak var tempPlusButton : UIButton?
    @IBOutlet weak var noRecordingsView : UIView?
    @IBOutlet weak var noRecordingsContentView : UIView?

    @IBOutlet weak var loadingActivityView : UIActivityIndicatorView?
    @IBOutlet weak var backButton : UIButton?

    fileprivate weak var timer : Timer? = nil;
    fileprivate var onDimissCallback : (()->())?;
    

    var actionContext = FTAudioActionContext.shelf;
    
    var currentPlayingGUID:String! = "" {
        willSet {
            self.removeObserverForCurrentPlayback();
        }
        didSet {
            if(self.currentPlayingGUID.count > 0) {
                self.addObserverForCurrentPlayback();
            }
        }
    }
    
    var recordedAudioFiles:[FTWatchRecording] = [FTWatchRecording]();
    
    weak var delegate: FTShelfViewModelProtocol?;

    weak var watchDelegate: FTWatchRecordedListViewControllerDelegate?

    var audioPlayer:AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "AppleWatch".localized
        self.popoverPresentationController?.delegate = self
        self.tempPlusButton?.isHidden = true
        #if DEBUG
            self.tempPlusButton?.isHidden = false
        #endif
        self.loadingActivityView?.isHidden = false
        self.loadingActivityView?.startAnimating()
        self.noRecordingsContentView?.isHidden = true
        
        self.reloadContents();
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentsUpdatedNotification(_:)), name: NSNotification.Name(rawValue: FTRecordingCollectionUpdatedNotification), object: nil)
        
        if let noRecordingsView = self.noRecordingsView {
            self.view.bringSubviewToFront(noRecordingsView)
        }
        self.tableView?.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never;
    }
    
    @objc func contentsUpdatedNotification(_ notification:Notification) {
        self.reloadContents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        if canbePopped() {
            self.backButton?.isHidden = false;
            self.backButton?.setImage(UIImage(named:"backDark"), for: .normal)
        } else if !isRegularClass() {
            self.backButton?.isHidden = false;
            self.backButton?.setImage(UIImage(named:"naviconCloseLight"), for: .normal)
        } else {
            self.backButton?.isHidden = true;
        }
    }

    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
        self.resetAudioPlayer()
        self.timer?.invalidate();
        self.timer = nil;
        self.onDimissCallback?();
        self.onDimissCallback = nil;
    }
    
    internal func reloadContents()
    {
        FTNoteshelfDocumentProvider.shared.allRecordings({ (recordings) in
            self.recordedAudioFiles = recordings;
            self.tableView?.reloadData();
            self.loadingActivityView?.isHidden = true
            self.noRecordingsContentView?.isHidden = false
        });
    }

    //MARK:- FTWatchAudioActionsDelegate
    func actionsViewController(_ actionsViewController: FTWatchAudioActionsViewController, didSelectAction audioAction: FTAudioAction) {
        
        self.handleAudioAction(audioAction, withSelectedAudio: actionsViewController.currentSelectedAudio!)
    }
    func handleAudioAction(_ audioAction:FTAudioAction, withSelectedAudio selectedAudio:FTWatchRecording){
        if(audioAction.actionType == FTAudioActionType.deleteRecording)
        {
            let alertAction = UIAlertController.init(title: NSLocalizedString("AudioDeleteConfirmMessage", comment: "Delete"),
                                                     message: "",
                                                     preferredStyle: UIAlertController.Style.alert);
            let okAction = UIAlertAction.init(title: NSLocalizedString("Delete", comment: "Delete"),
                                              style: UIAlertAction.Style.destructive,
                                              handler: { [weak self] (action) in
                                                self?.processAudioDeleteAction(for: selectedAudio)
            });
            alertAction.addAction(okAction);

            let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: nil);
            alertAction.addAction(cancelAction);

            self.present(alertAction, animated: true, completion: nil);
        }
        else if (audioAction.actionType == FTAudioActionType.markAsUsed || audioAction.actionType == FTAudioActionType.markAsUnused)
        {
            let audioFile = selectedAudio
            audioFile.audioStatus = audioAction.actionType == FTAudioActionType.markAsUnused ? .unread : .read
            FTNoteshelfDocumentProvider.shared.updateRecording(item: audioFile, onCompletion: { (error) in
                if(error == nil){
                    self.tableView?.reloadData()
                    let event = audioAction.actionType == FTAudioActionType.markAsUnused ? "Mar as Unread" : "Mark as read";
                    FTCLSLog("Watch Recording : \(event)");
                }
            })
            if(self.view.isRegularClass()){
                self.navigationController?.popViewController(animated: true)
            }
        }
        else
        {
            self.delegate?.recordingViewController(self, didSelectRecording: selectedAudio as! FTWatchRecordedAudio, forAction: audioAction.actionType)
            self.watchDelegate?.recordingViewController(self, didSelectRecording: selectedAudio as! FTWatchRecordedAudio, forAction: audioAction.actionType)

        }
    }

    func processAudioDeleteAction(for audio:FTWatchRecording) {
        let isCurrentAudio = (self.currentPlayingGUID == audio.GUID)
        if isCurrentAudio {
            self.currentPlayingGUID = ""
            self.resetAudioPlayer()
        }

        FTNoteshelfDocumentProvider.shared.deleteRecording(item: audio, onCompletion: { [weak self](error) in
            if(nil != error){
                assert(false, "error should handle here");
            }
            else {
                self?.reloadContents();
                if self?.isRegularClass() == true {
                    self?.navigationController?.popViewController(animated: true)
                    FTCLSLog("Watch Recording : Delete");
                    //Event
                }
            }
        })
    }


    //MARK:- Presentation
    class func showRecordingsPopover(withDelegate delegate: FTShelfViewModelProtocol,
                                     fromSourceView sourceView: UIView,
                                     onViewController viewController: UIViewController,
                                     context : FTAudioActionContext,
                                     onDismiss : (()->())? = nil) -> FTWatchRecordedListViewController
    {
        let recordingsViewController = UIStoryboard(name: "FTWatchRecordings", bundle: nil).instantiateInitialViewController() as! FTWatchRecordedListViewController;
        recordingsViewController.actionContext = context;
        recordingsViewController.delegate = delegate
        
        recordingsViewController.customTransitioningDelegate.sourceView = sourceView
        let contentSize = viewController.isRegularClass() ? CGSize(width: 330.0, height: 477.0) : CGSize(width: 320, height: 410)
        viewController.ftPresentModally(recordingsViewController, contentSize: contentSize, animated: true, completion: nil)
        
        recordingsViewController.onDimissCallback = onDismiss;
        
        return recordingsViewController;
    }
    
     class func pushToRecordings(withDelegate delegate: FTShelfViewModelProtocol,
                                      fromSourceView sourceView: UIView,
                                      onViewController viewController: UIViewController,
                                      context : FTAudioActionContext) {
        let recordingsViewController = UIStoryboard(name: "FTWatchRecordings", bundle: nil).instantiateInitialViewController() as! FTWatchRecordedListViewController;
        recordingsViewController.delegate = delegate
        recordingsViewController.actionContext = context;
        let navigationController = viewController.navigationController
        navigationController?.pushViewController(recordingsViewController, animated: true);
    }

    @IBAction override func backButtonTapped(_ sender: UIButton?) {
        self.resetAudioPlayer()
        if self.navigationController?.viewControllers.first == self{
            self.dismiss(animated: true, completion: { [weak self] in
                self?.onDimissCallback?();
                self?.onDimissCallback = nil;
            });
        }
        else {
            self.navigationController?.popViewController(animated: true)
            self.onDimissCallback?();
            self.onDimissCallback = nil;
        }
    }

    //MARK:- UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.noRecordingsView?.isHidden = (self.recordedAudioFiles.count > 0)
        return self.recordedAudioFiles.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FTWatchRecordedAudioCell") as! FTWatchRecordedAudioCell;
        cell.playButton.tag = indexPath.row;
        
        let audioFile:FTWatchRecording = self.recordedAudioFiles[indexPath.row]
        
        cell.dateLabel.text = audioFile.audioTitle;
        cell.dateLabel.addCharacterSpacing(kernValue: -0.32)
        cell.durationLabel.text = audioFile.duration.formatSecondsToString()
        cell.playButton.addTarget(self, action: #selector(FTWatchRecordedListViewController.playRecordedAudio(_:)), for: UIControl.Event.touchUpInside)
        cell.dateLabel.font = (audioFile.audioStatus == .unread) ? UIFont.appFont(for: .bold, with: 16) : UIFont.appFont(for: .regular, with: 16)
        cell.iconChevron.isHidden = !(self.view.isRegularClass())
        
        cell.playButton.isHidden = false
        cell.activityIndicator.isHidden = true

        cell.audioFileUUID = audioFile.GUID;
        cell.circularProgressView.isHidden = true
        if(audioFile.downloadStatus == .downloaded){
            cell.playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
            cell.playButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .selected)
            cell.playButton.isSelected = (self.currentPlayingGUID == audioFile.GUID)
        } else if(audioFile.downloadStatus == .notDownloaded) {
            cell.playButton.isSelected = false
            cell.playButton.setImage(UIImage.init(systemName: "icloud.and.arrow.down"), for: .normal)
            cell.playButton.setImage(UIImage.init(systemName: "icloud.and.arrow.down"), for: .selected)
        } else if(audioFile.downloadStatus == .downloading) {
            cell.playButton.isHidden = true
            cell.activityIndicator.isHidden = false
            cell.activityIndicator.startAnimating()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let audioFile:FTWatchRecording = self.recordedAudioFiles[indexPath.row]
        self.processAudioDeleteAction(for: audioFile)
    }

    //MARK:- UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if(self.recordedAudioFiles[indexPath.row].downloadStatus == .notDownloaded){
            let cell:FTWatchRecordedAudioCell = tableView.cellForRow(at: indexPath) as! FTWatchRecordedAudioCell
            cell.playButton.sendActions(for: UIControl.Event.touchUpInside)
            return
        }
        else if(self.recordedAudioFiles[indexPath.row].downloadStatus == .downloading){
            return
        }
        
        if(self.view.isRegularClass()){
            let audioActionsController = UIStoryboard(name: "FTWatchRecordings", bundle: nil).instantiateViewController(withIdentifier: "FTWatchAudioActionsViewController") as! FTWatchAudioActionsViewController
            audioActionsController.delegate = self
            audioActionsController.actionContext = self.actionContext;
            audioActionsController.currentSelectedAudio = self.recordedAudioFiles[indexPath.row] as? FTWatchRecordedAudio
            self.navigationController?.pushViewController(audioActionsController, animated: true)
        }
        else
        {
            let actionsProvider = FTWatchAudioActionsProvider()
            let audioActions = actionsProvider.actionsForAudio(self.recordedAudioFiles[indexPath.row] as? FTWatchRecordedAudio, actionContext: self.actionContext)
            let alertController:UIAlertController = UIAlertController.init(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
            audioActions.forEach({(audioAction) in
                
                let action = UIAlertAudioAction.init(title: audioAction.displayTitle, style: audioAction.actionStyle.alertActionStyle(), handler: { [weak self] (action) in
                    
                    if let selfObject = self {
                        selfObject.handleAudioAction(FTAudioAction.audioActionForType((action as! UIAlertAudioAction).actionType!), withSelectedAudio: selfObject.recordedAudioFiles[indexPath.row])
                    }
                });
                
                action.actionType = audioAction.actionType
                alertController.addAction(action)
            })
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: nil))

            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    //MARK:- Player Actions

    @objc func playRecordedAudio(_ sender:UIButton){
        let audioFile = self.recordedAudioFiles[sender.tag]
        if(audioFile.downloadStatus == .notDownloaded){
            FTNoteshelfDocumentProvider.shared.startDownloading(item: self.recordedAudioFiles[sender.tag])
            audioFile.downloadStatus = .downloading
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
            return
        }
        else if(audioFile.downloadStatus == .downloading){
            return
        }
        if(audioFile.audioStatus == .unread){
            audioFile.audioStatus = .read
            FTNoteshelfDocumentProvider.shared.updateRecording(item: audioFile, onCompletion: { (error) in
                if(error == nil){
                    self.tableView?.reloadData()
                }
            })
        }

        let isCurrentAudio = (self.currentPlayingGUID == audioFile.GUID)
        self.currentPlayingGUID = ""
        let audioFileURL = self.recordedAudioFiles[sender.tag].filePath
        self.resetAudioPlayer()
        if (isCurrentAudio == false){
            do{
                let audioSession = AVAudioSession.sharedInstance();
                try audioSession.setCategory(AVAudioSession.Category.playback,mode:.default);
                try audioSession.setActive(true);

                try self.audioPlayer = AVAudioPlayer.init(contentsOf: audioFileURL!)

                self.audioPlayer.prepareToPlay()
                self.audioPlayer.play()
                self.audioPlayer.delegate = self
                self.currentPlayingGUID = self.recordedAudioFiles[sender.tag].GUID
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FTAudioPlayerDidStartPlaying"),
                                                object: self.currentPlayingGUID,
                                                userInfo: nil);
            }
            catch let error as NSError {
                #if DEBUG
                debugPrint("Error: \(error.localizedDescription)")
                #endif
            }
        }
        self.tableView?.reloadData()
    }
    func createNotebookWithRecording(_ sender:UIButton){
        self.delegate?.recordingViewController(self, didSelectRecording: self.recordedAudioFiles[sender.tag] as! FTWatchRecordedAudio, forAction: FTAudioActionType.createNotebook)
    }

    //MARK:- AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FTAudioPlayerDidEndPlaying"),
                                        object: self.currentPlayingGUID,
                                        userInfo: nil);
        self.currentPlayingGUID = ""
        self.tableView?.reloadData()
    }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FTAudioPlayerDidEndPlaying"),
                                        object: self.currentPlayingGUID,
                                        userInfo: nil);
        self.currentPlayingGUID = ""
        self.tableView?.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func addObserverForCurrentPlayback()
    {
        self.timer?.invalidate();
        self.timer = nil;
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self] (timer) in
            if let audioPlayer = self?.audioPlayer, let currentGUID = self?.currentPlayingGUID {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FTAudioPlayerCurrentTimeDidChange"),
                                                object: currentGUID,
                                                userInfo: ["currentTime" : audioPlayer.currentTime,
                                                           "duration" : audioPlayer.duration]);
            }
        });
    }
    
    fileprivate func removeObserverForCurrentPlayback()
    {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FTAudioPlayerDidEndPlaying"),
                                        object: self.currentPlayingGUID,
                                        userInfo: nil);
        self.timer?.invalidate();
        self.timer = nil;
    }
}


//MARK:- temporary -
extension FTWatchRecordedListViewController
{
    @IBAction func addTemporaryWatchRecording(_ sender:UIButton){
        sender.tag = (sender.tag == 0 ? 1 : 0)
        guard let path = Bundle.main.path(forResource: sender.tag == 0 ? "sampleAudio1":"sampleAudio2", ofType: "m4a") else {
            return
        }
        let audioFileURL = URL.init(fileURLWithPath: path)
        let newGUID = FTUtils.getUUID()
        
        let destFilePath = NSTemporaryDirectory().appendingFormat("%@.m4a", newGUID);
        let destUrl = URL.init(fileURLWithPath: destFilePath)
        if(FileManager.default.fileExists(atPath: destUrl.path))
        {
            do{ try FileManager.default.removeItem(at: destUrl)} catch{}
        }
        do{try FileManager.default.copyItem(at: audioFileURL, to: destUrl)} catch{}
        
        let asset = AVURLAsset.init(url: destUrl)
        let audioDuration = asset.duration
        let audioDurationSeconds = CMTimeGetSeconds(audioDuration)
        
        let newRecording = FTWatchRecordedAudio.init(GUID: newGUID, date: Date(), duration: audioDurationSeconds)
        newRecording.filePath = destUrl;
        newRecording.syncStatus = .synced
        FTNoteshelfDocumentProvider.shared.addRecording(tempRecord: newRecording, onCompletion: { (recordObject, error) in
            if(nil == error) {
                self.reloadContents();
            }
            else {
                (error! as NSError).showAlert(from: self);
            }
        });
    }
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        self.resetAudioPlayer()
        self.onDimissCallback?();
        self.onDimissCallback = nil;
    }
    
    func resetAudioPlayer(){
        if(self.audioPlayer != nil){
            if(self.audioPlayer.isPlaying){
                self.audioPlayer.stop()
            }
            self.audioPlayer.delegate = nil
            self.audioPlayer = nil
        }
    }
}
class UIAlertAudioAction : UIAlertAction{
    var actionType:FTAudioActionType?
}
