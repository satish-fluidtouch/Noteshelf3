//
//  FTCustomButton.swift
//  Noteshelf3
//
//  Created by Sameer on 22/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI

public enum ScalevalueMode: CGFloat{
    case veryslow = 0.8
    case littleslow = 0.9
    case slow = 0.92
    case standard = 0.96
    case fast = 0.98
}

public class FTCustomButton: UIButton {
    //Set the custom style in story board to set the custom font
//    @IBInspectable var style: Int = 0;
    @IBInspectable var localizationKey: String?

    public override func awakeFromNib() {
        super.awakeFromNib()
        var title = ""
        if let localizationKey = self.localizationKey {
            title = NSLocalizedString(localizationKey, comment: self.title(for: .normal) ?? "")
        } else {
            title = self.title(for: .normal)?.localized ?? ""
        }
        var config = self.configuration
        config?.title = title
        self.configuration = config
        setUpFont()
    }

    private func setUpFont() {
        self.titleLabel?.adjustsFontForContentSizeCategory = true
        if  let font = self.titleLabel?.font {
            let style = UIFont.textStyle(for: font.pointSize)
            let scaledFont = UIFont.scaledFont(for: font, with: style)
            self.titleLabel?.font = scaledFont
        }
    }
}

//SwiftUI Interaction Button Custom Class
public struct FTMicroInteractionButtonStyle: ButtonStyle {

    let scaleValue: ScalevalueMode

    public init(scaleValue: ScalevalueMode) {
        self.scaleValue = scaleValue
    }

    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleValue.rawValue : 1.0)
            .animation(.easeInOut(duration: AnimationValue.animatedValue), value: configuration.isPressed)
    }
}

// TODO: (RP) rename this to be appropriate for micro interaction.
public struct AnimationValue {
    public static var animatedValue: Double = 0.3
}

//UIKit Interaction Button Custom Class
extension UIButton {

    public func apply(to button: UIButton, withScaleValue scaleValue: CGFloat = 0.93) {
        button.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonReleased(sender:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonReleased(sender:)), for: .touchUpOutside)

        // Store the scale value in the button's tag for later use
        button.tag = Int(scaleValue * 100) // Convert to an integer for simplicity
    }

    @objc private func buttonPressed(sender: UIButton) {
        let scaleValue = CGFloat(sender.tag) / 100.0
        UIView.animate(withDuration: AnimationValue.animatedValue, animations: {
            sender.transform = CGAffineTransform(scaleX: scaleValue, y: scaleValue)
        })
    }

    @objc private func buttonReleased(sender: UIButton) {
        UIView.animate(withDuration: AnimationValue.animatedValue, animations: {
            sender.transform = .identity
        })
    }
}
