//
//  CropViewController.swift
//  EditImage
//
//  Created by Matra on 15/05/18.
//  Copyright © 2018 Matra. All rights reserved.
//

import UIKit

protocol CropViewDelegate: AnyObject {
    func didBeganCroping(_viewcontroller:CropViewController)
    func didChangedCropRect(_viewcontroller:CropViewController, toRect rect: CGRect)
}

class CropViewController: UIViewController {

    @IBOutlet weak var maskView: UIView!
    fileprivate let cropRectView = CropView()
    fileprivate let minWidth: CGFloat = 100.0
    fileprivate let minHeight: CGFloat = 100.0
    var imageRect: CGRect! {
        didSet{
            createAddCropView()
        }
    }
    weak var delegate: CropViewDelegate?
    let cropContainerView = UIView()
    
    class func addToViewController(viewController: UIViewController,  delegate : CropViewDelegate , frame: CGRect, imageRect: CGRect) -> UIViewController{
        let controller = UIStoryboard(name: "EditImage", bundle: nil).instantiateViewController(withIdentifier: "CropViewController") as! CropViewController
        controller.delegate = delegate
        controller.imageRect = imageRect
        controller.view.frame = frame
        viewController.view.addSubview(controller.view)
        viewController.addChild(controller)
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        maskView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        maskView.isUserInteractionEnabled = false
        // Do any additional setup after loading the view.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cropBlurMask(cropRectView.frame)
    }
    //MARK:- crop view added
    func createAddCropView()  {
        cropContainerView.frame = imageRect
        cropContainerView.backgroundColor = .clear
        cropRectView.delegate = self
        cropRectView.frame = imageRect
        cropRectView.keepAspectRatio = false
        cropRectView.cropWindowBounds = CGRect(x: 0, y: 0, width: imageRect.size.width, height: imageRect.size.height)
        if cropRectView.superview == nil {
            self.view.addSubview(cropContainerView)
            self.view.addSubview(cropRectView)
        }
//        cropBlurMask(cropRectView.frame)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    //MARK: CropContainer
    fileprivate func cappedCropRectInImageRectWithRect(_ rectView: CropView) -> CGRect {
        var cropRect = rectView.frame
        let rect = rectView.bounds
        if cropRect.minX < cropContainerView.frame.minX {
            cropRect.origin.x = cropContainerView.frame.minX
            let cappedWidth = rect.maxX
            let height = !rectView.keepAspectRatio ? cropRect.size.height : cropRect.size.height * (cappedWidth / cropRect.size.width)
            cropRect.size = CGSize(width: cappedWidth, height: height)
        }
        
        if cropRect.minY < cropContainerView.frame.minY {
            cropRect.origin.y = cropContainerView.frame.minY
            let cappedHeight = rect.maxY
            let width = !rectView.keepAspectRatio ? cropRect.size.width : cropRect.size.width * (cappedHeight / cropRect.size.height)
            cropRect.size = CGSize(width: width, height: cappedHeight)
        }
        
        if cropRect.minX > cropContainerView.frame.maxX - minWidth {
            cropRect.origin.x = cropContainerView.frame.maxX - minWidth
            
        }
        if cropRect.maxX > cropContainerView.frame.maxX {
            let cappedWidth = cropContainerView.frame.maxX - cropRect.minX
            let height = !rectView.keepAspectRatio ? cropRect.size.height : cropRect.size.height * (cappedWidth / cropRect.size.width)
            cropRect.size = CGSize(width: cappedWidth, height: height)
        }
        
        if cropRect.minY > cropContainerView.frame.maxY - minHeight {
            cropRect.origin.y = cropContainerView.frame.maxY - minHeight
            
        }
        if cropRect.maxY > cropContainerView.frame.maxY {
            let cappedHeight = cropContainerView.frame.maxY - cropRect.minY
            let width = !rectView.keepAspectRatio ? cropRect.size.width : cropRect.size.width * (cappedHeight / cropRect.size.height)
            cropRect.size = CGSize(width: width, height: cappedHeight)
        }
            
        return cropRect
    }
    

}
//MARK:- CropRectViewDelegate
extension CropViewController: CropRectViewDelegate {
    func cropRectViewDidBeginEditing(_ view: CropView) {
        cropBlurMask(view.frame)
    }
    
    func cropRectViewDidChange(_ view: CropView) {
        self.delegate?.didBeganCroping(_viewcontroller: self)
       cropRectView.frame = cappedCropRectInImageRectWithRect(view)
        cropBlurMask(cropRectView.frame)
    }
    
    func cropRectViewDidEndEditing(_ view: CropView) {
        let newRect = self.view.convert(cropRectView.frame, to: cropContainerView)
        self.delegate?.didChangedCropRect(_viewcontroller: self, toRect: newRect)
    }
    
    func cropBlurMask(_ frame: CGRect){
        CATransaction.begin();
        CATransaction.setDisableActions(true);
        let frameValue = frame
        let path = UIBezierPath(roundedRect: frameValue, cornerRadius: 0)
        path.append(UIBezierPath(rect: self.maskView.bounds))
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.path = path.cgPath
        self.maskView.layer.mask = maskLayer
        self.view.layoutIfNeeded()
        CATransaction.commit()
    }
    
}
