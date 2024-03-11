//
//  FTTextToolbarButton.swift
//  Noteshelf3
//
//  Created by Akshay on 23/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTextToolbarButton: UIButton {
    override func updateConfiguration() {
        super.updateConfiguration()
        var bgConfig: UIBackgroundConfiguration
        if isSelected {
            bgConfig = UIBackgroundConfiguration.clear()
            bgConfig.backgroundColor = UIColor.appColor(.white100)
        } else {
            bgConfig = UIBackgroundConfiguration.clear()
        }
        self.preferredBehavioralStyle = .pad
        self.configuration?.background = bgConfig
    }
}

class FTTextInputAccessoryButton: UIButton {
    override func updateConfiguration() {
        super.updateConfiguration()
        var config: UIButton.Configuration
        if self.isSelected {
            config = .filled()
        } else {
            config = .plain()
        }
        config.image = configuration?.image
        config.title = configuration?.title

        self.configuration = config
    }
}

extension UIBarButtonItem {
    convenience init(button: UIButton) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.frame = CGRect(x: 0, y: 10, width: 36, height: 36)
        view.addSubview(button)
        self.init(customView: view)
    }
}

extension UIButton.Configuration {
   static func plainConfiguration(with image: UIImage?) -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.image = image
        return config
    }
}

