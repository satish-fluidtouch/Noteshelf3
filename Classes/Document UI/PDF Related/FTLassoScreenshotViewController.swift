//
//  FTLassoScreenshotViewController.swift
//  Noteshelf
//
//  Created by Matra on 15/05/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTLassoScreenshotViewController: UIViewController, FTCustomPresentable {

    override var shouldAvoidDismissOnSizeChange: Bool {
        return true;
    }
    var customTransitioningDelegate: FTCustomTransitionDelegate = FTCustomTransitionDelegate(with: .presentation)
    
    @IBOutlet fileprivate weak var screenshotImageView: UIImageView?
    var screenshot: UIImage?
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let image = screenshot else {
            return
        }
        screenshotImageView?.image = image
        // Do any additional setup after loading the view.
    }


    @IBAction func shareClicked(_ sender: UIButton) {
        guard let image = screenshot else {
            return
        }
        
        let items = [image]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        activityVC.popoverPresentationController?.sourceView = self.view
        activityVC.popoverPresentationController?.sourceRect = sender.frame
        activityVC.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if completed {
                self.dismiss(animated: true, completion: nil)
            }
        }
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func closeClicked(_ sender: Any) {
        let poppedController = self.navigationController?.popViewController(animated: true)
        if nil == poppedController {
            self.dismiss(animated: true, completion: nil)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
