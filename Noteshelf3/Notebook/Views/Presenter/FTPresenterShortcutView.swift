//
//  FTPresenterShortcutView.swift
//  Noteshelf3
//
//  Created by Narayana on 01/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTPresenterShortcutView: View {
    @ObservedObject var viewModel: FTPresenterShortcutViewModel

    var body: some View {
        ZStack {
            FTShortcutBarVisualEffectView()
                .cornerRadius(100.0)
            VStack(spacing: FTSpacing.small) {
                self.pointerView
                self.penView
                self.moreOptionsView
                    .hoverScaleEffect(scale: 1.3)
            }
        }
        .toolbarOverlay()
        .onAppear {
            self.viewModel.fetchPresenterData()
        }
    }

    private var pointerView: some View {
        ZStack {
            Image(self.viewModel.selectedPresenterType == .pen ? "laserPointer" : "laserPointerSelected")
        }
        .frame(width: shortcutWidth, height: 44.0)
        .contentShape(Rectangle())
        .hoverEffect()
        .onTapGesture {
            self.viewModel.saveSelection(type: .pointer, color: viewModel.laserPointerColor)
        }
    }

    private var penView: some View {
        VStack(spacing: FTSpacing.zero) {
            ForEach(0..<viewModel.laserPenColors.count, id: \.self) { index in
                let color = viewModel.laserPenColors[index]
                VStack {
                    FTPresenterColorCircleView(hexColor: color, isSelected: self.isSelected(color: color))
                        .hoverEffect()
                }
                .frame(width: shortcutWidth, height: 34.0)
                .contentShape(Rectangle())
                .onTapGesture {
                    self.viewModel.saveSelection(type: .pen, color: color)
                }
            }
        }
    }

    private func isSelected(color: String) -> Bool {
        return color == viewModel.currentSelectedColor
    }

    private var moreOptionsView: some View {
        Menu {
            ForEach(FTPresenterModeOption.allCases, id: \.self) { option in
                Button {
                    self.viewModel.handlePresentationOptionTap(option: option)
                } label: {
                    HStack(spacing: FTSpacing.small) {
                        Image(systemName: option.imageName)
                            .modifier(FTPresentOptionModifier())

                        Text(option.localizedString)
                            .modifier(FTPresentOptionModifier())
                    }
                }
            }
        } label: {
            VStack {
                Image(systemName: "ellipsis.circle")
                    .font(Font.appFont(for: .medium, with: 18))
                    .foregroundColor(Color.label.opacity(0.96))
            }.frame(width: shortcutWidth, height: 44.0)
        }.menuOrder(.fixed)
    }
}

struct FTPresentOptionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.label)
            .font(.appFont(for: .regular, with: 17))
    }
}

struct FTPresenterShortcutView_Previews: PreviewProvider {
    static var previews: some View {
        FTPresenterShortcutView(viewModel: FTPresenterShortcutViewModel(rackData: FTRackData(type: .pen, userActivity: nil), delegate: nil))
    }
}
