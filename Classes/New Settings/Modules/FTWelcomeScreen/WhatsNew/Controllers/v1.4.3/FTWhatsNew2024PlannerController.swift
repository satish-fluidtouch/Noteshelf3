//
//  FTTemplatePlannerController.swift
//  Noteshelf3
//
//  Created by Akshay on 28/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWhatsNew2024PlannerController: FTWhatsNewSlideViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.learnMoreBtn?.addTarget(self, action: #selector(learnMoreBtnAction(_ :)), for: .touchUpInside)
    }
    
    @objc override func learnMoreBtnAction(_ button: UIButton) {
        var components = URLComponents()
        components.scheme = FTSharedGroupID.getAppBundleID()
        components.path = FTAppIntentHandler.templatesPath
        if let url = components.url {
            self.dismiss(animated: true) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
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
