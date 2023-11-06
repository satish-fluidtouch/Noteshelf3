//
//  FTPenSizeEditView.swift
//  Noteshelf3
//
//  Created by Narayana on 22/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTPenSizeEditView: View {
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
            .frame(width: FTPenSizeEditController.viewSize.width - 16.0, height: 36.0)
            .background(Color.appColor(.toolbarOutline))
            .cornerRadius(10.0)
            .border(Color.appColor(.toolbarOutline), width: 0.5, cornerRadius: 10.0)
        }
        .frame(width: FTPenSizeEditController.viewSize.width, height: 52.0)
        .background(Color.appColor(.popoverBgColor))
        .cornerRadius(16.0)
        .background(Color.appColor(.black20)
            .shadow(color: Color.appColor(.black20), radius: 60, x: 0, y: 10)
            .blur(radius: 30, opaque: false))
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

struct FTPenSizeEditView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // test here
        }
    }
}
