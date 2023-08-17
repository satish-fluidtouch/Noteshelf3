//
//  FTTextInputBaseViewController.swift
//  Noteshelf
//
//  Created by Matra on 3/9/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTextInputBaseViewController: UIViewController , UIPopoverPresentationControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // 08/03/2018
    //MARK:- Presentation
    class func showAsPopover(fromViewController viewController: UIViewController,
                             withSourceView sourceView: UIView,
                             andSourceRect sourceRect: CGRect,
                             withDelegate delegate: FTInputCustomFontColorPickerDelegate) -> UIViewController {
        let storyboard = UIStoryboard.init(name: "FTTextInputUI", bundle: nil);
        let controller = storyboard.instantiateViewController(withIdentifier: "FTInputCustomFontView") as! FTInputCustomFontViewController;

        if viewController.isRegularClass() {
            let navigationController = UINavigationController.init(rootViewController: controller)
            navigationController.isNavigationBarHidden = true
            navigationController.modalPresentationStyle = .popover;
            let popoverPresentationController = navigationController.popoverPresentationController;
            popoverPresentationController?.sourceView = sourceView;
            popoverPresentationController?.sourceRect = sourceRect
            popoverPresentationController?.backgroundColor = UIColor.blue;
            popoverPresentationController?.permittedArrowDirections = .down
            viewController.present(navigationController, animated: true)
        }
        else{
            controller.modalPresentationStyle = .custom;
            controller.transitioningDelegate = controller.customTransitioningDelegate
            let popoverPresentationController = controller.popoverPresentationController;
            popoverPresentationController?.sourceView = sourceView;
            popoverPresentationController?.sourceRect = sourceRect;
            popoverPresentationController?.backgroundColor = UIColor.white;
            popoverPresentationController?.permittedArrowDirections = .down
            viewController.present(controller, animated: true)
            
        }
        return controller;
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

}
