//
//  FTCustomButton.swift
//  Noteshelf3
//
//  Created by Sameer on 22/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI

public class FTCustomButton: FTUIkitInteractionButton {
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
        NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    private func setUpFont() {
        self.titleLabel?.adjustsFontForContentSizeCategory = true
        if  let font = self.titleLabel?.font {
            let style = UIFont.textStyle(for: font.pointSize)
            let scaledFont = UIFont.scaledFont(for: font, with: style)
            self.titleLabel?.font = scaledFont
        }
    }
    
    @objc func preferredContentSizeChanged(_ notification: Notification) {
//        setStyle()
    }

}

open class FTUIkitInteractionButton: UIButton {

    private var isBouncing: Bool = false
    private let animationDuration: Double = 0.2

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    private func commonInit() {
        addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        addTarget(self, action: #selector(buttonTouchUpInside), for: .touchUpInside)
    }
    @objc private func buttonTouchDown() {
        animateButton(scale: 0.99)
    }
    @objc private func buttonTouchUpInside() {
        animateButton(scale: 1.0)
    }
    private func animateButton(scale: CGFloat) {
        let springAnimation = CASpringAnimation(keyPath: "transform.scale")
        springAnimation.fromValue = layer.presentation()?.value(forKeyPath: "transform.scale") as? CGFloat ?? 1.0
        springAnimation.toValue = scale
        springAnimation.duration = animationDuration
        springAnimation.initialVelocity = 0.5
        springAnimation.damping = 0.1
        layer.add(springAnimation, forKey: "springAnimation")
        UIView.animate(withDuration: animationDuration) {
            self.isBouncing = scale < 1.0
        }
    }
}

 struct FTInteractionButtonModifier: ViewModifier {
    @State private var isBouncing: Bool = false
    var scaleValue: CGFloat

     func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? scaleValue : 1.0)
            .animation(Animation.easeInOut(duration: 0.1), value: isBouncing)
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        toggleStateWithAnimation()
                        isBouncing = false
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 1.0)
                    .onEnded { _ in
                        toggleStateWithAnimation()
                        isBouncing = false
                    }
                    .onChanged { gesture in
                        toggleStateWithAnimation()
                    }
            )
    }
    private func toggleStateWithAnimation() {
        isBouncing.toggle()
    }
}

extension View {
    public func buttonInteractionStyle(scaleValue: CGFloat) -> some View {
        self.modifier(FTInteractionButtonModifier(scaleValue: scaleValue))
    }
}
