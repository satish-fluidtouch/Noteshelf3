//
//  EraseViewController.swift
//  EditImage
//
//  Created by Matra on 11/05/18.
//  Copyright © 2018 Matra. All rights reserved.
//

import UIKit

protocol EraseViewControllerDelegate: AnyObject {
    func didStartErasing(_viewController : EraseViewController, withTouch touch:UITouch)
    func eraserDidMove(_viewController : EraseViewController, withTouch touch:UITouch)
    func didEndErasing(_viewController : EraseViewController, withTouch touch:UITouch)
}

class EraseViewController: UIViewController {

    var firstTouch: Bool!
    weak var delegate: EraseViewControllerDelegate?
    
    open override func loadView() {
        let contentView = UIView()
        contentView.backgroundColor = UIColor.clear
        view = contentView
    }
    
    class func addToViewController(viewController: UIViewController,  delegate : EraseViewControllerDelegate , frame: CGRect ) -> UIViewController{
        let controller = EraseViewController()
        controller.delegate = delegate
        controller.view.frame = frame
        viewController.view.addSubview(controller.view)
        viewController.addChild(controller)
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UIView Touch Delegate
    override open func touchesBegan(_ touches: Set<UITouch>,
                                    with event: UIEvent?) {
        if let touch = touches.first {
            firstTouch = true
            if self.delegate != nil {
                self.delegate?.didStartErasing(_viewController: self, withTouch: touch)
            }
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>,
                                    with event: UIEvent?) {
        if let touch = touches.first {
            if firstTouch {
                firstTouch = false
            }

            if self.delegate != nil {
                self.delegate?.eraserDidMove(_viewController: self, withTouch: touch)
            }
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>,
                                    with event: UIEvent?) {
        if let touch = touches.first {
//            if !firstTouch {
                if self.delegate != nil {
                    self.delegate?.didEndErasing(_viewController: self , withTouch: touch)
                }
//            }
        }
    }

}
