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
   @StateObject var viewModel: FTFavoriteSizeViewModel
    let editIndex: Int
    let favoriteSizeValue: CGFloat

    var body: some View {
        VStack {
            VStack {
            }
            .frame(width: FTPenSizeEditController.viewSize.width - 16.0, height: 36.0)
            .background(Color.appColor(.toolbarOutline))
//            .cornerRadius(10.0)
//            .border(Color.appColor(.toolbarOutline), width: 0.5, cornerRadius: 10.0)
        }
        .frame(width: FTPenSizeEditController.viewSize.width, height: 52.0)
        .background(Color.appColor(.popoverBgColor))
//        .cornerRadius(16.0)
        .background(Color.appColor(.black20)
//            .shadow(color: Color.appColor(.black20), radius: 60, x: 0, y: 10)
            .blur(radius: 30, opaque: false))
        .overlay(
            FTPenSizeOverlay(editingSize: favoriteSizeValue, editIndex: editIndex)
            .environmentObject(viewModel)
        )
    }
}

struct FTPenSizeOverlay: View {
    @State var editingSize: CGFloat = 4.0
    @State private var selected: Bool = true
    @State private var showIndicator: Bool = true
    @State private var sliderTapped: Bool = false
    @EnvironmentObject var sizeViewModel: FTFavoriteSizeViewModel
    private let overlaySize: CGSize = FTPenSizeEditController.overlaySize
    let editIndex: Int

    var body: some View {
        ZStack {
            ValueSlider(value: $editingSize, in: sizeViewModel.sizeRange, step: 0.1, tapped: $sliderTapped) { edited in
            }.valueSliderStyle(
                HorizontalValueSliderStyle(
                    track:
                        HorizontalRangeTrack(
                            view:
                                VStack {
                                })
                        .background(Image("sliderBg").resizable().frame(width: overlaySize.width,height: 8)).contentShape(Rectangle()),
                    thumb: FTPenSizeView(isSelected: selected, showIndicator: showIndicator, viewSize: self.sizeViewModel.getViewSize(using: editingSize), favoriteSizeValue: editingSize),
                    thumbSize: CGSize(width: 40, height: 40),
                    options: .interactiveTrack
                )
            )
        }
        .frame(width: overlaySize.width, height: overlaySize.height)
        .onChange(of: self.editingSize) { size in
            if editIndex < self.sizeViewModel.favoritePenSizes.count {
                var reqSize = size
                if self.sliderTapped {
                    reqSize = CGFloat(Int(size.rounded()))
                }
                self.editingSize = reqSize
                self.sizeViewModel.updateCurrentPenSize(size: reqSize, sizeMode: .sizeEdit)
                self.sizeViewModel.updateFavoriteSize(with: reqSize, at: editIndex)
            }
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
