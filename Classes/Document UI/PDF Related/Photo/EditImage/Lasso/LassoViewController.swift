//
//  LassoViewController.swift
//  EditImage
//
//  Created by Matra on 29/05/18.
//  Copyright © 2018 Matra. All rights reserved.
//

import UIKit

protocol LassoViewDelegate: AnyObject {
    func lassoViewDidStartSelection(_ viewController : LassoViewController)
    func lassoViewDidSelectedPath(_ path: CGPath, with offset: CGPoint , _viewController: LassoViewController)
    func lassoViewRemovedSelection(_ viewController : LassoViewController)
}

class LassoViewController: UIViewController {
    
    weak var delegate: LassoViewDelegate?
    var cropWindowRect : CGRect! {
        didSet {
            addLassoView()
        }
    }
    var lassoView: FTLassoSelectionView?
    let cropContainerView = UIView()
    var lassoOffset = CGPoint.zero
    var lassoPath : CGPath?

    class func addToViewController(viewController: UIViewController,  delegate : LassoViewDelegate , frame: CGRect , and cropWindowRect: CGRect) -> UIViewController{
        let controller = LassoViewController()
        controller.delegate = delegate
        controller.cropWindowRect = cropWindowRect
        controller.view.frame = frame
        viewController.view.addSubview(controller.view)
        viewController.addChild(controller)
        return controller
    }
    
    open override func loadView() {
        let contentView = UIView()
        contentView.backgroundColor = UIColor.clear
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
       removeLassoSelection() 
    }
    @objc  func rotated() {
        removeLassoSelection() 
    }
    
    func addLassoView() {
        if lassoView == nil {
            cropContainerView.backgroundColor = .clear
            self.view.addSubview(cropContainerView)
            lassoView = FTLassoSelectionView.init(frame: cropContainerView.bounds)
            lassoView?.selectionMode = .imageEdit;
            lassoView?.editingImage = true;
            lassoView?.delegate = self
            lassoView?.isUserInteractionEnabled = true;
            lassoView?.autoresizingMask = [.flexibleWidth , .flexibleHeight]
            self.cropContainerView.addSubview(lassoView!)
        }
        cropContainerView.frame = cropWindowRect
        lassoView?.frame = cropContainerView.bounds
        
    }

    func removeLassoSelection() {
        lassoView?.finalizeMove()
    }
    
    func finilizeLassoChanges()  {
        if let path = lassoPath {
            self.delegate?.lassoViewDidSelectedPath(path, with: lassoOffset, _viewController: self)
        }
        lassoView?.finalizeMove()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

//MARK: - LassoSelectionViewDelegate
extension LassoViewController : FTLassoSelectionViewDelegate {
    
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView, selectionAreaMovedByOffset offset: CGPoint) {
        lassoOffset = CGPoint(x: lassoOffset.x + offset.x, y: lassoOffset.y + offset.y)
    }
    
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView, initiateSelection cutPath: CGPath) {
        self.delegate?.lassoViewDidStartSelection(self)
        lassoPath = cutPath
    }
    
    func lassoSelectionViewFinalizeMoves(_ lassoSelectionView: FTLassoSelectionView) {
        lassoOffset = CGPoint.zero
        lassoPath = nil
        self.delegate?.lassoViewRemovedSelection(self)
    }
    
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView, perform action: FTLassoAction) {
        
    }
    
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView, canPerform action: FTLassoAction) -> Bool {
        return false;
    }
}
