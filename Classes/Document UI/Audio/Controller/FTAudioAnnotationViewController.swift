//
//  FTAudioAnnotationViewController.swift
//  Noteshelf
//
//  Created by Matra on 19/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit


class FTtestView : UIView {
    override var frame: CGRect {
        set {
            super.frame = newValue;
        }
        get {
            return super.frame;
        }
    }
}
@objcMembers class FTAudioAnnotationViewController: UIViewController {

    @IBOutlet weak var audioAnnotationView: FTAudioAnnotationView!
    @IBOutlet weak var borderView : DropBorderView?
    weak var delegate: FTAnnotationEditControllerDelegate?
    var annotation: FTAnnotation {
        return _annotation!;
    }
    
    private var annotationMode: FTAnnotationMode = FTAnnotationMode.create
    private var _annotation: FTAnnotation?
    private var dragged: Bool = false
    private var canDrag: Bool = false
    private var isSelected: Bool = false
    private var isMenuVisible: Bool = false
    
    required init(withAnnotation annotation: FTAnnotation,
         delegate: FTAnnotationEditControllerDelegate?,
         mode: FTAnnotationMode) {
        super.init(nibName: FTAudioAnnotationViewController.className, bundle: nil)
        _annotation = annotation
        self.annotationMode = mode
        self.delegate = delegate
        let contentScale = delegate?.contentScale() ?? CGFloat(1);
        let frame = CGRectScale(annotation.boundingRect, contentScale)

        self.updateContentFrame(frame)
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.cancelsTouchesInView = false
        self.audioAnnotationView.addGestureRecognizer(tapGesture)
        
        let longPressGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(_:)))
        self.audioAnnotationView.addGestureRecognizer(longPressGesture)
        
        #if targetEnvironment(macCatalyst)
            let contextMenu = UIContextMenuInteraction.init(delegate: self)
            self.view.addInteraction(contextMenu)
        #else
            self.setupMenuItems()
        #endif
        self.handleAnnotationChanges()
        
        NotificationCenter.default.addObserver(forName: Notification.Name.didUpdateAnnotationNotification,
                                               object: annotation,
                                               queue: nil) { [weak self] (notification) in
            self?.refreshView();
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented for FTAudioAnnotationViewController")
    }
    
    override public var canBecomeFirstResponder: Bool {
        return true;
    }
    
    override public func becomeFirstResponder() -> Bool {
        let responder = super.becomeFirstResponder();
        self.view.becomeFirstResponder();
        return responder;
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    private func handleAnnotationChanges(){
        
        guard let annotation = self.annotation as? FTAudioAnnotation else {
            return;
        }
        let undoableInfo = annotation.undoInfo();
        let rect: CGRect = self.contentFrame()
        let scale: CGFloat = self.delegate?.contentScale() ?? 1;
        let oneByZoom: CGFloat = 1/scale;
        
        annotation.boundingRect = CGRectScale(rect, oneByZoom)
        annotation.audioState = .stateNone
        _annotation = annotation
        
        if(self.annotationMode == FTAnnotationMode.create) {
            self.delegate?.annotationControllerDidAddAnnotation(self, annotation: self.annotation)
            self.annotationMode = FTAnnotationMode.edit
        }
        else {
            self.delegate?.annotationControllerDidChange(self,undoableInfo: undoableInfo);
        }
    }
    //MARK:- Helpers
    
    private func hasAudioFiles() -> Bool {
        guard let annotation = self.annotation as? FTAudioAnnotation else {
            return false
        }
        var hasFiles = false
        if !(annotation.recordingModel.audioTracks()?.isEmpty ?? false) {
            hasFiles = true
        }
        return hasFiles
    }
    
    private func state(forEvent eventType: FTProcessEventType) -> [FTAnnotationState] {
        var states: [FTAnnotationState] = []
        
        if eventType == .none {
            states = [.select, .edit]
        } else {
            if self.isSelected {
                states = isMenuVisible ? [.hideMenu] : [.showMenu]
            } else {
                switch eventType {
                case .longPress:
                    states = [.select, .showMenu]
                case .singleTap:
                    states = [.select, .edit]
                default:
                    break
                }
            }
        }
        return states
    }
    
    private func contentFrame() -> CGRect
    {
        var frame = self.view.frame;
        frame = frame.insetBy(dx: 4, dy: 4);
        return frame;
    }
    
    private func updateContentFrame(_ frame : CGRect)
    {
        if !(frame.isInfinite) {
            var frameToSet = frame;
            frameToSet = frameToSet.insetBy(dx: -4, dy: -4);
            if(frameToSet.isInfinite) {
                FTLogError("frameToSet is isInfinite");
            }
            self.view.frame = frameToSet;
        } else {
            FTLogError("frameToSet is isInfinite");
        }
    }
    //MARK: - Gestures
    func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            processEvent(.longPress,at: CGPoint.zero)
        }
    }
    
    func tapGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .recognized {
            processEvent(.singleTap,at: CGPoint.zero)
        }
    }
    
    //MARK: - Menu
    
    func showMenu(_ show: Bool) {
        #if !targetEnvironment(macCatalyst)
        _ = self.becomeFirstResponder()
        let theMenu = UIMenuController.shared
        if show {
            isMenuVisible = true
            setupMenuItems()
            theMenu.update()
            if let superview = self.view.superview {
                let rect = self.view.frame.insetBy(dx: 0, dy: 0)
                theMenu.showMenu(from: superview, rect: rect)
            }
        } else {
            isMenuVisible = false
            if #available(iOS 13.0, *) {
                theMenu.hideMenu()
            } else {
                theMenu.setMenuVisible(false, animated: true)
            }
        }
        #endif
    }
    
    private func setupMenuItems() {
        guard let annotation = self.annotation as? FTAudioAnnotation else {
            return
        }
        let theMenu = UIMenuController.shared
        var menuItems : [UIMenuItem] = []
         
        var recordMenuItem : UIMenuItem!
        if let model = annotation.recordingModel , model.isCurrentAudioRecording() {
            recordMenuItem = UIMenuItem(title: NSLocalizedString("StopRecord", comment: "Stop Recording"), action: #selector(self.stopRecordMenuItem(_:)))
        } else {
            recordMenuItem = UIMenuItem(title: NSLocalizedString("Record", comment: "Record"), action: #selector(self.recordMenuAction(_:)))
        }
        menuItems.append(recordMenuItem)
        if hasAudioFiles() {
            var playMenuItem: UIMenuItem?
            if annotation.recordingModel.isCurrentAudioPlaying() {
                playMenuItem = UIMenuItem(title: NSLocalizedString("Pause", comment: "Pause"), action: #selector(self.pausePlayMenuItem(_:)))
            } else {
                playMenuItem = UIMenuItem(title: NSLocalizedString("Play", comment: "Play"), action: #selector(self.playMenuAction(_:)))
            }
            if let playMenu = playMenuItem {
                menuItems.append(playMenu)
            }
            
            let exportMenuItem = UIMenuItem(title: NSLocalizedString("Export", comment: "Export"), action: #selector(self.exportMenuAction(_:)))
            menuItems.append(exportMenuItem)
        }
        
        let deleteMenuItem = UIMenuItem(title: NSLocalizedString("Delete", comment: "Delete"), action: #selector(deleteMenuAction(_:)))
        menuItems.append(deleteMenuItem)
        
        theMenu.menuItems = menuItems
    }
    
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        var returnvalue = false
        if action == #selector(self.deleteMenuAction(_:)) {
            returnvalue = true
            
        } else if action == #selector(self.recordMenuAction(_:)) {
            returnvalue = true
        }
        else if action == #selector(self.stopRecordMenuItem(_:)) {
            returnvalue = true
        }
        else if action == #selector(self.playMenuAction(_:)) {
            returnvalue = true
        }
        else if action == #selector(self.pausePlayMenuItem(_:)) {
            returnvalue = true
        }
        else if action == #selector(self.exportMenuAction(_:)) {
            returnvalue = true
        }
        
        return returnvalue
    }
    
    //MARK: - Menu Action
    
    @objc private func deleteMenuAction(_ sender: Any?) {
        guard let audioannotation = self.annotation as? FTAudioAnnotation else {
            return
        }
        let audioSession = FTAudioSessionManager.sharedSession()?.activeSession()
        if(audioannotation.recordingModel == audioSession?.audioRecording) {
            audioSession?.resetSession();
        }
        self.delegate?.annotationControllerDidRemoveAnnotation(self, annotation: self.annotation)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTAudioSessionAskedToRemovePlayerNotification),
                                        object: audioannotation.recordingModel)
        track("Audio_Delete", params: [:], screenName: FTScreenNames.audio)
    }
    
    @objc private func recordMenuAction(_ sender: Any?) {
        FTPermissionManager.isMicrophoneAvailable(onViewController: self) { [weak self] (success) in
            if(success) {
                self?.processActionForType(FTAudioSessionDidStartRecording)
            }
        }
        track("Audio_Record", params: [:], screenName: FTScreenNames.audio)
    }
    
    @objc private func stopRecordMenuItem(_ sender: Any?) {
        processActionForType(FTAudioSessionDidStopRecording)
        track("Audio_Record_Stop", params: [:], screenName: FTScreenNames.audio)
    }
    
    @objc private func playMenuAction(_ sender: Any?) {
        processActionForType(FTAudioSessionDidStartPlayback)
         track("Audio_Play", params: [:], screenName: FTScreenNames.audio)
    }
    
    @objc private func pausePlayMenuItem(_ sender: Any?) {
        processActionForType(FTAudioSessionDidPausePlayback)
        track("Audio_Pause", params: [:], screenName: FTScreenNames.audio)
    }
    
    @objc private func exportMenuAction(_ sender: Any?) {
        track("Audio_Export", params: [:], screenName: FTScreenNames.audio)
        guard let audioannotation = self.annotation as? FTAudioAnnotation else {
            return
        }
        let audioSession = FTAudioSessionManager.sharedSession()?.activeSession()
        if(audioannotation.recordingModel == audioSession?.audioRecording) {
            audioSession?.resetSession();
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTAudioAnnotationExportNotification), object: nil, userInfo: ["annotation" : self.annotation, "frame" : NSValue.init(cgRect: self.view.frame)])
    }
    
    private func processActionForType(_ type : FTAudioSessionEvent) {
        guard let annotation = self.annotation as? FTAudioAnnotation else {
            return
        }
        isMenuVisible = false
        let audioSession = FTAudioSessionManager.sharedSession()?.activeSession()
        switch type {
        case FTAudioSessionDidStartRecording:
            if audioSession?.audioSessionState() == AudioSessionState.statePlaying {
                audioSession?.stopPlayback()
            }
            audioSession?.setAudioRecordingModel(annotation.recordingModel, for: self.view.window);
            audioSession?.startRecording()
        case FTAudioSessionDidStopRecording:
            audioSession?.stopRecording()
        case FTAudioSessionDidStartPlayback:
            if audioSession?.audioSessionState() == AudioSessionState.stateRecording {
                audioSession?.stopRecording()
            }
            audioSession?.setAudioRecordingModel(annotation.recordingModel, for: self.view.window);
            audioSession?.startPlayback()
        case FTAudioSessionDidPausePlayback:
            audioSession?.pausePlayback()
        default:
            break
        }
    }
}

//MARK:- Touch Delegate
extension FTAudioAnnotationViewController {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let superview = self.view.superview else {
            return
        }
        dragged = false
        
        if let pt = touches.first?.location(in: superview) {
            if self.view.frame.contains(pt) {
                canDrag = true
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let superview = self.view.superview else {
            return
        }
        if let pt = touches.first?.location(in: superview) {
            if canDrag {
                _ = updateFrame(pt)
                dragged = true
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.view.superview != nil else {
            return
        }
        canDrag = false
//        if let pt = touches.first?.location(in: superview) {
//            if !self.view.frame.contains(pt) {
////                deselectAnnotation()
//            } else {
//                self.handleAnnotationChanges()
//            }
//        }
        dragged = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.view.superview != nil else {
            return
        }
        canDrag = false
        dragged = false
        
//        if let pt = touches.first?.location(in: superview) {
//            if !self.view.frame.contains(pt) {
////                deselectAnnotation()
//            } else {
//                self.handleAnnotationChanges()
//            }
//        }
    }
    
    func updateFrame(_ inPoint : CGPoint) -> Bool {
        guard let superview = self.view.superview else {
            return false
        }
        var canPlace = false
        self.view.center = inPoint
        if superview.bounds.contains(self.view.frame) {
            canPlace = true
        } else {
            var newRect = self.view.frame
            if newRect.origin.x < 0 {
                newRect.origin.x = 0
            }
            if newRect.origin.y < 0 {
                newRect.origin.y = 0
            }
            if self.view.frame.origin.x > superview.frame.size.width - newRect.size.width {
                newRect.origin.x = superview.frame.size.width - newRect.size.width
            }

            if self.view.frame.origin.y > superview.frame.size.height - newRect.size.height {
                newRect.origin.y = superview.frame.size.height - newRect.size.height
            }
            
            self.view.frame = newRect
        }
        return canPlace
    }
}

//MARK:- Audio
private extension FTAudioAnnotationViewController {
    
    func sessionManagerStartRecoding() {
        guard let annotation = self.annotation as? FTAudioAnnotation else {
            return
        }
        let audioSession = FTAudioSessionManager.sharedSession()?.activeSession()
        if audioSession?.sessionID() == annotation.recordingModel.fileName {
            if audioSession?.audioSessionState() == AudioSessionState.statePlaying
            || audioSession?.audioSessionState() == AudioSessionState.stateRecording {
                return
            }
        }
        let hasAudioRecording = hasAudioFiles()
        if hasAudioRecording {
            if annotation.recordingModel.isCurrentAudioRecording() {
                audioSession?.stopRecording()
            }
            audioSession?.setAudioRecordingModel(annotation.recordingModel, for: self.view.window);
            audioSession?.startPlayback()
        } else {
            if audioSession?.audioSessionState() == AudioSessionState.stateRecording {
                audioSession?.stopRecording()
            }
            audioSession?.setAudioRecordingModel(annotation.recordingModel, for: self.view.window);
            audioSession?.startRecording()

        }
    }
}

//MARK: - FTAnnotationEditControllerInterface
extension FTAudioAnnotationViewController : FTAnnotationEditControllerInterface {
    
    var supportOrientationChanges: Bool {
        return true
    }
    
    func endEditingAnnotation() {
        handleAnnotationChanges()
        showMenu(false)
    }
    
    func refreshView() {
        let currentScale = self.delegate?.contentScale() ?? 1;
        let newFrameToSet = CGRect.scale(self.annotation.boundingRect, currentScale);
        self.updateContentFrame(newFrameToSet)
    }
    
    func saveChanges() {
        handleAnnotationChanges()
    }
    
    func isPointInside(_ point: CGPoint, fromView: UIView) -> Bool {
        return self.view.frame.contains(point)
    }
    
    func processEvent(_ eventType: FTProcessEventType,at point:CGPoint) {
        let states = self.state(forEvent: eventType)
        
        if states.contains(.select) {
            isSelected = true
        }
        
        if states.contains(.edit) {
            sessionManagerStartRecoding()
        }
        
        if states.contains(.showMenu) {
            showMenu(true)
        }
        
        if states.contains(.hideMenu) {
            showMenu(false)
        }
    }
    func updateViewToCurrentScale(fromScale : CGFloat) {
        
    }
    
    func annotationControllerLongPressDetected() {
        
    }
}

#if targetEnvironment(macCatalyst)
extension FTAudioAnnotationViewController: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let annotation = self.annotation as? FTAudioAnnotation else {
            return nil
        }
        var menuItems = [UIAction]()

        let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
            if let model = annotation.recordingModel , model.isCurrentAudioRecording() {
                let stopRecord = UIAction(title: NSLocalizedString("StopRecord", comment: "Stop Recording")) { [weak self] _ in
                    self?.stopRecordMenuItem(nil)
                }
                menuItems.append(stopRecord)
            } else {
                let record = UIAction(title: NSLocalizedString("Record", comment: "Record")) { [weak self] _ in
                    self?.recordMenuAction(nil)
                }
                menuItems.append(record)
            }
            if self.hasAudioFiles() {
                if annotation.recordingModel.isCurrentAudioPlaying() {
                    let pause = UIAction(title: NSLocalizedString("Pause", comment: "Pause")) { [weak self] _ in
                        self?.pausePlayMenuItem(nil)
                    }
                    menuItems.append(pause)
                } else {
                    let play = UIAction(title: NSLocalizedString("Play", comment: "Play")) { [weak self] _ in
                        self?.playMenuAction(nil)
                    }
                    menuItems.append(play)
                }
                
                let export = UIAction(title: NSLocalizedString("Export", comment: "Export")) { [weak self] _ in
                    self?.exportMenuAction(nil)
                }
                menuItems.append(export)
            }
            let delete = UIAction(title: NSLocalizedString("Delete", comment: "Delete")) { [weak self] _ in
                self?.deleteMenuAction(nil)
            }
            delete.attributes = .destructive;
            menuItems.append(delete)
            
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: menuItems)
        }
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
        return config
    }
}
#endif
