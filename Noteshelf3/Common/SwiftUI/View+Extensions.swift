//
//  View+Extensions.swift
//  Noteshelf3
//
//  Created by Narayana on 29/04/22.
//

import Foundation
import SwiftUI
import UIKit

extension View {
    func ftFormSheet<Content: View>(isPresented: Binding<Bool>, contentSize: CGSize,
                                    @ViewBuilder content: @escaping () -> Content) -> some View {
        self.background(FTFormSheet(show: isPresented,
                                    content: content, contentSize: contentSize))
    }

    func cornerRadius(color: Color, radius: CGFloat = 10.0) -> some View {
        modifier(FTCornerRadius(radius: radius, fillColor: color))
    }

    func overlayBorder(radius: CGFloat,
                       borderColor: Color,
                       borderWidth: CGFloat = 1.0,
                       height: CGFloat = 36.0) -> some View {
        modifier(FTOverlayBorder(radius: radius, borderColor: borderColor, borderWidth: borderWidth, height: height))
    }

    func addBorder<S>(_ content: S, width: CGFloat = 1, cornerRadius: CGFloat) -> some View where S: ShapeStyle {
        let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
        return clipShape(roundedRect)
            .overlay(roundedRect.strokeBorder(content, lineWidth: width))
    }

    func ftTextFieldStyle() -> some View {
        modifier(FTTextFieldStyleNew())
    }

    @ViewBuilder func isHidden(_ isHidden: Bool) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }

    func onFirstAppear(perform: @escaping () -> Void) -> some View {
        self.modifier(ViewAppearModfier(perform: perform))
    }

    func detectOrientation(_ orientation: Binding<UIDeviceOrientation>) -> some View {
        modifier(FTDeviceOrientationViewModifier(orientation: orientation))
    }

#if canImport(UIKit)
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
#endif

    public func toolbarTitleStyle() -> some View {
        modifier(ToolBarTitleStyle())
    }

    public func sectionNameFont() -> some View {
        modifier(SectionNameText())
    }

    public func showSelected(_ showRect: Bool) -> some View {
        environment(\.showSelected, showRect)
    }

    public func showSearch(_ showSearch: Bool) -> some View {
        environment(\.showSearch, showSearch)
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }

    func hoverScaleEffect(scale: CGFloat = 1.1) -> some View {
        self.modifier(FTHoverScaleEffect(scaleToHover: scale))
    }

    func macOnlyTapAreaFixer() -> some View {
#if targetEnvironment(macCatalyst)
        self.modifier(TapAreaModifier())
#else
        return self
#endif
    }

    func macOnlyPlainButtonStyle() -> some View {
#if targetEnvironment(macCatalyst)
        return self.modifier(ButtonStylePlain())
#else
        return self
#endif
    }

    func macOnlyColorSchemeFixer() -> some View {
#if targetEnvironment(macCatalyst)
        return self.modifier(ColorSchemeModifier())
#else
        return self
#endif
    }
}

extension Image {
    public func asThumbnail(width: CGFloat, height: CGFloat, cornerRadius: Double = 0) -> some View {
        self.resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .shadow(color: Color("#000000"), radius: 0.74, x: 0, y: 0.74)
            .shadow(color: Color("#000000"), radius: 2.94, x: 0, y: 1.47)
            .shadow(color: Color("#000000"), radius: 0.74, x: 0, y: 0)
    }

    public func chevronImage() -> some View {
        self.font(.headline)
            .foregroundColor(.gray)
    }

    public func closeButton() -> some View {
        self.resizable()
            .font(Font.appFont(for: .semibold, with: 12))
            .foregroundColor(Color(hex: "#3C3C43", alpha: 0.60))
            .frame(width: 30, height: 30)
    }
}

extension Text {
    func multilineTextStyle(lineLimit: Int, aligment: TextAlignment) -> some View {
        modifier(FTMultilineTextStyle(lineLimit: lineLimit, alignment: aligment))
    }
}

extension Toggle {
    func greenStyle() -> some View {
        modifier(FTToggleStyle())
    }
}

// MARK: - RoundedRectangle
extension RoundedRectangle {
    static let blue: some View = RoundedRectangle(cornerRadius: 10)
        .stroke(.blue, lineWidth: 4)
}

// MARK: - Custom Label
extension Label {
    public func customLabel() -> some View {
        self.labelStyle(CustomLabelStyle())
    }
}

struct EqualIconWidthDomain<Content: View>: View {
    let content: Content
    @State var iconWidth: CGFloat? = nil

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environment(\.iconWidth, iconWidth)
            .onPreferenceChange(IconWidthKey.self) { self.iconWidth = $0 }
            .labelStyle(EqualIconWidthLabelStyle())
    }
}

struct IconWidthModifier: ViewModifier {
    @Environment(\.iconWidth) var width

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { proxy in
                Color.clear
                    .preference(key: IconWidthKey.self, value: proxy.size.width)
            })
            .frame(width: width)
    }
}

extension IconWidthKey: EnvironmentKey { }
private struct SearchKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

// MARK: - showSelected Rectangle
private struct RectangleShowKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    fileprivate var iconWidth: CGFloat? {
        get { self[IconWidthKey.self] }
        set { self[IconWidthKey.self] = newValue }
    }

    var showSelected: Bool {
        get { self [RectangleShowKey.self] }
        set { self [RectangleShowKey.self] = newValue }
    }

    var showSearch: Bool {
        get { self [SearchKey.self] }
        set { self [SearchKey.self] = newValue }
    }
}

private struct IconWidthKey: PreferenceKey {
    static var defaultValue: CGFloat? { nil }

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        switch (value, nextValue()) {
        case (nil, let next): value = next
        case (_, nil): break
        case (.some(let current), .some(let next)): value = max(current, next)
        }
    }
}
