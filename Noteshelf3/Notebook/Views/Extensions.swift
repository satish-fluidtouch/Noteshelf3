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
    @Environment(\.colorScheme) var colorScheme

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        let style = colorScheme == .dark ? UIBlurEffect.Style.extraLight : UIBlurEffect.Style.regular
        let blurEffect  = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect);
        return blurEffectView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        let style = colorScheme == .dark ? UIBlurEffect.Style.extraLight : UIBlurEffect.Style.regular
        let blurEffect = UIBlurEffect(style: style)
        uiView.effect = blurEffect
        uiView.backgroundColor = UIColor.appColor(.lock_icon_bgcolor)
    }
}

extension View {
    func toolbarOverlay(radius: CGFloat = 100.0, borderWidth: CGFloat = 0.3) -> some View {
        modifier(FTToolbarBorder(radius: radius, borderColor: Color(uiColor: FTToolbarConfig.borderColor), borderWidth: borderWidth))
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

struct FTSpectrumRepresentedView: UIViewRepresentable {
    typealias UIViewType = ColorPickerView

    @Binding var color: String
    weak var delegate: ColorPickerViewDelegate?

    func makeUIView(context: Context) -> ColorPickerView {
        let colorPickerView = ColorPickerView()
        colorPickerView.color = UIColor(hexString: color)
        colorPickerView.delegate = context.coordinator
        return colorPickerView
    }

    func updateUIView(_ uiView: ColorPickerView, context: Context) {
        uiView.color = UIColor(hexString: color)
    }

    func makeCoordinator() -> FTSpectrumCoordinator {
        FTSpectrumCoordinator(color: $color, delegate: self)
    }
}

class FTSpectrumCoordinator: NSObject, ColorPickerViewDelegate {
    @Binding var color: String
    var parent: FTSpectrumRepresentedView

    init(color: Binding<String>, delegate: FTSpectrumRepresentedView) {
        _color = color
        parent = delegate
    }

    func colorDidChange(_ color: UIColor) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateColor(_ :)), object: nil)
        self.perform(#selector(updateColor(_ :)), with: color, afterDelay: 0.1)
    }

    @objc func updateColor(_ color: UIColor) {
        parent.color = color.hexStringFromColor()// to fetch first 6 digits hex
    }
}
