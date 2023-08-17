//
//  FTFinderTabHostingController.swift
//  Noteshelf3
//
//  Created by Sameer on 08/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTFinderTabHostingController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .appColor(.finderBgColor)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.navigationController?.isNavigationBarHidden = true
    }
    
    func _addChild(_ controller: UIViewController) {
        self.addChild(controller)
        self.view.addSubview(controller.view)
        controller.view.frame = self.view.frame
        controller.didMove(toParent: self)
    }
    
    func getChild() -> FTFinderTabBarController? {
        var finderController: FTFinderTabBarController?
        self.children.forEach { eachController in
            if let tabBarVc = eachController as? FTFinderTabBarController {
                finderController = tabBarVc
            }
        }
        return finderController
    }
    
//    func removeChild(_ controller: UIViewController) {
//        
//    }
}
