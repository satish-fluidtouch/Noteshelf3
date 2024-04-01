//
//  GridItem.swift
//  DynamicGridView
//
//  Created by Rakesh on 11/04/23.
//

import SwiftUI

struct FTShelfTopSectionItem: View {
    var type: FTShelfHomeTopSectionModel
    let isFirsttime: Bool
    let geometrySize: CGFloat
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    @StateObject var shelfViewModel: FTShelfViewModel
    
    var body: some View {
        Button {
            let locationName = shelfViewModel.isInHomeMode ? "Home" : shelfViewModel.collection.displayTitle
            switch type {
            case .quicknote:
                shelfViewModel.quickCreateNewNotebook()
                track(EventName.shelf_quicknote_tap, params: [EventParameterKey.location: locationName] ,screenName: ScreenName.shelf)
            case .newNotebook:
                shelfViewModel.delegate?.showNewBookPopverOnShelf()
                track(EventName.shelf_newnotebook_tap, params: [EventParameterKey.location: locationName] ,screenName: ScreenName.shelf)
            case .importFile:
                shelfViewModel.delegate?.didClickImportNotebook()
                track(EventName.shelf_importfile_tap, params: [EventParameterKey.location: locationName] ,screenName: ScreenName.shelf)
            }
        } label: {
            topSectionView
                .padding()
                .background(isFirsttime && shelfViewModel.isInHomeMode ? Color.appColor(.secondaryLight) : Color.appColor(.white20))
                .cornerRadius(16)
                .border(Color.appColor(.accentBorder),
                        width:1.0,
                        cornerRadius: 16)
        }
        .macOnlyTapAreaFixer()
        .accessibilityHint(type.accessibilityHint)
    }

    @ViewBuilder
    private var topSectionView: some View {
        if  !shelfViewModel.isInHomeMode && geometrySize < 600 || geometrySize < 600 && !shelfViewModel.shouldShowGetStartedInfo || geometrySize < 450 && shelfViewModel.shouldShowGetStartedInfo {
            VStack(alignment: .leading) {
                gridcomponetImageView
                VStack(alignment: .leading) {
                    gridcomponettitleAndDescription
                }
            }
            .frame(maxWidth: .infinity,alignment: .leading)
            .frame(minHeight: 60)
//            .frame(height: shelfViewModel.isInHomeMode && shelfViewModel.shouldShowGetStartedInfo ? 135.0 : 60.0)
        } else {
            HStack{
                gridcomponetImageView
                VStack(alignment: .leading){
                    gridcomponettitleAndDescription
                }
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .leading)
        }
    }
    
    func isLargeSize() -> Bool {
        let largeSizes: [DynamicTypeSize] = [.accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5]
        return largeSizes.contains(dynamicTypeSize)
    }
}

extension FTShelfTopSectionItem {
    @ViewBuilder
    var gridcomponettitleAndDescription: some View {
        Text(type.displayTitle)
            .foregroundColor(.appColor(.black1))
            .font(Font.appFont(for: .medium, with: 15))
            .padding(.bottom,1)
            .lineLimit(2)
        
        if isFirsttime && shelfViewModel.isInHomeMode{
            Text(type.description)
                .font(.appFont(for: .regular, with: 13))
                .foregroundColor(.appColor(.black70))
                .multilineTextAlignment(.leading)
                .font(Font.appFont(for: .regular, with: 13))
        }
    }
    @ViewBuilder
    var gridcomponetImageView: some View {
        Image(isFirsttime ? type.largeiconName : type.iconName)
//            .resizable()
//            .scaledToFit()
            .frame(minWidth: imageSize(),minHeight: imageSize())
    }
    private func imageSize() -> CGFloat {
        if shelfViewModel.isInHomeMode && isFirsttime && geometrySize > 500 {
            return FTShelfTopSectionviewConstants.regularImageSize
        } else if geometrySize < 500 && shelfViewModel.shouldShowGetStartedInfo {
            return FTShelfTopSectionviewConstants.compactRegularImageSize
        } else {
            return FTShelfTopSectionviewConstants.verticalImageSize
        }
    }
}
extension View {
    func border(_ color: Color, width: CGFloat, cornerRadius: CGFloat) -> some View {
        overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(color, lineWidth: width))
    }
}
struct PortraitGridItem_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfTopSectionItem(type: .quicknote, isFirsttime: true, geometrySize: 400.0, shelfViewModel: FTShelfViewModel(sidebarItemType: .home))
    }
}
