//
//  FTNotebookItemView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 12/05/22.
//
import FTStyles
import SwiftUI
enum FTNotebookPopoverType: Int, Identifiable {
    var id: Int {
        return rawValue
    }
    case getInfo = 0
    case tags
}
struct FTNotebookItemView: View {

    @EnvironmentObject var shelfItem: FTShelfItemViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo

    @State var hideShadow: Bool = false
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed: Bool = false

    var shelfItemWidth: CGFloat = 212
    var shelfItemHeight: CGFloat = 334
    let screenScale = UIScreen.main.scale;

    private var viewWidth: CGFloat  {
        return self.shelfItemWidth > 0 ? self.shelfItemWidth - 24 : 0
    }
    
    private var viewHeight: CGFloat  {
        return self.shelfItemHeight > 0 ? self.shelfItemHeight : 0
    }
    
    @Binding var isAnyNBActionPopoverShown: Bool

    var body: some View {
        //let _ = Self._printChanges()
        VStack(alignment: .center,spacing: 0) {
            ZStack(alignment:.bottom) {
                FTNotebookShadowView(shelfItem: shelfItem,thumbnailSize: thumbnailSize)
                    .isHidden((hideShadow || colorScheme == .dark))
                FTShelfItemContextMenuPreview(preview: {
                    FTNotebookCoverView(isHighlighted: (shelfViewModel.highlightItem == shelfItem))
                        .ignoresSafeArea()
                }, notebookShape: {
                    let shape: FTNotebookShape;
                    if shelfItem.coverImage.needEqualCorners || shelfViewModel.isNS2Collection {
                        shape = FTNotebookShape(raidus: leftCornerRadius);
                    }
                    else {
                        shape = FTNotebookShape(leftRaidus: leftCornerRadius, rightRadius: rightCornerRadius);
                    }
                    return shape;
                }, onAppearActon: {
                    shelfMenuOverlayInfo.isMenuShown = true;
                    hideShadow = true
                    // Track event
                    track(EventName.shelf_book_longpress, params: [EventParameterKey.location: shelfViewModel.shelfLocation()], screenName: ScreenName.shelf)
                }, onDisappearActon: {
                    hideShadow = false
                    if !isAnyNBActionPopoverShown {
                        shelfMenuOverlayInfo.isMenuShown = false;
                    }
                }, shelfItem: shelfItem)
                .frame(width: thumbnailSize.width,
                       height: thumbnailSize.height,
                       alignment: Alignment.center)
                .environmentObject(shelfItem)
                .padding(coverPadding)
                
            }
            .scaleEffect(isPressed ? 0.7 : 1.0)
            .animation(Animation.easeInOut(duration: 0.5), value: isPressed)
            .frame(width: thumbnailSize.width + (coverPadding.leading + coverPadding.trailing),
                   height: thumbnailSize.height + (coverPadding.top + coverPadding.bottom),
                   alignment: .top)
            .padding(EdgeInsets(top: -(coverPadding.top), leading: 0, bottom: 0, trailing: 0))
            .onLongPressGesture(perform: {

            }, onPressingChanged: { _ in
                isPressed.toggle()
                withAnimation {
                    isPressed = false
                }
            })
        }
        .padding(.horizontal,12)
        .frame(width: viewSize.width,
               height: viewSize.height,
               alignment: .top)
        .overlay(alignment: .bottom, content: {
            VStack(alignment: .center, content: {
                FTNotebookTitleView()
                    .frame(height: 60)
            })
            .frame(height: titleRectHeight,alignment:.bottom)
        })            
    }
    
    private var viewSize: CGSize {
        return CGSize(width:viewWidth, height: viewHeight)
    }
    
    private var thumbnailSize: CGSize {
       return CGSize(width:viewWidth, height: viewHeight - titleRectHeight)
    }
    
    private var coverProperties: FTShelfItemCoverViewProperties {
        if horizontalSizeClass == .regular {
            return .large
        }else {
            return .medium
        }
    }
    
    private var titleViewSize: CGSize {
        return CGSize(width: viewWidth, height: 60)
    }
    
    private var titleRectHeight: CGFloat {
       FTShelfItemProperties.Constants.Notebook.titleRectHeight
    }
            
    private var coverPadding: EdgeInsets {
        EdgeInsets(top: 16/screenScale, leading: 40/screenScale, bottom: 64/screenScale, trailing: 40/screenScale)
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
        var radius: CGFloat = 0.0
        if (shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.isDefaultCover) {
            radius = landCoverCornerRadius
        } else {
            radius = nbLeftCornerRadius
        }
        return radius
    }
    
    private var rightCornerRadius: CGFloat {
        var radius: CGFloat = 0.0
        if (shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.isDefaultCover) {
            radius = landCoverCornerRadius
        } else {
            radius = nbRightCornerRadius
        }
        return radius
    }
}
