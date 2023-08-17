//
//  EditViewController.swift
//  ImageScanner
//
//  Created by Prabhu on 7/28/17.
//  Copyright © 2017 FluidTouch. All rights reserved.
//

import UIKit
import Vision
import AVKit

struct Quadrilateral {
    var topLeft:CGPoint!
    var topRight:CGPoint!
    var bottomLeft:CGPoint!
    var bottomRight:CGPoint!
    
    init(tl:CGPoint = CGPoint.zero,tr:CGPoint = CGPoint.zero,bl:CGPoint = CGPoint.zero,br:CGPoint = CGPoint.zero) {
        self.topLeft = tl
        self.topRight = tr
        self.bottomLeft = bl
        self.bottomRight = br
    }
    
    init(ob:VNRectangleObservation) {
        self.topLeft = ob.topLeft
        self.topRight = ob.topRight
        self.bottomLeft = ob.bottomLeft
        self.bottomRight = ob.bottomRight
    }
    
    
    func transformedToViewSpace(orientation:UIImage.Orientation) -> Quadrilateral {
        let transForm = transformForImageSpace(imageOrientation: orientation)
        return applyTransForm(transForm: transForm)
    }
    
    func transformedToImageSpace(orientation:UIImage.Orientation) -> Quadrilateral {
        let transForm = transformForViewSpace(imageOrientation: orientation)
        return applyTransForm(transForm: transForm)
    }
    
    private func applyTransForm(transForm:CGAffineTransform) -> Quadrilateral {
        let newTopLeft = topLeft.applying(transForm)
        let newTopRight = topRight.applying(transForm)
        let newBottomLeft = bottomLeft.applying(transForm)
        let newBottomRight = bottomRight.applying(transForm)
        return Quadrilateral(tl: newTopLeft, tr: newTopRight, bl: newBottomLeft, br: newBottomRight)
    }
    
    private func transformForImageSpace(imageOrientation:UIImage.Orientation) -> CGAffineTransform {
        var rectTransform:CGAffineTransform
        switch imageOrientation {
        case .left:
            rectTransform = CGAffineTransform(rotationAngle: 90.degreesToRadians).translatedBy(x: 0, y: -1)
            break;
        case .right:
            rectTransform = CGAffineTransform(rotationAngle: -90.degreesToRadians).translatedBy(x: -1, y: 0)
            break;
        case .down:
            rectTransform = CGAffineTransform(rotationAngle: -180.degreesToRadians).translatedBy(x: -1, y: -1)
            break;
        default:
            rectTransform = CGAffineTransform.identity
        }
        return rectTransform
    }
    
    private  func transformForViewSpace(imageOrientation:UIImage.Orientation) -> CGAffineTransform {
        var transForm:CGAffineTransform
        switch imageOrientation {
        case .left:
            transForm = CGAffineTransform(rotationAngle: -90.degreesToRadians).translatedBy(x: -1, y: 0)
        case .right:
            transForm = CGAffineTransform(rotationAngle: 90.degreesToRadians).translatedBy(x: 0, y: -1)
        case .down:
            transForm = CGAffineTransform(rotationAngle: -180.degreesToRadians).translatedBy(x: -1, y: -1)
        default:
            transForm = CGAffineTransform.identity
        }
        return transForm
    }    
}
protocol EditViewControllerProtocol : AnyObject {
    func keepScan(item:ScannedItem)
    func updateScanControllerFor(mode newMode:ScanControllerMode)
    func deleteCurrentSelectedItem()
}

class EditViewController: UIViewController {
    
    var scannedItem:ScannedItem!
    
    @IBOutlet weak var imageHolderView:UIImageView!
    @IBOutlet weak var cropOverLay:CropOverLayView!
    @IBOutlet weak var blurView:UIView!
    @IBOutlet weak var retakeButton:UIButton!
    @IBOutlet weak var keepScanButton:UIButton!
    
    weak var delegate:EditViewControllerProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageHolderView.image = scannedItem.image
        self.cropOverLay.scannedItem  = scannedItem
        self.cropOverLay.cropOverlayDelegate = self
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.retakeButton.setTitle(NSLocalizedString("RetakeKey", comment: "Retake"), for: .normal)
        self.keepScanButton.setTitle(NSLocalizedString("KeepScanKey", comment: "Keep Scan"), for: .normal)
        // Do any additional setup after loading the view.
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews();
    }
    
    override func viewDidLayoutSubviews() {
        //For orientation changes
        super.viewDidLayoutSubviews();
        
        if let scannedItem = self.cropOverLay.scannedItem {
            let r = AVMakeRect(aspectRatio: scannedItem.image.size, insideRect: self.view.frame)
            self.cropOverLay.frame = r
        }
        self.cropOverLay.setNeedsDisplay();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension EditViewController {
    @IBAction func retakeButtonAction(sender:Any) {
        self.delegate?.updateScanControllerFor(mode: ScanControllerMode.retakeScan)
        self.dismiss(animated: true)
    }
    
    @IBAction func deleteButtonAction() {
        self.dismiss(animated: true) {
            self.delegate?.deleteCurrentSelectedItem()
        }
    }
}

protocol CropImageProtocol : AnyObject {
    func cropImage(with quad:Quadrilateral)
    func isSelectionQuadInterSectingBottomBar(btns:[UIView]) -> Bool
    func hideBottomBar(isHidden:Bool,animated:Bool)
    func filteredImage(item:ScannedItem)
}

extension EditViewController: CropImageProtocol {
    func cropImage(with quad: Quadrilateral) {
    }
    func isSelectionQuadInterSectingBottomBar(btns:[UIView]) -> Bool {
        var isIntersecting:Bool = false
        for btn in btns {
            if true == btn.frame.intersects(self.blurView.frame) {
                isIntersecting = true
                break
            }
        }
        return isIntersecting
    }
    func hideBottomBar(isHidden:Bool,animated:Bool) {
        if isHidden == true && blurView.isHidden == false {
            if animated {
                UIView.animate(withDuration: 0.4, animations: {
                    self.blurView.isHidden = true
                })
            }
            else {
                self.blurView.isHidden = true
            }
        }
        else if isHidden == false && blurView.isHidden == true {
            if animated {
                UIView.animate(withDuration: 0.4, animations: {
                    self.blurView.isHidden = false
                })
            }
            else {
                self.blurView.isHidden = false
            }
        }
    }
    func filteredImage(item:ScannedItem) {
        self.dismiss(animated: true) {
            self.delegate?.keepScan(item: item)
        }
    }
}


class CropOverLayView: UIView {
    var topLeftCircle:UIView! = {
        let v = UIView()
        v.backgroundColor = UIColor.clear
        v.frame = CGRect(origin: .zero, size: CGSize(width: 24, height: 24))
        v.layer.borderWidth = 2
        
        
        v.layer.borderColor = UIColor.appColor(.accent).cgColor
        v.layer.cornerRadius = v.bounds.width / 2
        return v
    }()
    var topRightCircle:UIView! = {
        let v = UIView()
        v.frame = CGRect(origin: .zero, size: CGSize(width: 24, height: 24))
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.appColor(.accent).cgColor
        v.layer.cornerRadius = v.bounds.width / 2
        return v
    }()

    var bottomLeftCircle:UIView! = {
        let v = UIView()
        v.frame = CGRect(origin: .zero, size: CGSize(width: 24, height: 24))
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.appColor(.accent).cgColor
        v.layer.cornerRadius = v.bounds.width / 2
        return v
    }()

    var bottomRightCircle:UIView! = {
        let v = UIView()
        v.frame = CGRect(origin: .zero, size: CGSize(width: 24, height: 24))
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.appColor(.accent).cgColor
        v.layer.cornerRadius = v.bounds.width / 2
        return v
    }()
    
    var btns:[UIView] = []
    var curView:UIView?
    var start:CGPoint?
    var end:CGPoint?
    fileprivate var _scannedItem:ScannedItem!
    var scannedItem:ScannedItem! {
        get {
            return _scannedItem
        }
        set {
            _scannedItem = newValue
            
        }
    }
    weak var cropOverlayDelegate:CropImageProtocol?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        topLeftCircle.center = CGPoint.zero
        topRightCircle.center = CGPoint.zero
        bottomLeftCircle.center = CGPoint.zero
        bottomRightCircle.center = CGPoint.zero
        btns=[topLeftCircle,topRightCircle,bottomLeftCircle,bottomRightCircle]
        btns.forEach { (btn) in
            addSubview(btn)
        }
        self.backgroundColor = UIColor.clear
//        self.alpha = 1
//        self.layer.mask = self.shapeLyer
    }
    
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.move(to: topLeftCircle.center)
        context.addLine(to: topRightCircle.center)
        context.addLine(to: bottomRightCircle.center)
        context.addLine(to: bottomLeftCircle.center)
        context.addLine(to: topLeftCircle.center)
        context.addRect(CGRect.infinite)
        context.clip(using: CGPathFillRule.evenOdd)
        UIColor.black.withAlphaComponent(0.2).setFill();
        context.fill(self.bounds);
        
        
        context.move(to: topLeftCircle.center)
        context.addLine(to: topRightCircle.center)
        context.addLine(to: bottomRightCircle.center)
        context.addLine(to: bottomLeftCircle.center)
        context.addLine(to: topLeftCircle.center)

        context.setStrokeColor(UIColor.appColor(.accent).cgColor)
        context.setLineWidth(3)
        context.strokePath()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        
        let q = scannedItem.quad.transformedToViewSpace(orientation: scannedItem.image.imageOrientation)
        let r = self.frame;
//        let r = AVMakeRect(aspectRatio: scannedItem.image.size, insideRect: self.frame)

        topLeftCircle.center = CGPoint(x: q.topLeft.x * r.width, y: q.topLeft.inverted().y * r.height)
        topRightCircle.center = CGPoint(x: q.topRight.x * r.width, y: q.topRight.inverted().y * r.height)
        bottomLeftCircle.center = CGPoint(x: q.bottomLeft.x * r.width, y: q.bottomLeft.inverted().y * r.height)
        bottomRightCircle.center = CGPoint(x: q.bottomRight.x * r.width, y: q.bottomRight.inverted().y * r.height)
        
        #if DEBUG
        debugPrint("top left : \(topLeftCircle.center)")
        debugPrint("top Right : \(topRightCircle.center)")
        debugPrint("Bottom left : \(bottomLeftCircle.center)")
        debugPrint("Bottom right : \(bottomRightCircle.center)")
        debugPrint("View frame : \(self.frame)")
        #endif
    }

    fileprivate func selectedBtn(point:CGPoint) -> UIView? {
        var minDist:Float = Float.greatestFiniteMagnitude
        curView = btns.first
        btns.forEach { (view) in
            let distance = view.center.distanceTo(p: point)
            if  fabsf(distance) < fabsf(minDist) {
                curView = view
                minDist = distance
            }
//            print("Min dist : \(minDist) distance:\(distance)")
        }
        return curView
    }
    
    fileprivate func handleBlurViewVisibility() {
        if let cropDel = self.cropOverlayDelegate ,cropDel.isSelectionQuadInterSectingBottomBar(btns: btns) {
            cropDel.hideBottomBar(isHidden: true, animated: true)
        }
        else {
            self.cropOverlayDelegate?.hideBottomBar(isHidden: false, animated: true)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        Array(touches).forEach { (touch) in
            let touchPt = touch.location(in: self)
            curView = selectedBtn(point: touchPt)
            start = touchPt
            #if DEBUG
            debugPrint("touchPt :\(touchPt)")
            #endif
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        Array(touches).forEach { (touch) in
            let touchPt = touch.location(in: self)
            let d:CGPoint = CGPoint(x: touchPt.x - start!.x, y: touchPt.y - start!.y)
            let c = curView!.center
            let p = CGPoint(x: c.x + d.x, y: c.y + d.y)
            if self.bounds.contains(p) {
                curView!.center = p
                start = touchPt
                handleBlurViewVisibility()
                self.setNeedsDisplay()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        Array(touches).forEach { (touch) in
            let touchPt = touch.location(in: self)
            let d:CGPoint = CGPoint(x: touchPt.x - start!.x, y: touchPt.y - start!.y)
            let c = curView!.center
            let p = CGPoint(x: c.x + d.x, y: c.y + d.y)
            if self.bounds.contains(p) {
                curView!.center = p
                start = touchPt
                self.setNeedsDisplay()
                self.cropOverlayDelegate?.hideBottomBar(isHidden: false, animated: true)
            }
            #if DEBUG
            debugPrint("EndPt :\(touchPt)")
            #endif
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
}

extension CGPoint {
    func unitConverted(to size:CGSize) -> CGPoint {
        return CGPoint(x: self.x/size.width, y: self.y/size.height)
    }
}
extension CropOverLayView {
    @IBAction func keepScanButtonAction(sender:Any?) {
        let s = self.bounds.size
        let quad = Quadrilateral(tl: topLeftCircle.center.unitConverted(to: s).inverted(),
                                 tr: topRightCircle.center.unitConverted(to: s).inverted(),
                                 bl: bottomLeftCircle.center.unitConverted(to: s).inverted(),
                                 br: bottomRightCircle.center.unitConverted(to: s).inverted())
        scannedItem.quad =  quad.transformedToImageSpace(orientation: scannedItem.image.imageOrientation)
        self.cropOverlayDelegate?.filteredImage(item: scannedItem!)
    }
}

extension CIImage {
    func croppedImage(with q:Quadrilateral, orientation:UIImage.Orientation) -> UIImage? {
        let rectCoords = NSMutableDictionary(capacity: 4)
        rectCoords["inputTopLeft"] = CIVector(cgPoint:q.topLeft)
        rectCoords["inputTopRight"] = CIVector(cgPoint:q.topRight)
        rectCoords["inputBottomLeft"] = CIVector(cgPoint:q.bottomLeft)
        rectCoords["inputBottomRight"] = CIVector(cgPoint:q.bottomRight)
        let filtered = self.applyingFilter("CIPerspectiveCorrection", parameters: (rectCoords as? [String : Any])!)
        let context = CIContext(options: nil)
        guard let cgimage = context.createCGImage(filtered, from: filtered.extent) else {
            #if DEBUG
            debugPrint("Error in generateing CGImage")
            #endif
            return nil
        }

        let uiImage = UIImage(cgImage: cgimage, scale: 2.0, orientation: orientation)
        return uiImage
    }
    
    //Converts quad from view coordinatepsce to image coordinate space.
    func convertToImageCoordinateSpace(q:Quadrilateral) -> Quadrilateral {
        let tl = CGPoint(x: self.extent.width * q.topLeft.x, y: self.extent.height * (q.topLeft.y))
        let tr = CGPoint(x: self.extent.width * q.topRight.x, y: self.extent.height * (q.topRight.y))
        let bl = CGPoint(x: self.extent.width * q.bottomLeft.x, y: self.extent.height * (q.bottomLeft.y))
        let br = CGPoint(x: self.extent.width * q.bottomRight.x, y: self.extent.height * (q.bottomRight.y))

        return Quadrilateral(tl: tl, tr: tr, bl: bl, br: br)
    }
}

