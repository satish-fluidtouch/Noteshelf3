//
//  FTModifiers.swift
//  NS3
//
//  Created by Narayana on 18/04/22.
//

import FTStyles
import SwiftUI

struct FTCornerRadius: ViewModifier {
    let radius: CGFloat
    let fillColor: Color

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(
                    cornerRadius: radius,
                    style: .continuous
                ).fill(fillColor))
    }
}

struct FTMultilineTextStyle: ViewModifier {
    let lineLimit: Int
    let alignment: TextAlignment

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(lineLimit)
            .multilineTextAlignment(alignment)
    }
}

struct FTOverlayBorder: ViewModifier {
    let radius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    let height: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(borderColor, lineWidth: borderWidth)
                    .frame(height: height)
            )
    }
}

struct FTTextFieldStyleNew: ViewModifier {
    let bgColor = Color.appColor(.gray60).opacity(0.12)
    let fgColor: Color = .primary
    let radius: CGFloat = 10.0

    func body(content: Content) -> some View {
        content
            .foregroundColor(fgColor)
            .appFont(for: .regular, with: 17)
            .padding(.horizontal, FTSpacing.medium)
            .background(bgColor.cornerRadius(radius))
    }
}

struct FTDeviceOrientationViewModifier: ViewModifier {
    @Binding var orientation: UIDeviceOrientation

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                let currentOrientation = UIDevice.current.orientation
                if currentOrientation.isPortrait || currentOrientation.isLandscape {
                    orientation = currentOrientation
                }
            }
    }
}

public struct ViewAppearModfier: ViewModifier {
    @State private var isAppeared: Bool = false
    private var perform: () -> Void

    public init(perform: @escaping () -> Void) {
        self.perform = perform
    }

    public func body(content: Content) -> some View {
        content.onAppear {
            if !isAppeared {
                isAppeared = true
                perform()
            }
        }
    }
}

struct ToolBarTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.subheadline.weight(.bold))
    }
}

struct SectionNameText: ViewModifier {
    func body(content: Content) -> some View {
        content.font(Font.caption.weight(.medium))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct CustomLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
            configuration.title
        }
    }
}

struct FTToggleStyle: ViewModifier {
    let color = Color.green

    func body(content: Content) -> some View {
        content
            .toggleStyle(SwitchToggleStyle(tint: color))
            .listRowSeparator(.hidden)
    }
}

struct EqualIconWidthLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon.modifier(IconWidthModifier())
            configuration.title
        }
    }
}

struct FTHoverScaleEffect: ViewModifier {
    @State private var hovered = false
    let scaleToHover: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(self.hovered ? scaleToHover : 1.0)
            .onHover { hover in
                withAnimation {
                    self.hovered = hover
                }
            }
    }
}

struct TapAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.contentShape(Rectangle())
    }
}

struct ButtonStylePlain: ViewModifier {
    func body(content: Content) -> some View {
        content.buttonStyle(.plain)
    }
}

struct ColorSchemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(UIApplication.shared.uiColorScheme().toColorScheme)
    }
}
