//
//  FTCustomButton.swift
//  Noteshelf3
//
//  Created by Sameer on 22/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI

public class FTCustomButton: UIButton {
    //Set the custom style in story board to set the custom font
//    @IBInspectable var style: Int = 0;
    @IBInspectable var localizationKey: String?

    public override func awakeFromNib() {
        super.awakeFromNib()
        if let localizationKey = self.localizationKey {
            self.setTitle(NSLocalizedString(localizationKey, comment: self.title(for: .normal) ?? ""), for: .normal)
        } else {
            self.setTitle(self.title(for: .normal)?.localized ?? "", for: .normal)
        }
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
    let scaleValue: CGFloat

    public init(scaleValue: CGFloat) {
        self.scaleValue = scaleValue
    }

    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleValue : 1.0)
            .animation(.easeInOut(duration: AnimationValue.animatedValue), value: configuration.isPressed)
    }
}
public struct AnimationValue {
    public static var animatedValue: Double = 0.2
}

//UIKit Interaction Button Custom Class
open class FTInteractionButton: UIButton {
    public static let shared = FTInteractionButton()

    open func apply(to button: UIButton, withScaleValue scaleValue: CGFloat = 0.93) {
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
