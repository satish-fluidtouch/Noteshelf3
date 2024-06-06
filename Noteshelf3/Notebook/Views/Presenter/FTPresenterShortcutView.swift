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
            HStack(spacing: FTSpacing.small) {
                self.pointerView
                self.penView
                self.moreOptionsView
                    .rotationEffect(self.viewModel.contentTransformation)
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
        .frame(width: 44.0, height: shortcutHeight)
        .contentShape(Rectangle())
        .hoverEffect()
        .onTapGesture {
            self.viewModel.saveSelection(type: .pointer, color: viewModel.laserPointerColor)
        }
    }

    private var penView: some View {
        HStack(spacing: FTSpacing.zero) {
            ForEach(0..<viewModel.laserPenColors.count, id: \.self) { index in
                let color = viewModel.laserPenColors[index]
                VStack {
                    FTPresenterColorCircleView(hexColor: color, isSelected: self.isSelected(color: color))
                        .hoverEffect()
                }
                .frame(width: 34.0, height: shortcutHeight)
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
            }.frame(width: 44.0, height: shortcutHeight)
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

struct FTPresenterSliderShortcutView: View {
    @ObservedObject var viewModel: FTPresenterShortcutViewModel

    var body: some View {
        ZStack {
            FTSliderPointerView()
                .environmentObject(viewModel)
            FTSliderPenColorsView()
                .environmentObject(viewModel)
            FTSliderMoreOptionsView()
                .environmentObject(viewModel)
        }
        .onAppear {
            self.viewModel.fetchPresenterData()
        }
    }
}

struct FTSliderPointerView: View {
    @EnvironmentObject var viewModel: FTPresenterShortcutViewModel
    private let startAngle: Angle = FTPenSliderConstants.startAngle

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let angle = Angle(degrees: startAngle.degrees - Double(FTPenSliderConstants.rotationAngle))
                let x = FTPenSliderConstants.sliderRadius * cos(angle.radians) + geometry.size.width / 2
                let y = FTPenSliderConstants.sliderRadius * sin(angle.radians) + geometry.size.height / 2

                Image(self.viewModel.selectedPresenterType == .pen ? "laserPointer" : "laserPointerSelected")
                    .frame(width: 44.0, height: shortcutHeight)
                    .position(x: x, y: y)
                    .onAppear {
                        print("zzzz - pointer: x ->\(x) and y -> \(y)")
                    }
                    .onTapGesture {
                        self.viewModel.saveSelection(type: .pointer, color: viewModel.laserPointerColor)
                    }
            }
        }
    }
}

struct FTSliderPenColorsView: View {
    @EnvironmentObject var viewModel: FTPresenterShortcutViewModel
    private let startAngle: Angle = Angle(degrees: FTPenSliderConstants.startAngle.degrees + Double(FTPenSliderConstants.spacingAngle))

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<viewModel.laserPenColors.count, id: \.self) { index in
                    let color = viewModel.laserPenColors[index]
                    let angle = Angle(degrees: startAngle.degrees + (Double(FTPenSliderConstants.spacingAngle) * Double(index)) - Double(FTPenSliderConstants.rotationAngle))
                    let x = FTPenSliderConstants.sliderRadius * cos(angle.radians) + geometry.size.width / 2
                    let y = FTPenSliderConstants.sliderRadius * sin(angle.radians) + geometry.size.height / 2
                    
                    Button {
                        self.viewModel.saveSelection(type: .pen, color: color)
                    } label: {
                        FTPresenterColorCircleView(hexColor: color, isSelected: self.isSelected(color: color))
                            .frame(width: 34.0, height: shortcutHeight)
                    }
                    .buttonStyle(.plain)
                    .position(x: x, y: y)
                    .onAppear {
                        print("zzzz - presenter colors: index \(index) x ->\(x) and y -> \(y)")
                    }
                }
            }
            .onAppear {
                print("zzzz - presenter colors: \(viewModel.laserPenColors)")
            }
        }
    }

    private func isSelected(color: String) -> Bool {
        return color == viewModel.currentSelectedColor
    }
}


struct FTSliderMoreOptionsView: View {
    @EnvironmentObject var viewModel: FTPresenterShortcutViewModel
    private let startAngle: Angle = Angle(degrees: FTPenSliderConstants.startAngle.degrees + Double(FTPenSliderConstants.spacingAngle) * Double(1 + 3))

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let angle = Angle(degrees: startAngle.degrees  - Double(FTPenSliderConstants.rotationAngle))
                let x = FTPenSliderConstants.sliderRadius * cos(angle.radians) + geometry.size.width / 2
                let y = FTPenSliderConstants.sliderRadius * sin(angle.radians) + geometry.size.height / 2

                moreOptionsView
                    .position(x: x, y: y)
                    .onAppear {
                        print("zzzz - more options: x ->\(x) and y -> \(y)")
                    }
            }
        }
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
            }.frame(width: 44.0, height: shortcutHeight)
        }.menuOrder(.fixed)
    }
}
