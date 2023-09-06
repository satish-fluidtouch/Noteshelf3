//
//  FTNotebookViewList.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 19/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

struct FTNotebookViewList : View {

    var shelfItemWidth: CGFloat = 212
    var shelfItemHeight: CGFloat = 88
    private let screenScale = UIScreen.main.scale
    private let listGridViewHorizontalPadding: CGFloat = 12

    @EnvironmentObject var shelfItem: FTShelfItemViewModel
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo
    @State var hideShadow: Bool = false
    @Environment(\.colorScheme) var colorScheme

    @Binding var isAnyNBActionPopoverShown: Bool

    var body: some View {
        FTShelfItemContextMenuPreview(preview: {
            contentView
            .padding(.horizontal, listGridViewHorizontalPadding)
            .overlay(content: {
                if(shelfViewModel.highlightItem == shelfItem) {
                    FTShelfItemDropOverlayView()
                        .cornerRadius(10, corners: .allCorners)
                }
            })
            .ignoresSafeArea()

        }, notebookShape: {
            return FTNotebookShape(raidus: 10);
        }, onAppearActon: {
            shelfMenuOverlayInfo.isMenuShown = true;
            hideShadow = true
            // Track event
            track(EventName.shelf_book_longpress, params: [EventParameterKey.location: shelfViewModel.shelfLocation()], screenName: ScreenName.shelf)
        }, onDisappearActon: {
            if !isAnyNBActionPopoverShown {
                shelfMenuOverlayInfo.isMenuShown = false;
                hideShadow = false
            }
        }, shelfItem: shelfItem)
    }

    @ViewBuilder
    private var contentView: some View {
        HStack(alignment: .center,spacing: 16) {
            if shelfViewModel.mode == .selection {
                FTShelfItemSelectionIndicator(isSelected: $shelfItem.isSelected)
                    .padding(.trailing,16)
            }
            FTNotebookTitleView()
                .frame(alignment: .center)
                .padding(.leading,shelfViewModel.mode == .selection ? 52 : 68)
        }
        .overlay(alignment: .leading, content: {
            coverView
        })
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .centeredWithDivider
    }
    @ViewBuilder
    private var coverView: some View {
        VStack(alignment: .center,spacing: 0) {
            ZStack(alignment:.bottom) {
                FTNotebookShadowView(shelfItem: shelfItem,thumbnailSize: shelfImageSize)
                    .isHidden((hideShadow || colorScheme == .dark))
                FTNotebookCoverView(isHighlighted: false)
                    .frame(width: shelfImageSize.width,height: shelfImageSize.height,alignment: .center)
                    .padding(coverPadding)
            }
            .frame(width: shelfImageSize.width ,
                   height: shelfImageSize.height,
                   alignment: .top)
            .padding(EdgeInsets(top: (-coverPadding.top), leading: 0, bottom: 0, trailing: 0))
        }
        .padding(EdgeInsets(top: (-coverPadding.top), leading: shelfViewModel.mode == .selection ? 38 : 0, bottom: 0, trailing: 0))
    }

    private var shelfImageSize: CGSize {
        let shelfHeight = shelfItemHeight - 16;
        var shelfItemSize = CGSize(width: 52, height: shelfHeight)
        let image = shelfItem.coverImage
        if image.size.width > image.size.height {
            shelfItemSize.height = 37;
        }
        return shelfItemSize
    }
    
    private var coverPadding: EdgeInsets {
        var insets = EdgeInsets(top: 16/screenScale, leading: 40/screenScale, bottom: 64/screenScale, trailing: 40/screenScale)
        if shelfViewModel.displayStlye == .List {
            insets = EdgeInsets(top: 8/screenScale, leading: 16/screenScale, bottom: 25/screenScale, trailing: 16/screenScale)
        }
        return insets
    }
}

extension View {
    var centeredWithDivider: some View {
        VStack {
            Spacer()
            
            self
            
            Spacer()
            Divider()
                .frame(height: 1.0)
                .background(Color.appColor(.black5))
        }
    }
}
