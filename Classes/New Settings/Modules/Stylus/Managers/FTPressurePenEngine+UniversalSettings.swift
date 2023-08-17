//
//  PressurePenEngine+UniversalSettings.swift
//  Noteshelf
//
//  Created by Siva on 15/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
#if !targetEnvironment(macCatalyst)
let SharedPressurePenEngine = PressurePenEngine.shared()

extension PressurePenEngine {

    func enableStylus(withIdentifier persistenKey: String, status: Bool) {
        let standardUserDefaults = UserDefaults.standard
        if status {
            UserDefaults.setApplePencilEnable(false);
        }
        standardUserDefaults.set(status, forKey: (persistenKey));
        standardUserDefaults.synchronize();
    }

}
#endif
