//
//  Extensions.swift
//  Noteshelf3
//
//  Created by Narayana on 06/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShortcutBarVisualEffectView: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.backgroundColor = FTToolbarConfig.bgColor
    }
}

struct FTVibrancyEffectView: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        let blurEffect  = UIBlurEffect(style: .regular)
        let blurEffectView = UIVisualEffectView(effect: blurEffect);

        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        blurEffectView.contentView.addSubview(vibrancyView)
        return blurEffectView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.backgroundColor = FTToolbarConfig.bgColor
    }
}

extension View {
    func toolbarOverlay(radius: CGFloat = 100.0) -> some View {
        modifier(FTToolbarBorder(radius: radius, borderColor: Color(uiColor: FTToolbarConfig.borderColor), borderWidth: 0.3))
    }
}

struct FTToolbarBorder: ViewModifier {
    let radius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
}

struct FTToolSeperator: View {
    var body: some View {
        Divider()
            .frame(height: 1.0)
            .opacity(0.5)
            .foregroundColor(Color.appColor(.toolSeperator))
    }
}
