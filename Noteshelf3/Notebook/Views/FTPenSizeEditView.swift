//
//  FTPenSizeEditView.swift
//  Noteshelf3
//
//  Created by Narayana on 22/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

enum FTPenSizeEditViewDisplayMode: String {
    case normal
    case favoriteEdit

    var contentSize: CGSize {
        var size = CGSize(width: FTPenSizeEditController.viewSize.width, height: 36.0)
        if self == .normal {
            size.width -= 16.0
        }
        return size
    }

    var containerSize: CGSize {
        return CGSize(width: FTPenSizeEditController.viewSize.width, height: 52.0)
    }

    var contentColor: Color {
        var color = Color.appColor(.toolbarOutline)
        if self == .favoriteEdit {
            color = Color.appColor(.white60)
        }
        return color
    }

    var contentBorderWidth: CGFloat {
        var width: CGFloat = 0.5
        if self == .favoriteEdit {
            width = 0.0
        }
        return width
    }
}

struct FTPenSizeEditView: View {
    var displayMode = FTPenSizeEditViewDisplayMode.normal
    let penType: FTPenType
    @State var favoriteSizeValue: CGFloat
    @ObservedObject var sizeEditModel: FTPenSizeEditModel

    @State private var sliderTapped = false
    @State private var selected: Bool = true
    @State private var showIndicator: Bool = true
    private let overlaySize: CGSize = FTPenSizeEditController.overlaySize

    var body: some View {
        VStack {
            VStack {
            }
            .frame(width: displayMode.contentSize.width, height: displayMode.contentSize.height)
            .background(displayMode.contentColor)
            .cornerRadius(10.0)
            .border(Color.appColor(.toolbarOutline), width: displayMode.contentBorderWidth, cornerRadius: 10.0)
        }
        .frame(width: displayMode.containerSize.width, height: displayMode.containerSize.height)
        .containerStyle(displayMode: self.displayMode)
        .overlay(
            ZStack {
                ValueSlider(value: $favoriteSizeValue, in: penType.rackType.sizeRange, step: 0.1, tapped: $sliderTapped) { edited in
                }.valueSliderStyle(
                    HorizontalValueSliderStyle(
                        track:
                            HorizontalRangeTrack(
                                view:
                                    VStack {
                                    })
                            .background(Image("sliderBg").resizable().frame(width: overlaySize.width,height: 8)).contentShape(Rectangle()),
                        thumb: FTPenSizeView(isSelected: selected, showIndicator: showIndicator, viewSize: penType.getIndicatorSize(using: favoriteSizeValue), favoriteSizeValue: favoriteSizeValue),
                        thumbSize: CGSize(width: 40, height: 40),
                        options: .interactiveTrack
                    )
                )
            }
            .frame(width: overlaySize.width, height: overlaySize.height)
        )
        .onAppear {
            self.favoriteSizeValue = self.sizeEditModel.currentSize
        }
        .onChange(of: self.favoriteSizeValue) { size in
            var reqSize = size
            if self.sliderTapped {
                reqSize = CGFloat(Int(size.rounded()))
            }
            self.favoriteSizeValue = reqSize
            self.sizeEditModel.currentSize = reqSize
        }
    }
}

private struct ContainerModifier: ViewModifier {
    private let mode: FTPenSizeEditViewDisplayMode

    init(mode: FTPenSizeEditViewDisplayMode) {
        self.mode = mode
    }

    func body(content: Content) -> some View {
        if mode == .favoriteEdit {
            content
        } else {
            content
                .background(Color.appColor(.popoverBgColor))
                .cornerRadius(16.0)
                .background(Color.appColor(.black20)
                    .shadow(color: Color.appColor(.black20), radius: 60, x: 0, y: 10)
                    .blur(radius: 30, opaque: false))
        }
    }
}

private extension View {
    func containerStyle(displayMode: FTPenSizeEditViewDisplayMode) -> some View {
        self.modifier(ContainerModifier(mode: displayMode))
    }
}

struct FTPenSizeEditView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // test here
        }
    }
}
