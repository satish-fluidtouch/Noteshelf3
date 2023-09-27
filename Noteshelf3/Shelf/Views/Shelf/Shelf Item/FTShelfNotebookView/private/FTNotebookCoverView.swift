//
//  FTNotebookCoverView.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 19/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

struct FTNotebookCoverView: View {
    @EnvironmentObject var shelfItem: FTShelfItemViewModel
    @EnvironmentObject var shelfViewModel: FTShelfViewModel

    var isHighlighted = false;

    var body: some View {
        ZStack(alignment: .top) {
            if(isHighlighted) {
                FTShelfItemDropOverlayView()
                    .zIndex(2)
            }
            Image(uiImage: shelfItem.coverImage)
                .resizable()
                .zIndex(1)
                .if(shelfItem.isLoadingNotebook, transform: { view in
                    view.overlay(alignment: Alignment.center, content: {
                        ProgressView()
                    })
                })
                    .if(shelfItem.isDownloadingNotebook, transform: { view in
                        view.overlay(alignment: Alignment.center, content: {
                            FTCircularProgressView(progress: $shelfItem.progress)
                                .frame(width: 32, height: 32, alignment: .center)
                        })
                    })
                        .overlay(alignment: Alignment.bottom) {
                    if shelfItem.uploadDownloadInProgress {
                        let font: Font = shelfViewModel.displayStlye == .List ? Font.appFont(for: .regular, with: 12) : Font.appFont(for: .regular, with: 18)
                        Image(systemName: "icloud")
                            .foregroundColor(Color.black.opacity(0.2))// For handlilng dark/light mode used black color
                            .frame(width: 24, height: 24, alignment: Alignment.center)
                            .font(font)
                            .padding(.bottom, 8)
                    } else if shelfItem.isNotDownloaded {
                        let imagSize: CGSize = shelfViewModel.displayStlye == .List ? CGSize(width: 16, height: 16) :  CGSize(width: 24, height: 24)
                        let padding: CGFloat = shelfViewModel.displayStlye == .List ? 2 : 8
                        let font: Font = shelfViewModel.displayStlye == .List ? Font.appFont(for: .regular, with: 12) : Font.appFont(for: .regular, with: 18)
                        Image(systemName: "icloud.and.arrow.down")
                            .foregroundColor(Color.black.opacity(0.2))// For handlilng dark/light mode used black color
                            .frame(width: imagSize.width, height: imagSize.height, alignment: Alignment.center)
                            .font(font)
                            .padding(.bottom, padding)
                    }
                }
                .overlay(alignment: .bottom) {
                    if shelfViewModel.mode == .selection, shelfViewModel.displayStlye != .List {
                        FTShelfItemSelectionIndicator(isSelected: $shelfItem.isSelected)
                            .padding(.bottom, 4)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if  shelfViewModel.canShowStarredIconOnNB && shelfItem.isFavorited {
                        let starredImgSize: CGSize = shelfViewModel.displayStlye == .List ? CGSize(width: 16, height: 16) :  CGSize(width: 28, height: 28)
                        let padding: CGFloat = shelfViewModel.displayStlye == .List ? 2 : 8
                        let font: Font = shelfViewModel.displayStlye == .Gallery ? Font.appFont(for: .regular, with: 21) : (shelfViewModel.displayStlye == .Icon ? Font.appFont(for: .regular, with: 16) : Font.appFont(for: .regular, with: 12))
                        Image(systemName: "star.fill")
                            .imageScale(.medium)
                            .foregroundColor(Color.init(hex: "#FFBD00", alpha: 0.9))
                            .frame(width: starredImgSize.width, height: starredImgSize.height, alignment: Alignment.center)
                            .font(font)
                            .padding(.trailing,padding)
                            .padding(.top,padding)
                    }
                }
                .overlay {
                    if shelfItem.showLockIcon() {
                        FTLockIconView()
                    }
                }
                .overlay(alignment: .topLeading, content: {
                    NS2BadgeView()
                })
                .onFirstAppear(perform: {
                    shelfItem.configureShelfItem(shelfItem.model)
                })
        }
        .cornerRadius(leftCornerRadius, corners: [.topLeft, .bottomLeft])
        .cornerRadius(rightCornerRadius, corners: [.topRight, .bottomRight])
    }
    
    func sizeOfLockIcon(_ refSize: CGSize) -> CGFloat {
        let ratio: CGFloat = 64 / 214
        return refSize.width * ratio
    }
    
    private var leftCornerRadius: CGFloat {
        FTShelfItemProperties.leftCornerRadiusForShelfItemImage(shelfItem.coverImage,displayStyle: shelfViewModel.displayStlye)
    }

    private var rightCornerRadius: CGFloat {
        FTShelfItemProperties.rightCornerRadiusForShelfItemImage(shelfItem.coverImage,displayStyle: shelfViewModel.displayStlye)
    }
}

struct FTShelfItemSelectionIndicator: View {
    var isSelected: Binding<Bool>
    @EnvironmentObject var shelfitem: FTShelfItemViewModel
    @EnvironmentObject var viewModel: FTShelfViewModel
    
    var body: some View {
        Image(isSelected.wrappedValue ? "selection_checkMark" : "shelfItemSelectionMode")
            .symbolRenderingMode(SymbolRenderingMode.palette)
            .foregroundColor(Color.appColor(.black20))
            .frame(width:viewModel.displayStlye == .List ? 22 : 32, height: 32, alignment: Alignment.center)
    }
}

struct FTShelfItemDropOverlayView: View {
    var body: some View {
        Color.black.opacity(0.2)
            .frame(maxWidth: .infinity,maxHeight:.infinity)
    }
}

struct NS2BadgeView: View {
    @EnvironmentObject var shelfItem: FTShelfItemViewModel
    @EnvironmentObject var shelfViewModel: FTShelfViewModel

    var body: some View {
        if shelfItem.isNS2Book == true {
            let size: CGFloat = shelfViewModel.displayStlye == .List ? 10 : 20
            let padding: CGFloat = shelfViewModel.displayStlye == .List ? 2 : 8
            Image("ns2_migration_logo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(.top, padding)
                .padding(.leading, padding)
        }
    }
}

struct FTLockIconView: View {
    @EnvironmentObject var shelfViewModel: FTShelfViewModel

    var body: some View {
        let size: CGFloat = shelfViewModel.displayStlye == .Gallery ? 64 : (shelfViewModel.displayStlye == .Icon ? 38 : 16)
        let imageSize: CGFloat = shelfViewModel.displayStlye == .Gallery ?  24 : (shelfViewModel.displayStlye == .Icon ?  16 : 8)
        ZStack {
            FTVibrancyEffectView()
            .frame(width: size, height: size, alignment: .center)
            .cornerRadius(100.0)
            .overlay {
                Image("lockedIcon")
                .resizable()
                    .scaledToFit()
                    .frame(width:imageSize, height: imageSize)
            }
        }
    }
}
