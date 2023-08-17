//
//  FTPointerInteraction.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 02/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTPointerInteractionStyle: Int {
    case none
    case automatic
    case highlight
    case lift
    case hover
    case custom
    
    static var defaultStyle: FTPointerInteractionStyle {
        return .highlight
    }
}

@objcMembers class FTBaseButton: UIButton {
    var interactionStyle:FTPointerInteractionStyle = FTPointerInteractionStyle.defaultStyle

    override func awakeFromNib() {
        super.awakeFromNib()
        FTBaseButton.applyPointInteraction(to: self)
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        FTBaseButton.applyPointInteraction(to: self)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        FTBaseButton.applyPointInteraction(to: self)
    }
    
    static func applyPointInteraction(to button: UIButton) {
        if #available(iOS 13.4, *) {
            if button.supportsHovering {
                button.pointerStyleProvider = buttonProvider(button:pointerEffect:pointerShape:)
            }
        }
    }
}

extension UIButton {
    var supportsHovering: Bool { //A button should have either image OR title to support pointer interaction
        if (self.title(for: UIControl.State.normal)?.isEmpty ?? true) &&
            (self.image(for: UIControl.State.normal) == nil)
        {
            return false
        }
        return true
    }
}

func buttonProvider(button: UIButton, pointerEffect: UIPointerEffect, pointerShape: UIPointerShape) -> UIPointerStyle? {
    var buttonPointerStyle: UIPointerStyle?
    var interactionStyle = FTPointerInteractionStyle.defaultStyle
    if let baseButton = button as? FTBaseButton {
        if baseButton.supportsHovering {
            interactionStyle = baseButton.interactionStyle
        }
        else {
            interactionStyle = .none
        }
    }
    // Use the pointer effect's preview that's passed in.
    let targetedPreview = pointerEffect.preview
    switch interactionStyle {
    case .automatic:
        let buttonPointerEffect = UIPointerEffect.automatic(targetedPreview)
        buttonPointerStyle = UIPointerStyle(effect: buttonPointerEffect, shape: pointerShape)
        
    case .highlight:
        // Pointer slides under the given view and morphs into the view's shape.
        let buttonHighlightPointerEffect = UIPointerEffect.highlight(targetedPreview)
        buttonPointerStyle = UIPointerStyle(effect: buttonHighlightPointerEffect, shape: pointerShape)
        
    case .lift:
        /** Pointer slides under the given view and disappears as the view scales up and gains a shadow.
            Make the pointer shape’s bounds match the view’s frame so the highlight extends to the edges.
        */
        let buttonLiftPointerEffect = UIPointerEffect.lift(targetedPreview)
        let customPointerShape = UIPointerShape.path(UIBezierPath(roundedRect: button.bounds, cornerRadius: 6.0))
        buttonPointerStyle = UIPointerStyle(effect: buttonLiftPointerEffect, shape: customPointerShape)
        
    case .hover:
        /** Pointer retains the system shape while over the given view.
            Visual changes applied to the view are dictated by the effect's properties.
        */
        let buttonHoverPointerEffect =
            UIPointerEffect.hover(targetedPreview, preferredTintMode: .none, prefersShadow: true)
        buttonPointerStyle = UIPointerStyle(effect: buttonHoverPointerEffect, shape: nil)

    case .custom:
        break
    case .none:
        break
    }

    return buttonPointerStyle
}
