//
//  ScanViewController.swift
//  ImageScanner
//
//  Created by Prabhu on 7/28/17.
//  Copyright © 2017 FluidTouch. All rights reserved.
//

import UIKit
import Vision
import FTCommon
import AVFoundation

#if !targetEnvironment(macCatalyst)
protocol FTScanDocumentDelegate : NSObjectProtocol{
    func scanDocumentDidFinish(_ viewController : ScanViewController, withFileUrl fileURL: URL);
    func scanDocumentDidCancel(_ viewController : ScanViewController);
}
#endif

enum ScanControllerMode {
    case newScan
    case retakeScan
}

extension CGPoint {
    func inverted() -> CGPoint {
        return CGPoint(x: self.x, y: 1 - self.y)
    }
    func distanceTo(p:CGPoint) -> Float {
        let p1 = p
        let p2 = self
        return hypotf(Float(p1.x - p2.x),Float(p1.y - p2.y))
    }
}

class ScannedItem : NSObject {
    var isEditing:Bool=false
    var image:UIImage!
    var croppedImage:UIImage! {
        return _croppedImage
    }
    var quad:Quadrilateral! {
        didSet {
            _croppedImage = self.getCroppedImage().fixOrientation().imageByRemovingShadows()
        }
    }
    fileprivate var _croppedImage:UIImage?

    
    init(image:UIImage,quad:Quadrilateral) {
        super.init()
        self.image = image
        self.quad = quad
    }
    fileprivate func getCroppedImage() -> UIImage {
        let ciimage = CIImage(image:image)
        let q =  ciimage!.convertToImageCoordinateSpace(q: quad)
        let filteredImage = ciimage!.croppedImage(with: q, orientation: image.imageOrientation)
        return filteredImage!
    }
}

//MARK: ScanViewController
#if !targetEnvironment(macCatalyst)
class ScanViewController: UIViewController {

    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var cameraView:UIView!
    @IBOutlet weak var noCameraView:UIView!
    @IBOutlet weak var lblNotAvailable:UILabel!
    weak var scanDelegate : FTScanDocumentDelegate?;

    @IBOutlet weak var saveButton:UIButton!
    @IBOutlet weak var cancelButton:UIButton!
    @IBOutlet weak var collectionView:UICollectionView!
    @IBOutlet weak var collectionViewFlowLayOut:UICollectionViewFlowLayout!
    @IBOutlet weak var flashButton:UIButton!
    
    var arScannedItems:[ScannedItem] = [ScannedItem]()
    fileprivate var selectedItem:ScannedItem?
    
    lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video),
            let input = try? AVCaptureDeviceInput(device: backCamera) else {
                return session
        }
        session.addInput(input)
        return session
    }()
    fileprivate  var cameraOutput:AVCapturePhotoOutput!
    fileprivate lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    fileprivate let handler = VNSequenceRequestHandler()
    lazy var parallelograView:ParalleloGramView  = {
        let view = ParalleloGramView(frame: CGRect.zero)
        view.alpha = 0.5
        view.backgroundColor = .clear
        return view
    }()
    fileprivate var scanMode:ScanControllerMode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.scanMode = ScanControllerMode.newScan
        self.lblNotAvailable.text=NSLocalizedString("ScannerUnavailable", comment: "Document scanner needs full scrieen")
        NotificationCenter.default.addObserver(self, selector: #selector(ScanViewController.handleCameraStartsRunning), name: NSNotification.Name.AVCaptureSessionDidStartRunning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ScanViewController.handleCameraStopsRunning), name: NSNotification.Name.AVCaptureSessionDidStopRunning, object: nil)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:Int(kCVPixelFormatType_32BGRA)]
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "queue"))
        captureSession.addOutput(output)
        cameraOutput = AVCapturePhotoOutput.init()
        
        if captureSession.canAddOutput(cameraOutput) {
            captureSession.addOutput(cameraOutput)
        }
        captureSession.sessionPreset = AVCaptureSession.Preset.photo;
        captureSession.startRunning()
        
        cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraView.layer.addSublayer(cameraLayer)
        cameraView.addSubview(parallelograView)
        
        // Do any additional setup after loading the view.
        collectionViewFlowLayOut.scrollDirection = .horizontal
        collectionView.dataSource = self
        collectionView.delegate = self
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .clear
        saveButton.layer.cornerRadius = saveButton.bounds.height / 2
        saveButton.layer.backgroundColor = UIColor(red: 14/255, green: 205/255, blue: 235/255, alpha: 1).cgColor
        
        flashButton.setImage(UIImage(named: "flashIcon"), for: .selected)
        flashButton.isSelected = false
        
        saveButton.setTitle(NSLocalizedString("SaveKey", comment: "Save"), for: .normal)
        cancelButton.setTitle(NSLocalizedString("CancelKey", comment: "Cancel"), for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        self.selectedItem=nil
        self.checkForPermission();
    }

    @objc func handleCameraStartsRunning()
    {
        self.noCameraView.isHidden=true
    }
    
    @objc func handleCameraStopsRunning()
    {
        self.noCameraView.isHidden=false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    fileprivate func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        cameraLayer.frame = cameraView.bounds
        parallelograView.frame = cameraView.bounds
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let connection =  self.cameraLayer.connection  {
            #if DEBUG
            debugPrint("Video orientation \(connection.videoOrientation.rawValue)")
            #endif
            let orientation: UIInterfaceOrientation = self.view.window?.ftStatusBarOrientation ?? .unknown
            if connection.isVideoOrientationSupported {
                switch (orientation) {
                case .portrait:
                    updatePreviewLayer(layer: connection, orientation: .portrait)
                case .landscapeRight:
                    updatePreviewLayer(layer: connection, orientation: .landscapeRight)
                case .landscapeLeft:
                    updatePreviewLayer(layer: connection, orientation: .landscapeLeft)
                case .portraitUpsideDown:
                    updatePreviewLayer(layer: connection, orientation: .portraitUpsideDown)
                default:
                    updatePreviewLayer(layer: connection, orientation: .portrait)
                }
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    fileprivate func handleRects(_ request: VNRequest, error: Error?, buff:CVImageBuffer) {
        if request.results?.count==0 {
            DispatchQueue.main.sync {
                self.parallelograView.isHidden=true
            }
            #if DEBUG
            debugPrint("Count: 0")
            #endif
            return
        }
        #if DEBUG
        debugPrint("Count: %d",request.results?.count ?? 0)
        #endif
        DispatchQueue.main.sync {
            self.parallelograView.isHidden=false
        }
        DispatchQueue.main.async {
            let newRectObserVation=(request.results as! [VNRectangleObservation]).last!
            self.parallelograView.topLeft = self.cameraLayer.layerPointConverted(fromCaptureDevicePoint: newRectObserVation.topLeft.inverted())
            self.parallelograView.topRight = self.cameraLayer.layerPointConverted(fromCaptureDevicePoint: newRectObserVation.topRight.inverted())
            self.parallelograView.bottomLeft = self.cameraLayer.layerPointConverted(fromCaptureDevicePoint: newRectObserVation.bottomLeft.inverted())
            self.parallelograView.bottomRight = self.cameraLayer.layerPointConverted(fromCaptureDevicePoint: newRectObserVation.bottomRight.inverted())
            
            self.parallelograView.refreshScannedRectangle()
        }
    }
    
    fileprivate func presentEditViewController(item:ScannedItem) {
        let editController = UIStoryboard(name: "Scanner", bundle: nil).instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        editController.scannedItem = item
        editController.delegate = self
        editController.modalPresentationStyle = .custom
        editController.modalTransitionStyle = .crossDissolve
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
            self.present(editController, animated: true)
        }
    }
    
    fileprivate func animateCroppedImagePostEdit(_ item:ScannedItem, to destRect:CGRect) {
        let image = item.croppedImage!
        let imageView = UIImageView.init(frame: self.parallelograView.overlayLayer.frame)
        imageView.frame=CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: image.size.width/2, height: image.size.height/2))
        imageView.contentMode = .scaleAspectFit
        imageView.image=image
        self.view.addSubview(imageView)
        
        var centre = self.view.center
        centre.y = centre.y - 100
        imageView.center = centre

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            imageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (success) in
            UIView.animate(withDuration: 0.4, delay: 0.4, options: .curveEaseIn, animations: {
                imageView.frame = destRect
            }) { (success) in
                imageView.removeFromSuperview()
            }
        }
        
        self.takePhotoButton.isEnabled = true
    }
    
    fileprivate func updateSaveButton() {
        if self.arScannedItems.count > 0 {
            let title = "\(NSLocalizedString("SaveKey", comment: "Save")) (\(self.arScannedItems.count))"
            self.saveButton.isHidden=false
            self.saveButton.setTitle(title, for: .normal)
        }
        else {
            self.saveButton.isHidden=true
            self.saveButton.setTitle("Save", for: .normal)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] (ctx) in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        })
    }
}

//MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension ScanViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let request = VNDetectRectanglesRequest { (request, error) in
            self.handleRects(request, error: error, buff: pixelBuffer)
        }
        request.minimumAspectRatio=0.2
        do {
            try handler.perform([request], on: pixelBuffer)
        }
        catch{
            #if DEBUG
            debugPrint(error)
            #endif
        }
    }
}

//MARK: outlet actions
extension ScanViewController {
    @IBAction  func takePhotoButtonAction(sender:Any) {
//        takePhoto = true
        self.takePhotoButton.isEnabled = false
        FTCLSLog("UI: Take Photo-Scan");
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.__availablePreviewPhotoPixelFormatTypes.first
        
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType!,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
            ] as [String : Any]
        settings.previewPhotoFormat = previewFormat
        if(cameraOutput.__supportedFlashModes.contains(NSNumber.init(value: Int8(AVCaptureDevice.FlashMode.on.rawValue))))
        {
            if flashButton.isSelected {
                settings.flashMode = .on
            }
            else {
                settings.flashMode = .off
            }
        }
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }

    @IBAction func flashButtonAction(sender:Any) {
        flashButton.isSelected = !flashButton.isSelected
    }
    
    @IBAction func cancelButtonAction(sender:Any?) {
        self.takePhotoButton.isEnabled = true
        FTCLSLog("UI: Cancel Scan Button");

        if self.scanMode == ScanControllerMode.newScan {
            dismiss(animated: true, completion: {
                self.captureSession.stopRunning()
            })
        }
        else if scanMode == ScanControllerMode.retakeScan {
            updateScanControllerFor(mode: ScanControllerMode.newScan)
            if(nil != selectedItem) {
                //present with currently selected item
                presentEditViewController(item: selectedItem!)
            }
            else {
                if(self.arScannedItems.count == 1) {
                    self.cancelButtonAction(sender:sender);
                }
            }
        }
    }
    
    public func tempScannedNoteLocation() -> URL? {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ScannedNote.pdf")
    }

    @IBAction func saveButtonAction(sender:Any) {
        //FTActivityIndicatorView.show("Processing", in: self.view, type: FTActivityIndicatorType.progress, animated: true, cancel: nil)
        FTCLSLog("UI: Save Scanned Items Button");

        DispatchQueue.global().async {[unowned self] in
            FTPDFFileGenerator().generatePDFWithScannedItems(self.arScannedItems, atLocation: self.tempScannedNoteLocation(), completion: {
                DispatchQueue.main.async {
                    //FTActivityIndicatorView.hide(for: self.view, animated: true)
                    
                    let dest = self.tempScannedNoteLocation()
                    self.dismiss(animated: true, completion: {
                        self.captureSession.stopRunning()
                        if(self.scanDelegate != nil)
                        {
                            self.scanDelegate?.scanDocumentDidFinish(self, withFileUrl: dest!)
                        }
                    })
                }
            })
        }
    }
}

private typealias ScanViewCameraPermission = ScanViewController;
extension ScanViewCameraPermission
{
    func checkForPermission() {
        // First we check if the device has a camera (otherwise will crash in Simulator - also, some iPod touch models do not have a camera).
        let deviceHasCamera = UIImagePickerController.isSourceTypeAvailable(.camera)
        if (deviceHasCamera) {
            let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            switch authStatus {
            case .denied: alertPromptToAllowCameraAccessViaSettings()
            default: break;
            }
        } else {
            let alertController = UIAlertController(title: "Error", message: "Device has no camera", preferredStyle: .alert)
            weak var weakSelf : ScanViewCameraPermission? = self;
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                weakSelf?.cancelButtonAction(sender: weakSelf?.cancelButton);
            });
            alertController.addAction(defaultAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func alertPromptToAllowCameraAccessViaSettings() {
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String;
        let alert = UIAlertController(title: "\"\(appName)\" Would Like To Access the Camera", message: "Please grant permission to use the Camera.", preferredStyle: .alert )
        weak var weakSelf : ScanViewCameraPermission? = self;
        alert.addAction(UIAlertAction(title: "Open Settings", style: .cancel) { alert in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil);
            weakSelf?.cancelButtonAction(sender: weakSelf?.cancelButton);
        })
        present(alert, animated: true, completion: nil)
    }
}

//MARK:- AVCapturePhotoCaptureDelegate
extension ScanViewController:AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            #if DEBUG
            debugPrint("error occured : \(error.localizedDescription)")
            #endif
        }

        guard let cgimage = photo.cgImageRepresentation() else {
            return;
        }

        #if DEBUG
        debugPrint("CGImage width: \(cgimage.width) height: \(cgimage.height)")
        #endif
        
        var targetSize = self.view.bounds.size
        if(targetSize.height > targetSize.width)
        {
            let newTargetSize = CGSize.init(width: targetSize.height, height: targetSize.width)
            targetSize = newTargetSize
        }
        let cropRect = AVMakeRect(aspectRatio: targetSize, insideRect: CGRect.init(x:0, y:0, width: CGFloat(cgimage.width), height: CGFloat(cgimage.height)))
        let croppedCGImage = cgimage.cropping(to: cropRect)!
        let ftStatusBarOrientation = self.view.window?.ftStatusBarOrientation ?? .unknown
        let orientation = self.rotationNeededForImageCapturedWithDeviceOrientation(deviceOrientation:ftStatusBarOrientation)
        let smallImage  = UIImage(cgImage: croppedCGImage, scale: 2.0, orientation: orientation)
        
        let request = VNDetectRectanglesRequest { (request, error) in
            guard let observations = request.results as? [VNRectangleObservation] else {
                return
            }
            var quad:Quadrilateral!
            var newRectObserVation:VNRectangleObservation
            if observations.count > 0 {
                newRectObserVation = observations.first!
                quad = Quadrilateral(ob: newRectObserVation)
            }
            else
            {
                let topLeft = CGPoint.init(x: 0.2, y: 0.8)
                let topRight = CGPoint.init(x: 0.8, y: 0.8)
                let bottomLeft = CGPoint.init(x: 0.2, y: 0.2)
                let bottomRight = CGPoint.init(x: 0.8, y: 0.2)
                quad = Quadrilateral.init(tl: topLeft, tr: topRight, bl: bottomLeft, br: bottomRight)
            }
                //FTActivityIndicatorView.show("Processing", in: self.view, type: FTActivityIndicatorType.progress, animated: true, cancel: nil)
                let scannedItem = ScannedItem(image: smallImage, quad: quad)
                
                if self.scanMode == ScanControllerMode.newScan {
                    self.arScannedItems.append(scannedItem)
                }
                else if self.scanMode == ScanControllerMode.retakeScan {
                    if(self.selectedItem != nil){
                        if let idx = self.arScannedItems.index(of: self.selectedItem!) {
                            self.arScannedItems[idx] = scannedItem
                        }
                    }
                    else
                    {
                        self.arScannedItems[self.arScannedItems.count-1] = scannedItem
                    }
                    self.updateScanControllerFor(mode: .newScan)

                }
                self.presentEditViewController(item: scannedItem)
                //FTActivityIndicatorView.hide(for: self.view, animated: true)
            }
            request.minimumAspectRatio=0.2
        
        do {
            try handler.perform([request], on: smallImage.cgImage!)
        }
        catch{
            #if DEBUG
            debugPrint(error)
            #endif
        }
    }
}

//MARK: UICollectionViewDelegate
extension ScanViewController:UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arScannedItems.count
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: "CroppedImageCollectionViewCellIdentifier", for: indexPath) as! CroppedImageCollectionViewCell
        cell.imageView.layer.masksToBounds = true
        cell.imageView.layer.cornerRadius = 2
        let image = self.arScannedItems[indexPath.row].croppedImage
        cell.imageView.image = image
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        FTCLSLog("UI: Tapped Scanned Item To Edit");

        self.selectedItem = self.arScannedItems[indexPath.row]
        self.selectedItem?.isEditing=true
        self.presentEditViewController(item: selectedItem!)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if self.arScannedItems.count > 0 {
            var  totCelWidth:CGFloat = 0
            self.arScannedItems.forEach { (item) in
                var size:CGSize
                if(item.croppedImage != nil)
                {
                    if item.croppedImage.size.width > item.croppedImage.size.height {
                        size =  CGSize(width: 60, height: 47)
                    }
                    else {
                        size = CGSize(width: 47, height: 60)
                    }
                    totCelWidth = totCelWidth + size.width
                }
            }
            
            let totalInterimSpace = (collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing * CGFloat(self.arScannedItems.count - 1)
            let totCollectionViewWidth = collectionView.bounds.width
            let left = (totCollectionViewWidth - (totCelWidth + totalInterimSpace)) / 2
            if left > 0 {
                return UIEdgeInsets(top: 0, left: left, bottom: 0, right: 0)
            }
            else {
                return UIEdgeInsets.zero
            }
        }
        else {
            return UIEdgeInsets.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let item = self.arScannedItems[indexPath.row].croppedImage {
            if item.size.width > item.size.height {
                return CGSize(width: 60, height: 47)
            }
            else {
                return CGSize(width: 47, height: 60)
            }
            
        }
        return CGSize.zero
    }
    
    func rotationNeededForImageCapturedWithDeviceOrientation(deviceOrientation:UIInterfaceOrientation) -> UIImage.Orientation {
        var imageOrientation:UIImage.Orientation
        switch deviceOrientation {
        case .portraitUpsideDown:
            imageOrientation = .left
            break
        case .landscapeRight:
            imageOrientation = .up
            break
        case .landscapeLeft:
            imageOrientation = .down
            break
        default:
            imageOrientation = .right
        }
        return imageOrientation
    }
}

//MARK: EditViewControllerProtocol
extension ScanViewController:EditViewControllerProtocol {
    func updateScanControllerFor(mode newMode:ScanControllerMode){
        self.takePhotoButton.isEnabled = true
        self.scanMode = newMode
        if self.scanMode == ScanControllerMode.newScan {
            self.collectionView.isHidden = false
            self.saveButton.isHidden = false
        }
        else if self.scanMode == ScanControllerMode.retakeScan {
            self.collectionView.isHidden = true
            self.saveButton.isHidden = true
        }
    }
    func keepScan(item: ScannedItem) {
        FTCLSLog("Keep Scan");

        if(item.isEditing || self.selectedItem != nil)
        {
            if let idx = self.arScannedItems.index(of: item){
                let indexPath = IndexPath(item: idx, section: 0)
                self.collectionView.reloadItems(at: [indexPath])
                self.animateItemPostEdit(item: item)
                self.selectedItem = nil
            }
        }
        else
        {
            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: [IndexPath.init(item: self.arScannedItems.count-1, section: 0)])
            }, completion: { (success) in
                self.animateItemPostEdit(item: item)
            })
        }
        self.updateSaveButton()
    }
    func animateItemPostEdit(item:ScannedItem) {
            if let idx = self.arScannedItems.index(of: item) {
                let indexPath = IndexPath(item: idx, section: 0)
                if let layoutAttr = self.collectionView.layoutAttributesForItem(at: indexPath) {
                    var frame  = layoutAttr.frame
                    frame  = self.collectionView.convert(frame, to: self.view)
                    self.animateCroppedImagePostEdit(item, to: frame)
                }
            }
        }
    func deleteCurrentSelectedItem() {
        self.takePhotoButton.isEnabled = true
        FTCLSLog("Delete Scanned Item");

        if(self.selectedItem != nil){
            if let item = self.selectedItem, let index =
                self.arScannedItems.index(of: item) {
                self.arScannedItems.remove(at: index)
            }
        }
        else
        {
            self.arScannedItems.removeLast()
        }
        self.selectedItem = nil
        self.collectionView.reloadData()
        self.updateSaveButton()
    }
}

//To create PDF file with scanned document images
extension FTPDFFileGenerator{
    func generatePDFWithScannedItems(_ items:[ScannedItem], atLocation fileURL:URL?, completion:()-> Void ) {
        if let destUrl =  fileURL {
            if FileManager.default.fileExists(atPath: destUrl.path) {
                try! FileManager.default.removeItem(atPath: destUrl.path)
            }
            var pageRect = CGRect.zero
            UIGraphicsBeginPDFContextToFile(destUrl.path, pageRect, nil)
            items.forEach({ (item) in
                if((item.croppedImage) != nil)
                {
                    pageRect = CGRect.zero
                    let imageRect = CGRect(x: 0, y: 0, width: item.croppedImage.size.width, height: item.croppedImage.size.height)
                    if(item.croppedImage.size.width > item.croppedImage.size.height) {
                        pageRect.size = aspectFittedRect(imageRect, self.deviceSpecificLandscapeDocumentRect()).size
                    }
                    else {
                        pageRect.size = aspectFittedRect(imageRect, self.deviceSpecificPortraitDocumentRect()).size
                    }
                    UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
                    if pageRect.contains(imageRect)
                    {
                        pageRect=CGRect.init(origin: CGPoint.init(x: (pageRect.size.width-imageRect.size.width)/2, y: (pageRect.size.height-imageRect.size.height)/2), size: imageRect.size)
                    }
                    item.croppedImage.draw(in: pageRect)
                }
            })
            UIGraphicsEndPDFContext()
            completion()
        }
    }
}
#endif
