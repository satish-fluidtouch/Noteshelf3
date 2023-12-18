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
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPressed: Bool

    var isHighlighted = false

    var body: some View {
        ZStack(alignment: .top) {
            Image(uiImage: shelfItem.coverImage)
                .resizable()
            
                .overlay(alignment: .center) {
                    ProgressView()
                        .isHidden(!shelfItem.isLoadingNotebook)
                    FTCircularProgressView(progress: $shelfItem.progress)
                        .frame(width: 32, height: 32, alignment: .center)
                    FTLockIconView()
                }
            
                .overlay(alignment: .topTrailing) {
                    FTFavoriteIconView()
                }

                .overlay(alignment: .bottom) {
                    FTShelfItemUploadDownloadIndicator()
                    FTShelfItemSelectionIndicator(isSelected: $shelfItem.isSelected)
                        .padding(.bottom, 4)
                }

            // As this is rare case, handled using IF
            if(isHighlighted) {
                FTShelfItemDropOverlayView()
            }
        }
        .cornerRadius(leftCornerRadius, corners: [.topLeft, .bottomLeft])
        .cornerRadius(rightCornerRadius, corners: [.topRight, .bottomRight])
        .border(shelfItem.coverImage.hasNoCover && colorScheme == .dark ? Color.white.opacity(0.1) : .clear, width: 2.0,cornerRadius: 10)
        
        .onFirstAppear(perform: {
            shelfItem.configureShelfItem(shelfItem.model)
        })
        .onAppear(perform: {
            shelfItem.isVisible = true;
            self.shelfItem.fetchCoverImage();
        })
        .onDisappear(perform: {
            shelfItem.isVisible = false;
        })
        
        .onTapGesture(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                shelfViewModel.didTapOnShelfItem(shelfItem)
            }
        })
        .onLongPressGesture(perform: {
            
        }, onPressingChanged: { _ in
            withAnimation {
                isPressed.toggle()
            }
        })
    }
    
    private var leftCornerRadius: CGFloat {
        FTShelfItemProperties.leftCornerRadiusForShelfItemImage(shelfItem.coverImage,displayStyle: shelfViewModel.displayStlye)
    }

    private var rightCornerRadius: CGFloat {
        FTShelfItemProperties.rightCornerRadiusForShelfItemImage(shelfItem.coverImage,displayStyle: shelfViewModel.displayStlye)
    }
}

struct FTShelfItemUploadDownloadIndicator: View {
    @EnvironmentObject var shelfitem: FTShelfItemViewModel
    @EnvironmentObject var viewModel: FTShelfViewModel
    
    private var imageSize: CGSize {
        let imagSize = viewModel.displayStlye == .List ? CGSize(width: 16, height: 16) :  CGSize(width: 24, height: 24)
        return imagSize
    }
    
    private var padding: CGFloat {
        let padding: CGFloat = viewModel.displayStlye == .List ? 2 : 8
        return padding
    }
    
    private var font: Font {
        let font = viewModel.displayStlye == .List ? Font.appFont(for: .regular, with: 12) : Font.appFont(for: .regular, with: 18)
        return font
    }

    private var indicatorImage: String {
        var name = "icloud.and.arrow.up"
        if !shelfitem.uploadDownloadInProgress && shelfitem.isNotDownloaded {
            name = "icloud.and.arrow.down"
        }
        return name
    }
    
    private var toShowIndicator: Bool {
        let status = shelfitem.uploadDownloadInProgress || (!shelfitem.uploadDownloadInProgress && shelfitem.isNotDownloaded)
        return status
    }
    
    var body: some View {
        Image(systemName: indicatorImage)
            .foregroundColor(Color.black.opacity(0.3))
            .frame(width: imageSize.width, height: imageSize.height, alignment: Alignment.center)
            .font(font)
            .padding(.bottom, padding)
            .isHidden(toShowIndicator)
    }
}

struct FTFavoriteIconView: View {
    @EnvironmentObject var shelfitem: FTShelfItemViewModel
    @EnvironmentObject var viewModel: FTShelfViewModel
    
    private var imageSize: CGSize {
        let imagSize = viewModel.displayStlye == .List ? CGSize(width: 16, height: 16) :  CGSize(width: 28, height: 28)
        return imagSize
    }
    
    private var padding: CGFloat {
        let padding: CGFloat = viewModel.displayStlye == .List ? 2 : 8
        return padding
    }
    
    private var font: Font {
        let font = viewModel.displayStlye == .Gallery ? Font.appFont(for: .regular, with: 21) : (viewModel.displayStlye == .Icon ? Font.appFont(for: .regular, with: 16) : Font.appFont(for: .regular, with: 12))
        return font
    }

    var body: some View {
        Image(systemName: "star.fill")
            .imageScale(.medium)
            .foregroundColor(Color.init(hex: "#FFBD00", alpha: 0.9))
            .frame(width: imageSize.width, height: imageSize.height)
            .font(font)
            .padding(.trailing, padding)
            .padding(.top, padding)
            .isHidden(!(viewModel.canShowStarredIconOnNB && shelfitem.isFavorited))
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
            .isHidden(!(viewModel.mode == .selection && viewModel.displayStlye != .List))
    }
}

struct FTShelfItemDropOverlayView: View {
    var body: some View {
        Color.black.opacity(0.2)
            .frame(maxWidth: .infinity,maxHeight:.infinity)
    }
}

struct FTLockIconView: View {
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @EnvironmentObject var shelfitem: FTShelfItemViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let size: CGFloat = shelfViewModel.displayStlye == .Gallery ? 64 : (shelfViewModel.displayStlye == .Icon ? 38 : 16)
        let imageSize: CGFloat = shelfViewModel.displayStlye == .Gallery ?  24 : (shelfViewModel.displayStlye == .Icon ?  16 : 8)
        ZStack {
            FTVibrancyEffectView()
            .environment(\.colorScheme, colorScheme)
            .frame(width: size, height: size, alignment: .center)
            .cornerRadius(100.0)
            .overlay {
                Image("lockedIcon")
                .resizable()
                    .scaledToFit()
                    .frame(width:imageSize, height: imageSize)
            }
        }
        .isHidden(!shelfitem.model.isPinEnabledForDocument())
    }
}

@available(iOS 17.0, *)
struct PulseAnimationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
//            .symbolEffect(.pulse.byLayer)
    }
}

extension View {
    @ViewBuilder
    func pulseAnimation() -> some View {
        if #available(iOS 17.0, *) {
            self.modifier(PulseAnimationModifier())
        } else {
            self
        }
    }
}
