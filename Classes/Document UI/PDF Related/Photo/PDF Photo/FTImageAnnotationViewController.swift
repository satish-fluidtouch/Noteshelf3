//
//  FTImageEditerViewController.swift
//  Noteshelf
//
//  Created by Amar on 17/05/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

import MobileCoreServices

 class FTImageAnnotationViewController: FTImageResizeViewController {
    
    weak var delegate: FTAnnotationEditControllerDelegate?

    private var scale : CGFloat = 1;
    
    private var _annotation: FTAnnotation?
    private var annotationMode: FTAnnotationMode = FTAnnotationMode.create
    
    var annotation: FTAnnotation {
        return _annotation!;
    }
    
    var supportOrientationChanges : Bool {
        return true
    }
    
    required init?(withAnnotation annotation: FTAnnotation,
                  delegate: FTAnnotationEditControllerDelegate?,
                  mode: FTAnnotationMode)
    {
        guard let imgAnnotation = annotation as? FTImageAnnotation, let image = imgAnnotation.image else { return nil }
        super.init(withImage: image)
        self._annotation = annotation
        self.annotationMode = mode
        self.delegate = delegate
        self.photoMode = .normal
        self.view.autoresizingMask = [UIView.AutoresizingMask.init(rawValue: 0)];
        self.allowsEditing = imgAnnotation.allowsEditing
        self.allowsResizing = imgAnnotation.allowsResize            
        self.allowsLocking = imgAnnotation.allowsLocking

        self.view.transform = imgAnnotation.imageTransformMatrix
        let contentScale = delegate?.contentScale() ?? CGFloat(1);
        let frame = CGRectScale(annotation.boundingRect, contentScale)
        self.updateContentFrame(frame)
        #if targetEnvironment(macCatalyst)
        let contextMenu = UIContextMenuInteraction.init(delegate: self)
        self.view.addInteraction(contextMenu)
        #else
//        showMenu(true)
        #endif
        
        NotificationCenter.default.addObserver(forName: Notification.Name.didUpdateAnnotationNotification,
                                               object: annotation,
                                               queue: nil) { [weak self] (notification) in
            self?.refreshView();
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(withImage image: UIImage) {
        fatalError("init(withImage:) has not been implemented")
    }
    
    private func handleAnnotationChanges(){
        
        guard let annotation = self.annotation as? FTImageAnnotation else {
            return;
        }
        let undoableInfo = annotation.undoInfo();
        let rect: CGRect = self.contentFrame()
        let scale: CGFloat = self.delegate?.contentScale() ?? 1;
        let oneByZoom: CGFloat = 1/scale;
        
        annotation.version = FTImageAnnotation.defaultAnnotationVersion();
        annotation.boundingRect = CGRectScale(rect, oneByZoom)
        annotation.imageTransformMatrix = self.view.transform
        annotation.image = self.contentImageView?.image
        _annotation = annotation
        
        if(self.annotationMode == FTAnnotationMode.create) {
            self.delegate?.annotationControllerDidAddAnnotation(self, annotation: self.annotation)
            self.annotationMode = FTAnnotationMode.edit
        }
        else {
            self.delegate?.annotationControllerDidChange(self,undoableInfo: undoableInfo);
        }
    }
     
     private func updateClipAnnotation(with img: UIImage, clipUrlString: String) {
         guard let annotation = self.annotation as? FTWebClipAnnotation else {
             return;
         }
         let undoableInfo = annotation.undoInfo();
         let rect: CGRect = self.contentFrame()
         let scale: CGFloat = self.delegate?.contentScale() ?? 1;
         let oneByZoom: CGFloat = 1/scale;
         
         annotation.version = FTImageAnnotation.defaultAnnotationVersion();
         annotation.boundingRect = CGRectScale(rect, oneByZoom)
         annotation.imageTransformMatrix = self.view.transform
         annotation.image = img
         annotation.clipString = clipUrlString
         _annotation = annotation
         
         if(self.annotationMode == FTAnnotationMode.create) {
             self.delegate?.annotationControllerDidAddAnnotation(self, annotation: self.annotation)
             self.annotationMode = FTAnnotationMode.edit
         }
         else {
             self.delegate?.annotationControllerDidChange(self,undoableInfo: undoableInfo);
         }
     }
    
    override func deleteAnnotation() {
        // When we edit->delete->undo the annotation, refresh rect is not correct, hence updating rect.
        let rect: CGRect = self.contentFrame()
        let scale: CGFloat = self.delegate?.contentScale() ?? 1;
        let oneByZoom: CGFloat = 1/scale;
        annotation.boundingRect = CGRectScale(rect, oneByZoom)
        self.delegate?.annotationControllerDidRemoveAnnotation(self, annotation: self.annotation)
    }

    override func lockAnnotation() {
        self.annotation.isLocked = true
        endEditingAnnotation()
        self.delegate?.annotationControllerDidCancel(self)
    }
    
    override func copyAnnotation() {
        let pasteboard = UIPasteboard.general
        // To have proviosion of pasting the image outside application
        do {
            self.annotation.copyMode = true
            let annotationData = try NSKeyedArchiver.archivedData(withRootObject: self.annotation, requiringSecureCoding: false)
            self.annotation.copyMode = false
            var pbInfo: [String: Any] = [String: Any]()
            pbInfo[UIPasteboard.pdfAnnotationUTI()] = annotationData
            if let imgAnnotation = self.annotation as? FTImageAnnotation, let image = imgAnnotation.image {
                pbInfo[kUTTypePNG as String] = image;
            }
            pasteboard.items = [pbInfo];
        }
        catch {
            print("error description: \(error.localizedDescription)")
        }
    }
    
    override func cutAnnotation() {
        self.copyAnnotation()
        self.delegate?.annotationControllerDidRemoveAnnotation(self, annotation: self.annotation)
    }
    
    override func moveAnnotationToFront() {
        self.delegate?.moveAnnotationToFront(self.annotation)
    }
    
    override func moveAnnotationToBack() {
        self.delegate?.moveAnnotationToBack(self.annotation)
    }
     
     override func editWebClip() {
         guard let topVC = self.view.window?.visibleViewController else { return }
         guard let clipUrlStr = (annotation as? FTWebClipAnnotation)?.clipString else { return }
         FTWebClipViewController.showWebClip(overViewController: topVC,defaultURLString: clipUrlStr, withDelegate: self)
     }

    //MARK: - display image editor
    override func displayEditImageView(_ image: UIImage?) {
        
        let storyboard = UIStoryboard(name: "EditImage", bundle: nil)
        let editImageController = storyboard.instantiateInitialViewController() as? EditImageRootViewController
        editImageController?.initialImage = image
        editImageController?.delegate = self
        editImageController?.modalPresentationStyle = .overFullScreen
        let topController: UIViewController? = self.view.window?.visibleViewController
        if let editImageController = editImageController {
            topController?.present(editImageController, animated: true)
        }
    }

     private func reset() {
        if let superview = self.view.superview {
            let contentScale = delegate?.contentScale() ?? CGFloat(1);
            var frame = sourceImage.aspectFrame(withinScreenArea: superview.frame, zoomScale: contentScale)
            frame = frame.integral
            self.updateContentFrame(frame)
        }
        perform(#selector(showControlPoints(animate:)), with: false, afterDelay: 0.5)
    }
    

    //MARK: - Gesture
    override func doubleTapGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        FTCLSLog("Image Edit Enter (tap): \(NSCoder.string(for: sourceImage.size))")
        displayEditImageView(sourceImage)
    }
}

//MARK: - EditImageDelegate
extension FTImageAnnotationViewController : EditImageDelegate {
    func didCancelEditing(_ viewController: EditImageRootViewController) {
        FTCLSLog("Image Cancel Editing")
        self.showControlPoints(animate: true)
    }
    
    func didEndEditing(_ viewController: EditImageRootViewController, withImage finalImage: UIImage) {
        FTCLSLog("Image End Editing: image size: \(NSCoder.string(for: finalImage.size))")
        if !sourceImage.size.equalTo(finalImage.size) {
            sourceImage = finalImage;
            let center: CGPoint = self.view.center
            reset()
            self.view.center = center
        } else {
            sourceImage = finalImage;
        }
        self.contentImageView?.image = finalImage
        showControlPoints(animate: true)
    }
}


//MARK: - FTAnnotationEditControllerInterface
extension FTImageAnnotationViewController : FTAnnotationEditControllerInterface {
    
    func endEditingAnnotation() {
        handleAnnotationChanges()
        showMenu(false)
    }
    
    func refreshView() {
        let currentTransform = self.view.transform
        if let imgAnnotation = self.annotation as? FTImageAnnotation {
            self.view.transform = imgAnnotation.imageTransformMatrix
            let currentFrame = self.view.frame;
            let currentScale = self.delegate?.contentScale() ?? 1;
            let newFrameToSet = CGRect.scale(self.annotation.boundingRect, currentScale);
            if newFrameToSet.integral != currentFrame.integral
                || currentTransform != imgAnnotation.imageTransformMatrix {
                self.updateContentFrame(newFrameToSet)
            }
        }
    }
    
    func saveChanges() {
        handleAnnotationChanges()
    }
    
    func isPointInside(_ point: CGPoint, fromView: UIView) -> Bool {
        let newPoint = self.view.convert(point, from: fromView)
        return self.isPointInside(newPoint)
    }
    
    private func convertedViewFrame(_ frame: CGRect) -> CGRect {
        let contentOffset = (self.delegate?.visibleRect().origin ?? .zero)
        let newOriginPoint = CGPointTranslate(frame.origin, contentOffset.x, contentOffset.y)
        return CGRect(origin: newOriginPoint, size: frame.size)
    }
    
    func processEvent(_ eventType : FTProcessEventType,at point:CGPoint)
    {
        
    }

    func updateViewToCurrentScale(fromScale : CGFloat) {
        if let del = self.delegate, del.contentScale() != fromScale {
            var currentFrame = self.contentFrame();
            currentFrame = CGRectScale(currentFrame, 1/fromScale);

            let newFrame = CGRectScale(currentFrame, del.contentScale());
            self.updateContentFrame(newFrame);
        }
    }
    
    func annotationControllerLongPressDetected() {
        showMenu(true)
    }
}

extension FTImageAnnotationViewController: FTWebClipControllerDelegate {
    func didCaptureScreenShot(screenShot: UIImage?, clipUrlString: String?) {
        if let img = screenShot {
            self.contentImageView?.image = img
           updateClipAnnotation(with: img, clipUrlString: clipUrlString ?? webClipDefaultURL)
        }
    }
}


#if !targetEnvironment(macCatalyst)
extension FTImageAnnotationViewController {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        var canPerform = super.canPerformAction(action, withSender: sender)
        if action == #selector(editClipAnnotation(_:)) {
            if let annot = self.annotation as? FTWebClipAnnotation {
                if !annot.clipString.isEmpty {
                    canPerform = true
                }
            }
        }
        
        if action ==  #selector(editMenuAction(_:)) {
            if let annot = self.annotation as? FTWebClipAnnotation {
                if !annot.clipString.isEmpty {
                    canPerform = false
                }
            }
        }
        return canPerform
    }
}
#endif

#if targetEnvironment(macCatalyst)
extension FTImageAnnotationViewController {
    func canPerformAction(_ selector: Selector) -> Bool {
        if [#selector(self.copy(_:)),
            #selector(self.cut(_:)),
            #selector(self.delete(_:))
        ].contains(selector) {
            return true;
        }
        return false;
    }
    
    func performAction(_ selector: Selector) {
        if #selector(self.copy(_:)) == selector {
            self.copyAnnotation();
        }
        else if #selector(self.cut(_:)) == selector {
            self.cutAnnotation();
        }
        else if #selector(self.delete(_:)) == selector {
            self.deleteAnnotation()
        }
    }
}
#endif
