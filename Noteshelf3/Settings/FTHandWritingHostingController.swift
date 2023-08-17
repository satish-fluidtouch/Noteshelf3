//
//  FTHandWritingHostingController.swift
//  Noteshelf3
//
//  Created by Rakesh on 09/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI

protocol FTHandwritingLanguageSelectionNavDelegate: AnyObject {
    func pushScreen()
    func dismiss()
}

class FTHandWringViewModel: ObservableObject {
    weak var delegate: FTHandwritingLanguageSelectionNavDelegate?
}

class FTHandWritingHostingController: UIHostingController<AnyView> {
    var model = FTHandWringViewModel();
    
    init() {
        let newModel = FTHandWringViewModel();
        super.init(rootView: AnyView(FTHandWritingView().environmentObject(FTIAPManager.shared.premiumUser).environmentObject(newModel)))
        newModel.delegate = self;
        self.model = newModel;
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
 
extension FTHandWritingHostingController: FTHandwritingLanguageSelectionNavDelegate {
    func pushScreen() {
        if FTIAPManager.shared.premiumUser.isPremiumUser {
            let storyboard = UIStoryboard(name: "FTNewSettings", bundle: nil);
            if let languageVc = storyboard.instantiateViewController(withIdentifier: FTRecognitionLanguageViewController.className) as? FTRecognitionLanguageViewController  {
                self.navigationController?.pushViewController(languageVc, animated: true)
            }
        }
        else {
            FTIAPurchaseHelper.shared.showIAPAlertForFeature(feature: "HandWriting Recognition", on: self);
        }
    }
    
    func dismiss() {
        self.dismiss(animated: true)
    }
}
