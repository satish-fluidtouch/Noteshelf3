//
//  EditImageRootViewController.swift
//  EditImage
//
//  Created by Matra on 11/05/18.
//  Copyright © 2018 Matra. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol EditImageDelegate: AnyObject {
    func didCancelEditing(_ viewController : EditImageRootViewController)
    func didEndEditing(_ viewController : EditImageRootViewController, withImage finalImage: UIImage)
}

@objcMembers class EditImageRootViewController: UIViewController {

    private var viewSize : CGSize = .zero;
    
    //MARK: - Outlets
    @IBOutlet weak var editImageView: UIImageView?
    @IBOutlet weak var toolBarView: UIView!
    @IBOutlet weak var baseView: UIView?
    @IBOutlet weak var optionBarView: UIView!
    
    //MARK:- Constraint Outlets
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    
    
    //MARK: - Properties
    var optionViewController : EditImageOptionBarViewController?
    var toolBarViewController : EditImageToolBarViewController?
    var initialImage: UIImage?
    var currentOperation :FTImageEditOperation = .none {
        didSet{
            
        }
    }
    let minSize: CGFloat = 100.0
    var displayedController: UIViewController?
    weak var delegate : EditImageDelegate?
    fileprivate var editWindowRect : CGRect!
    fileprivate var cropScale : CGFloat = 1.0
    fileprivate var croppedImage : UIImage!
    fileprivate var currentlyEditingImage = false
    fileprivate var madeChangesToImage = false
    fileprivate var patternColor: UIColor = UIColor.init(patternImage: UIImage(named: "checks")!)
    fileprivate var canCropImage = true
    
    let editOperation = EditImageOperation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentOperation = .crop
        NotificationCenter.default.addObserver(self, selector: #selector(self.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        configureUI()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        currentlyEditingImage = false
        if let controller = self.displayedController as? LassoViewController {
            controller.removeLassoSelection()
        }
    }
    
    @objc func rotated() {
        optionViewController?.canCrop = false
//        self.editImageView.backgroundColor = .clear
//        setEditImageViewFrame(true)
//        {
//            if let controller = self.displayedController as? CropViewController {
//                controller.imageRect = self.editWindowRect
//            }
//        }
        
        imageSizeToImageView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.editImageView?.image == nil && self.initialImage != nil{
            self.editImageView?.backgroundColor = .clear
            self.editImageView?.image = self.initialImage
           
            self.editWindowRect = self.editImageView?.frame
            editOperation.initializeWithImage((self.editImageView?.image!)!)
            
        }
        #if targetEnvironment(macCatalyst)
        if(viewSize != self.view.frame.size) {
            viewSize = self.view.frame.size;
            imageSizeToImageView()
        }
        #else
        imageSizeToImageView()
        #endif
    }

    
    func configureUI() {
        // Add bottom tool bar
        toolBarViewController = EditImageToolBarViewController.addToViewController(viewController: self, delegate: self, containerView: toolBarView) as? EditImageToolBarViewController

        // Add option bar
        optionViewController = EditImageOptionBarViewController.addToViewController(viewController: self, delegate: self, containerView: optionBarView) as? EditImageOptionBarViewController

    }
  
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setEditImageViewFrame(true)
    }
    

    func changeMode(_ mode: FTImageEditOperation) {
        FTCLSLog("Image: Operation \(mode.rawValue)")
       if currentlyEditingImage {
        if mode == currentOperation { return}
        else {
            FTCLSLog("Image: Asked user to apply changes")
            askUserToApplyChanges(mode)
            }
        }else{
            currentOperation = mode
            setEditImageViewFrame(true)
        }
    }
    
    func askUserToApplyChanges(_ mode: FTImageEditOperation) {
        weak var weakself = self
        let alertViewController = UIAlertController(title: nil , message: NSLocalizedString("SaveImageChangesConfirmation", comment: "Would you like to apply the changes to the image before proceeding to another option?") , preferredStyle: .alert);
        alertViewController.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "No"), style: .default, handler: { (_) in
            if mode == .none {
                weakself?.dismissAndSendBackImage()
            }else{
                weakself?.currentlyEditingImage = false
                weakself?.currentOperation = mode
                weakself?.setEditImageViewFrame(true)
            }
        }));
        alertViewController.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Yes"), style: .default, handler: { (_) in
            weakself?.currentlyEditingImage = false
            if weakself?.currentOperation == .crop {
                weakself?.currentOperation = mode
                weakself?.cropResizeImageIfNeeded()
            } else if weakself?.currentOperation == .erase {
                if mode == .none {
                    weakself?.dismissAndSendBackImage()
                }else{
                    weakself?.currentOperation = mode
                    weakself?.setEditImageViewFrame(true)
                }
            } else{
                if let controller = weakself?.displayedController as? LassoViewController {
                    weakself?.currentOperation = mode
                    controller.finilizeLassoChanges()
                }
            }
        }));
        self.present(alertViewController, animated: true, completion: nil);
    }
    
    //MARK:- Switch ViewController
    func switchToController() {
        
        switch currentOperation {
        case .crop:
            if canCropImage , let baseView = self.baseView {
                displayedController = CropViewController.addToViewController(viewController: self, delegate: self, frame: baseView.frame, imageRect: editWindowRect)
            }
        case .erase:
            if let baseView = self.baseView , let image = self.editImageView?.image {
                configureManagerForMode(mode: .erase, image: image)
                displayedController = EraseViewController.addToViewController(viewController: self, delegate: self, frame: baseView.bounds)
            }
        case .lasso:
            if canCropImage, let baseView = self.baseView {
                displayedController = LassoViewController.addToViewController(viewController: self, delegate: self, frame: baseView.bounds, and: editWindowRect)
            }
        default:
            break
        }
    }
    
    
    // MARK: - Make OperationManager
    func configureManagerForMode(mode: FTImageEditOperation, image : UIImage!){
        
        editOperation.initializeToMode(mode: .erase, with: image)
        
    }
    
    //MARK: - Image view frame
    // lasso
    func resizeAndCropImageForLassoSelection(with offset: CGPoint,andpath path : CGPath) {
        var selectedRect = path.boundingBoxOfPath
        selectedRect = selectedRect.offsetBy(dx: offset.x, dy: offset.y)
        if selectedRect.origin.x < 0 {
            selectedRect.origin.x = 0
        }
        if selectedRect.origin.y < 0 {
            selectedRect.origin.y = 0
        }
        let lastImage = self.editImageView?.image
        let smallImage = lastImage?.crop(rect: selectedRect, withscaleWidth: (editImageView?.bounds.width)!, scaleHeight: (editImageView?.bounds.height)!)
        editImageView?.image = editOperation.cropImageForSelectedPath(path, image: smallImage, boundingBox: selectedRect, lassoOffset: offset)
        if currentOperation == .none {
            dismissAndSendBackImage()
        }else{
            setEditImageViewFrame(true)
        }
    }
    //Cropping
    func cropResizeImageIfNeeded()  {
        let lastImage = self.editImageView?.image
        let newImage = lastImage?.crop(rect: editWindowRect, withscaleWidth: (editImageView?.bounds.width)!, scaleHeight: (editImageView?.bounds.height)!)
        self.editImageView?.image = newImage
        editOperation.addCroppedImage(newImage!)

        optionViewController?.canCrop = ((newImage?.size.width)! > CGFloat(10.0) && (newImage?.size.height)! > CGFloat(10.0)) ? true : false
        currentlyEditingImage = false
        if currentOperation == .none {
            dismissAndSendBackImage()
        }else{
            setEditImageViewFrame(true)
        }
    }

    func setEditImageViewFrame(_ animated : Bool, completion: (() -> Void)? = nil) {
        optionViewController?.editMode = currentOperation
        if animated {
            removeTopController()
        }

        if animated {
            self.imageSizeToImageView()
            self.switchToController()
            completion?()
        }else {
            imageSizeToImageView()
            completion?()
        }
    }

    func imageSizeToImageView() {
        if let editingImage = editImageView?.image, let baseView = self.baseView {
            let maxRectForImage = CGRect(x: 20, y: baseView.frame.minY, width: (baseView.bounds.width) - 40, height: (baseView.bounds.height) - 40)
            let rect = AVMakeRect(aspectRatio: editingImage.size, insideRect: (maxRectForImage))
            let newframe = CGRect(x: (baseView.bounds.width - rect.size.width)/2, y: (baseView.bounds.height - rect.size.height)/2, width: rect.size.width, height: rect.size.height)
            editWindowRect = newframe
            if let controller = displayedController as? CropViewController {
                controller.imageRect = editWindowRect
            } else if let controller = displayedController as? LassoViewController {
                controller.view.frame = baseView.frame
                controller.cropWindowRect = editWindowRect
            } else if let controller = displayedController as? EraseViewController {
                controller.view.frame = baseView.frame
            }
            self.editImageView?.clipsToBounds = true;
            
            self.imageViewWidthConstraint.constant = rect.size.width
            self.imageViewHeightConstraint.constant = rect.size.height
            self.view.layoutIfNeeded()
            
            editImageView?.backgroundColor = patternColor
        }
    }
    
    fileprivate func cappedCropRectInImageRectWithRect(_ rect: CGRect) -> CGRect {
        var cropRect = rect
        let rect = CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height)
        if cropRect.minX < 0 {
            cropRect.origin.x = 0
            let cappedWidth = rect.maxX
            let height = cropRect.size.height
            cropRect.size = CGSize(width: cappedWidth, height: height)
        }
        
        if cropRect.minY < 0 {
            cropRect.origin.y = 0
            let cappedHeight = rect.maxY
            let width = cropRect.size.width
            cropRect.size = CGSize(width: width, height: cappedHeight)
        }
        
        return cropRect
    }
    
    func frameForMinCroppingWithRect(_ rect: CGRect) -> CGRect{
        let lastImage = self.editImageView?.image
        let newImage = lastImage?.crop(rect: rect, withscaleWidth: (editImageView?.bounds.width)!, scaleHeight: (editImageView?.bounds.height)!)
        var frame = rect
        if (newImage?.size.width)! < minSize {
            let newWidth = ((editImageView?.bounds.width)! * minSize) / (lastImage?.size.width)!
            frame.size.width = newWidth
        }
        if (newImage?.size.height)! < minSize {
            let newHeight = ((editImageView?.bounds.height)! * minSize) / (lastImage?.size.height)!
            frame.size.height = newHeight
        }
        
        let newRect = CGRect(x: rect.origin.x - (frame.size.width - rect.size.width), y: rect.origin.y - (frame.size.height - rect.size.height), width: frame.size.width, height: frame.size.height)
        
        return cappedCropRectInImageRectWithRect(newRect)
    }
    //MARK:- Remove top controller
    func removeTopController() {
        if displayedController != nil {
            optionViewController?.canCrop = false
            displayedController?.view.removeFromSuperview()
            displayedController?.removeFromParent();
        }
    }
    
    func dismissEditView() {
        editOperation.resetEditedImages(initialImage: nil)
        #if targetEnvironment(macCatalyst)
            self.dismiss(animated: true) {
                self.delegate?.didCancelEditing(self)
            }
        #else
        self.delegate?.didCancelEditing(self)
        self.dismiss(animated: true, completion: nil)
        #endif
    }
    
    func dismissAndSendBackImage() {
        #if targetEnvironment(macCatalyst)
            self.dismiss(animated: true) {
                self.delegate?.didEndEditing(self, withImage: (self.editImageView?.image!)!)
            }
        #else
        self.delegate?.didEndEditing(self, withImage: (editImageView?.image!)!)
        dismissEditView()
        #endif
    }
}

//MARK: - OptionBarDelegate
extension EditImageRootViewController : OptionBarDelegate {
    
    func canUndo() -> Bool {
        return self.editOperation.canUndo
    }
    
    func canRedo() -> Bool {
        return self.editOperation.canRedo
    }
    
    func didSelectOptionReset(_viewController: EditImageOptionBarViewController) {
        currentlyEditingImage = false
        madeChangesToImage = false
        self.editImageView?.image = self.initialImage
        editOperation.resetEditedImages(initialImage: self.initialImage!)
//        configureManagerForMode(mode: currentOperation , image: editImageView.image)
        setEditImageViewFrame(false) {
            if let controller = self.displayedController as? CropViewController {
                controller.imageRect = self.editWindowRect
            }else if let controller = self.displayedController as? LassoViewController {
                controller.removeLassoSelection()
            }
        }
    }
    
    func didSelectOptionCrop(_viewController: EditImageOptionBarViewController) {
        currentlyEditingImage = false
        if currentOperation == .crop {
            cropResizeImageIfNeeded()
        }else{
            if let controller = displayedController as? LassoViewController {
                controller.finilizeLassoChanges()
            }
        }
    }
    
    func didSelectOptionUndo(_viewController: EditImageOptionBarViewController) {
        editImageView?.image = editOperation.undo()
        optionViewController?.updateUndoRedo()
        setEditImageViewFrame(false) {
            if let controller = self.displayedController as? CropViewController {
                controller.imageRect = self.editWindowRect
            }
        }
        currentlyEditingImage = false
    }
    
    func didSelectOptionRedo(_viewController: EditImageOptionBarViewController) {
        editImageView?.image = editOperation.redo()
        optionViewController?.updateUndoRedo()
        setEditImageViewFrame(false) {
            if let controller = self.displayedController as? CropViewController {
                controller.imageRect = self.editWindowRect
            }
        }
        currentlyEditingImage = false
    }
    
}

//MARK: - ToolBarDelegate
extension EditImageRootViewController : ToolBarDelegate {
    
    func didSelectCancel(_viewController: EditImageToolBarViewController) {
        dismissEditView()
    }
    
    func didSelectCrop(_viewController: EditImageToolBarViewController) {
        
        changeMode(.crop)
    }
    
    func didSelectErase(_viewController: EditImageToolBarViewController) {
        changeMode(.erase)
    }
    
    func didSelectLasso(_viewController: EditImageToolBarViewController) {
        changeMode(.lasso)
    }
    
    func didSelectDone(_viewController: EditImageToolBarViewController) {
        if !madeChangesToImage {
            dismissEditView()
        }else{
            if !currentlyEditingImage {
                dismissAndSendBackImage()
            }else{
                askUserToApplyChanges(.none)
            }
        }
    }
    
}

//MARK: - EraseViewControllerDelegate
extension EditImageRootViewController : EraseViewControllerDelegate {
    
    func didStartErasing(_viewController: EraseViewController, withTouch touch: UITouch) {
        optionViewController?.enableReset = true
        madeChangesToImage = true
        FTCLSLog("Image: Erase Started")
    }
    
    func eraserDidMove(_viewController: EraseViewController, withTouch  touch: UITouch){
        self.editImageView?.image = editOperation.touchPoints(touch: touch, onImage: (editImageView?.image!)!, endEditing: false, rect: (editImageView?.frame)!)
    }
    
    func didEndErasing(_viewController: EraseViewController, withTouch touch: UITouch) {
        self.editImageView?.image = editOperation.touchPoints(touch: touch, onImage: (editImageView?.image!)!, endEditing: true, rect: (editImageView?.frame)!)
        optionViewController?.updateUndoRedo()
        FTCLSLog("Image: Erase Ended")
    }

}

//MARK:- CropViewDelegate
extension EditImageRootViewController: CropViewDelegate {
    func didChangedCropRect(_viewcontroller: CropViewController, toRect rect: CGRect) {
        if canCropImage{
            
            editWindowRect = frameForMinCroppingWithRect(rect)
            madeChangesToImage = true
            optionViewController?.canCrop = true
            currentlyEditingImage = true
            if self.currentOperation == .crop {
                self.cropResizeImageIfNeeded()
                optionViewController?.updateUndoRedo()
            }
        }
    }
    
    func didBeganCroping(_viewcontroller: CropViewController) {
        FTCLSLog("Image: Crop Began")
        optionViewController?.enableReset = true

    }
    
   
    
}

//MARK: - LassoViewDelegate
extension EditImageRootViewController : LassoViewDelegate {
    func lassoViewDidStartSelection(_ viewController: LassoViewController) {
        madeChangesToImage = true
        optionViewController?.canCrop = true
        currentlyEditingImage = true
        FTCLSLog("Image: Lasso Started")
    }
    
    func lassoViewDidSelectedPath(_ path: CGPath, with offset: CGPoint, _viewController: LassoViewController) {
        optionViewController?.canCrop = false
        resizeAndCropImageForLassoSelection(with: offset,andpath: path)
    }
    
    func lassoViewRemovedSelection(_ viewController: LassoViewController) {
        currentlyEditingImage = false
        FTCLSLog("Image: Lasso Ended")
    }
}
