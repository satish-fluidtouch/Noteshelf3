//
//  FTGroupCoverNew.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 19/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

enum FTGroupCoverViewPurpose {
    case shelf
    case movePopover
    case shareFormsheet
}
struct FTGroupCoverViewNew: View {

    var groupModel: FTGroupItemProtocol?
    
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var groupCoverViewModel: FTGroupCoverViewModel
    @EnvironmentObject var groupItem: FTGroupItemViewModel

    var groupWidth: CGFloat = 214
    var groupHeight: CGFloat = 298
    var coverViewPurpose: FTGroupCoverViewPurpose = .shelf
    let screenScale = UIScreen.main.scale;


    private var groupCoverWidth: CGFloat  {
        if self.groupWidth > 0 {
            if coverViewPurpose == .shelf {
                return shelfViewModel.displayStlye == .List ? self.groupWidth : (self.groupWidth - 24)
            } else {
                return groupWidth
            }
        }
        return 0
    }
    private var groupCoverHeight: CGFloat  {
        return self.groupHeight > 0 ? self.groupHeight : 0
    }

    //Constants
    private var verticalPadding: CGFloat {
        var padding: CGFloat = 21
        if coverViewPurpose == .shelf {
            if shelfViewModel.displayStlye == .List {
                padding = 4
            } else if shelfViewModel.displayStlye == .Icon {
                padding = 13.49
            }
        } else if coverViewPurpose == .movePopover {
            padding = 4.66
        }
        return padding
    }

    private var horizontalpadding: CGFloat  {
        var padding: CGFloat = 14
        if coverViewPurpose == .shelf {
            if shelfViewModel.displayStlye == .List {
                padding = 3
            } else if shelfViewModel.displayStlye == .Icon {
                padding = 9
            }
        } else if coverViewPurpose == .movePopover {
            padding = 3.5
        }
        return padding
    }

    private var horizontalSpacing: CGFloat {
        var padding: CGFloat = 12
        if coverViewPurpose == .shelf {
            if shelfViewModel.displayStlye == .List {
                padding = 2
            } else if shelfViewModel.displayStlye == .Icon {
                padding = 7.61
            }
        } else if coverViewPurpose == .movePopover {
            padding = 1.73
        }
        return padding
    }
    private var  verticalSpacing: CGFloat {
        var padding: CGFloat = 12
        if coverViewPurpose == .shelf {
            if shelfViewModel.displayStlye == .List {
                padding = 2
            } else if shelfViewModel.displayStlye == .Icon {
                padding = 7.61
            }
        }
        else if coverViewPurpose == .movePopover {
            padding = 1.66
        }
        return padding
    }
    private var cornerRadius: CGFloat {
        var radius: CGFloat = 10
        if coverViewPurpose == .shelf {
            if shelfViewModel.displayStlye == .List {
                radius = 4
            } else if shelfViewModel.displayStlye == .Icon {
                radius = 6
            }
        } else if coverViewPurpose == .movePopover {
            radius = 1.39
        }
        return radius
    }
    private var bgColor: Color {
        if coverViewPurpose == .shelf {
            return Color.appColor(.groupBGColor)
        } else if coverViewPurpose == .shareFormsheet {
            return  Color.appColor(.shareGroupCovernBg)
        } else  {
            return  Color.black.opacity(0.1)
        }
    }
    //************** Group cover rules **************//
    // 2 port, 2 land- 2 land
    // 3 port and 1 land- 1 land and 2 port
    // 2 land and 1 port- 2 land
    // 4 port/3 port/1 land- as it is
    // 4 land- 2 land
    // 2 land 2 port- 2 land
    //**********************************************//

    var body: some View {
        VStack(alignment:.leading) {
            Grid(alignment:.leading ,horizontalSpacing: horizontalSpacing,verticalSpacing: verticalSpacing) {
                // Top Row
                if self.hasOnlyPortThumbs() {
                    portGridRowForItems(self.topPortItems())
                } else if self.hasOnlyLandThumbs()  ||
                            landThumbs.count >= 1 {
                    landGridRowForItem(self.topLandItem)
                }
                // Bottom Row
                if groupCoverViewModel.groupNotebooks.count > 1 {
                    if self.hasOnlyLandThumbs() || self.showOnlyTwoLandThumbs() || landThumbs.count > 1 {
                        landGridRowForItem(self.bottomLandItem)
                    }
                    else if (self.hasOnlyPortThumbs() && portThumbs.count > 2) ||  (!self.hasOnlyPortThumbs() && portThumbs.count >= 1){
                        portGridRowForItems(self.bottomPortItems())
                    }
                }
            }
            .frame(maxWidth:.infinity,alignment: .leading)
            .padding(.vertical,verticalPadding)
            .padding(.horizontal,horizontalpadding)
            .zIndex(0)
        }
        .overlay(alignment: .top) {
            if coverViewPurpose == .shelf, (groupCoverViewModel.groupItem!.childrens.isEmpty || groupContainsAllEmptyGroups){
                Image("emptyGroupPlaceholder")
                    .resizable()
                    .frame(height:(groupCoverHeight - 2*verticalPadding), alignment: .top)
                    .padding(.vertical,verticalPadding)
                    .padding(.horizontal,horizontalpadding)
            }
        }
        .overlay(alignment:.top) {
            if coverViewPurpose == .shelf, shelfViewModel.highlightItem == groupItem {
                FTShelfItemDropOverlayView()
                    .frame(width:groupWidth,height:groupCoverHeight,alignment: .top)
            }
        }
        .frame(width:groupCoverWidth,height:groupCoverHeight,alignment: .top)
        .background(bgColor)
        .cornerRadius(cornerRadius)
        .onAppear {
            groupCoverViewModel.isVisible = true
            groupCoverViewModel.fetchTopNotebookOfGroup(groupModel)
        }
        .onDisappear {
            groupCoverViewModel.isVisible = false
        }
    }
    private func landGridRowForItem(_ shelfItem:FTShelfItemViewModel?) -> some View {
        GridRow(alignment: .top) {
            if let shelfItem {
                LandNotebookItem(shelfItem)
                .gridCellColumns(2)
            }else {
                EmptyView()
            }
        }
    }
    private func portGridRowForItems(_ items:[FTShelfItemViewModel]) -> some View {
        GridRow {
            if items.count == 1 {
                PortNotebookItem(items[0])
                    .gridCellUnsizedAxes(.horizontal)
            }else if items.count >= 2 {
                PortNotebookItem(items[0])
                PortNotebookItem(items[1])
            }
        }
    }
    private func PortNotebookItem(_ shelfItem:FTShelfItemViewModel) -> some View {
        GroupNotebookView(coverViewPurpose:coverViewPurpose, shelfItemWidth: portThumbSize.width,shelfItemHeight: portThumbSize.height)
            .if(coverViewPurpose == .shelf, transform: { view in
                view.environmentObject(shelfViewModel)
            })
            .environmentObject(shelfItem)
    }
    
    private func LandNotebookItem(_ shelfItem:FTShelfItemViewModel) -> some View {
        GroupNotebookView(coverViewPurpose:coverViewPurpose, shelfItemWidth: landThumbSize.width,shelfItemHeight: landThumbSize.height)
            .if(coverViewPurpose == .shelf, transform: { view in
                view.environmentObject(shelfViewModel)
            })
            .environmentObject(shelfItem)
    }
    
    private var portThumbSize: CGSize {
        if groupCoverWidth > 0 && groupCoverHeight > 0 {
            return CGSize(width: (groupCoverWidth - 2*horizontalpadding - horizontalSpacing)/2, height: (groupCoverHeight - 2*verticalPadding - verticalSpacing)/2)
        }
        return .zero
    }
    private var landThumbSize: CGSize {
        if groupCoverWidth > 0 && groupCoverHeight > 0 {
            return CGSize(width: (groupCoverWidth - 2*horizontalpadding), height: (groupCoverHeight - 2*verticalPadding - verticalSpacing)/2)
        }
        return .zero
    }

    private func hasOnlyPortThumbs() -> Bool { // to check if top thumbnails has all portraits
        (groupCoverViewModel.groupNotebooks.count > 0 && portThumbs.count == groupCoverViewModel.groupNotebooks.count)
    }

    private func hasOnlyLandThumbs() -> Bool { // to check if top thumbnails has all landscaped
        (groupCoverViewModel.groupNotebooks.count > 0 && landThumbs.count == groupCoverViewModel.groupNotebooks.count)
    }

    private var landThumbs: [FTShelfItemViewModel] {
        groupCoverViewModel.groupNotebooks.filter({ viewmodel in
            return viewmodel.coverImage.size.width >  viewmodel.coverImage.size.height
        })
    }

    private var portThumbs: [FTShelfItemViewModel] {
        groupCoverViewModel.groupNotebooks.filter({ viewmodel in
            if viewmodel.isNS2Book {
                return true
            } else {
                return viewmodel.coverImage.size.height >  viewmodel.coverImage.size.width
            }
        })
    }

    private func showOnlyTwoLandThumbs() -> Bool {
        var showOnlyTwoLandThumbs: Bool = false
        let noOfLandThumbs: Int = groupCoverViewModel.groupNotebooks.filter({ $0.coverImage.isALandCover }).count
        showOnlyTwoLandThumbs = (noOfLandThumbs >= 2)
        return showOnlyTwoLandThumbs
    }

    private func topPortItems() ->[FTShelfItemViewModel] {
        Array(portThumbs.prefix(2))
    }

    private func bottomPortItems() ->[FTShelfItemViewModel] {
        if self.hasOnlyPortThumbs() && portThumbs.count >= 3 {
            return portThumbs.count > 3 ? Array(portThumbs.suffix(2)) : Array(portThumbs.suffix(1))
        } else {
            return portThumbs.count >= 2 ? Array(portThumbs.suffix(2)) : Array(portThumbs.suffix(1))
        }

    }

    private var topLandItem : FTShelfItemViewModel? {
        landThumbs.first
    }

    private var bottomLandItem: FTShelfItemViewModel? {
        return landThumbs.last
    }

    private var groupContainsAllEmptyGroups: Bool {
        return groupCoverViewModel.groupItem?.isGroupEmpty() ?? false
    }
}

struct FTGroupCoverViewNew_Previews: PreviewProvider {
    static var previews: some View {
        FTGroupCoverViewNew(groupCoverViewModel: FTGroupCoverViewModel(groupItem: nil))
    }
}

private struct GroupNotebookView: View {

    @EnvironmentObject var shelfItem: FTShelfItemViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var shelfViewModel: FTShelfViewModel

    var coverViewPurpose: FTGroupCoverViewPurpose = .shelf
    var shelfItemWidth: CGFloat = 212
    var shelfItemHeight: CGFloat = 334
    let screenScale = UIScreen.main.scale;

    private var viewWidth: CGFloat  {
        return self.shelfItemWidth > 0 ? self.shelfItemWidth : 0
    }

    private var viewHeight: CGFloat  {
        return self.shelfItemHeight > 0 ? self.shelfItemHeight : 0
    }

    var body: some View {
        coverWithLayerShadow
    }
    @ViewBuilder private var coverWithShadowImage: some View {
        ZStack(alignment:.center) {
            shadowView
                .frame(width: thumbnailSize.width + (52 / screenScale) ,
                       height: thumbnailSize.height + (52 / screenScale),
                       alignment: .center)
            coverView
                .frame(width: thumbnailSize.width + (52 / screenScale) ,
                       height: thumbnailSize.height + (52 / screenScale),
                       alignment: .center)
        }
        .frame(width: viewSize.width,
               height: viewSize.height,
               alignment: .center)
    }
    @ViewBuilder private var coverWithLayerShadow: some View {
        ZStack(alignment:.top) {
            coverView
                .frame(width: viewSize.width,
                       height: viewSize.height,
                       alignment: .top)
                .shadow(color: Color.appColor(.black8),
                        radius: fineShadowRadius,
                        x:0,
                        y:fineShadowY)
                .shadow(color: Color.appColor(.black8),
                        radius: blurShadowRadius,
                        x:0,
                        y:blurShadowY)
        }
        .onAppear {
            shelfItem.isVisible = true
        }
        .onDisappear {
            shelfItem.isVisible = false
        }
        .frame(width: viewSize.width,
                   height: viewSize.height,
                   alignment: .top)
    }
    private var shadowView: some View {
        Image(uiImage: shadowImage.resizableImage(withCapInsets: shadowImageEdgeInsets, resizingMode: .stretch))
    }

    @ViewBuilder private var coverView: some View {
        Image(uiImage: shelfItem.coverImage)
            .resizable()
            .overlay(alignment: .topLeading, content: {
                if coverViewPurpose == .shelf {
                    NS2BadgeView()
                        .scaleEffect(CGSize(width: 0.5, height: 0.5), anchor: .topLeading)
                        .environmentObject(shelfItem)
                        .environmentObject(shelfViewModel)
                }
            })
            .overlay {
                if shelfItem.model.isPinEnabledForDocument() && coverViewPurpose == .shelf {
                    FTLockIconView()
                        .scaleEffect(CGSize(width: 0.5, height: 0.5), anchor: .center)
                        .environmentObject(shelfViewModel)
                }
            }
            .cornerRadius(leftCornerRadius, corners: [.topLeft, .bottomLeft])
            .cornerRadius(rightCornerRadius, corners: [.topRight, .bottomRight])
            .zIndex(1)
            .onFirstAppear(perform: {
                shelfItem.configureShelfItem(shelfItem.model)
            })
            .overlay(alignment: Alignment.bottom) {
                if coverViewPurpose == .shelf && !((shelfItem.model as? FTDocumentItem)?.isDownloaded ?? false) {
                    Image(systemName: "icloud.and.arrow.down")
                        .symbolRenderingMode(SymbolRenderingMode.palette)
                        .foregroundColor(Color.appColor(.black20))
                        .frame(width: 16, height: 16, alignment: Alignment.center)
                        .font(Font.appFont(for: .medium, with: 12))
                        .if(shelfViewModel.displayStlye == .List, transform: { view in
                            view.scaleEffect(CGSize(width: 0.5, height: 0.5), anchor: .bottom)
                        })
                        .padding(.bottom, 4)
                }
            }
    }
    private var fineShadowRadius: CGFloat {
        var radius: CGFloat = 3.22
        if shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.isDefaultCover {
            radius = 5
        }
        if (coverViewPurpose == .shelf && shelfViewModel.displayStlye == .Icon) || (coverViewPurpose == .movePopover) {
            radius = 0.49
        }
        return radius
    }
    private var blurShadowRadius: CGFloat {
        var radius: CGFloat = 12.91
        if shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.isDefaultCover {
            radius = 20
        }
        if (coverViewPurpose == .shelf && shelfViewModel.displayStlye == .Icon) || (coverViewPurpose == .movePopover) {
            radius = 1.99
        }
        return radius
    }
    private var fineShadowY: CGFloat {
        var radius: CGFloat = 1.29
        if shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.isDefaultCover {
            radius = 2
        }
        if (coverViewPurpose == .shelf && shelfViewModel.displayStlye == .Icon) || (coverViewPurpose == .movePopover) {
            radius = 0.19
        }
        return radius
    }
    private var blurShadowY: CGFloat {
        var radius: CGFloat = 7.74
        if shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.isDefaultCover {
            radius = 12
        }
        if (coverViewPurpose == .shelf && shelfViewModel.displayStlye == .Icon) || (coverViewPurpose == .movePopover) {
            radius = 1.19
        }
        return radius
    }
    private var viewSize: CGSize {
        return CGSize(width:viewWidth, height: viewHeight)
    }

    private var thumbnailSize: CGSize {
       return CGSize(width:viewWidth, height: viewHeight)
    }

    private var coverPadding: EdgeInsets {
        EdgeInsets(top: 12/screenScale, leading: 26/screenScale, bottom: 40/screenScale, trailing: 26/screenScale)
    }

    private var nbLeftCornerRadius: CGFloat {
        FTShelfItemProperties.Constants.Notebook.portNBCoverleftCornerRadius
    }

    private var nbRightCornerRadius: CGFloat {
        FTShelfItemProperties.Constants.Notebook.portNBCoverRightCornerRadius
    }

    private var landCoverCornerRadius: CGFloat {
        FTShelfItemProperties.Constants.Notebook.landCoverCornerRadius
    }
    private var leftCornerRadius: CGFloat {
        var radius: CGFloat = FTShelfItemProperties.Constants.Group.moveFormsheetNoCoverCornerRadius// for move popover
        if shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.isDefaultCover {
            if coverViewPurpose == .shelf {
                if shelfViewModel.displayStlye == .Gallery {
                    radius = FTShelfItemProperties.Constants.Group.noCoverCornerRadius
                } else if shelfViewModel.displayStlye == .Icon {
                    radius = FTShelfItemProperties.Constants.Group.iconViewNoCoverCornerRadius
                } else if shelfViewModel.displayStlye == .List {
                    radius = FTShelfItemProperties.Constants.Group.listViewNoCoverCornerRadius
                }
            } else if coverViewPurpose == .shareFormsheet {
                radius = FTShelfItemProperties.Constants.Group.noCoverCornerRadius
            }
        }
        else {
            if coverViewPurpose == .movePopover {
                radius = FTShelfItemProperties.Constants.Group.moveFormsheetNBLeftCornerRadius
            } else if coverViewPurpose == .shelf {
                if shelfViewModel.displayStlye == .Gallery {
                    radius = FTShelfItemProperties.Constants.Group.nbLeftCornerRadius
                } else if shelfViewModel.displayStlye == .Icon {
                    radius = FTShelfItemProperties.Constants.Group.iconViewNBLeftCornerRadius
                } else if shelfViewModel.displayStlye == .List {
                    radius = FTShelfItemProperties.Constants.Group.listViewNBLeftCornerRadius
                }
            } else {
                radius = FTShelfItemProperties.Constants.Group.nbLeftCornerRadius
            }
        }
        return radius
    }
    private var rightCornerRadius: CGFloat {
        var radius: CGFloat = FTShelfItemProperties.Constants.Group.moveFormsheetNoCoverCornerRadius// for move popover
        if shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.isDefaultCover {
            if coverViewPurpose == .shelf {
                if shelfViewModel.displayStlye == .Gallery {
                    radius =  FTShelfItemProperties.Constants.Group.noCoverCornerRadius
                } else if shelfViewModel.displayStlye == .Icon {
                    radius =  FTShelfItemProperties.Constants.Group.iconViewNoCoverCornerRadius
                } else if shelfViewModel.displayStlye == .List {
                    radius = FTShelfItemProperties.Constants.Group.listViewNoCoverCornerRadius
                }
            } else if coverViewPurpose == .shareFormsheet {
                radius = FTShelfItemProperties.Constants.Group.noCoverCornerRadius
            }
        }
        else {
            if coverViewPurpose == .shelf {
                if shelfViewModel.displayStlye == .Gallery {
                    radius =  FTShelfItemProperties.Constants.Group.nbRightCornerRadius
                } else if shelfViewModel.displayStlye == .Icon {
                    radius =  FTShelfItemProperties.Constants.Group.iconViewNBRightCornerRadius
                } else if shelfViewModel.displayStlye == .List {
                    radius = FTShelfItemProperties.Constants.Group.listViewNBRightCornerRadius
                }
            } else if coverViewPurpose == .shareFormsheet {
                radius = FTShelfItemProperties.Constants.Group.nbRightCornerRadius
            }
        }
        return radius
    }
    private var shadowImageEdgeInsets: UIEdgeInsets {
        if shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.isDefaultCover {
            return UIEdgeInsets(top: 24/screenScale, left: 40/screenScale, bottom: 56/screenScale, right: 40/screenScale)
        } else {
            return  UIEdgeInsets(top: 28/screenScale, left: 38/screenScale, bottom: 52/screenScale, right: 42/screenScale)
        }
    }

    private var shadowImage: UIImage {
        var image = UIImage(named: "coveredGroupNBShadow");
        if (shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.hasNoCover || shelfItem.coverImage.isDefaultCover) {
            if let img = UIImage(named: "noCoverNBShadow")
                , let cgImage = img.cgImage {
                image = UIImage(cgImage: cgImage, scale: 2, orientation: img.imageOrientation);
            }
        } else {
            if let img = UIImage(named: "coveredGroupNBShadow"), let cgImage = img.cgImage {
                image = UIImage(cgImage: cgImage, scale: 2, orientation: img.imageOrientation);
            }
        }
        return image!;
    }
}
