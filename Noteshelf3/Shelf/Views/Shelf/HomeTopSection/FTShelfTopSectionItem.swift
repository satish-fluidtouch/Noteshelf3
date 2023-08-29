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
    
    @StateObject var shelfViewModel: FTShelfViewModel
    
    var body: some View {
        Button {
            switch type {
            case .quicknote:
                shelfViewModel.quickCreateNewNotebook()
            case .newNotebook:
                shelfViewModel.delegate?.showNewBookPopverOnShelf()
            case .importFile:
                shelfViewModel.delegate?.didClickImportNotebook()
            }
        } label: {
            topSectionView
                .padding()
                .macOnlyTapAreaFixer()
        }
        .background(isFirsttime && shelfViewModel.isInHomeMode ? Color.appColor(.secondaryLight) : Color.appColor(.white20))
        .cornerRadius(16)
        .border(Color.appColor(.accentBorder),
                width:1.0,
                cornerRadius: 16)
    }

    @ViewBuilder
    private var topSectionView: some View {
        if  !shelfViewModel.isInHomeMode && geometrySize < 600 || geometrySize < 600 && !shelfViewModel.shouldShowGetStartedInfo || geometrySize < 450 && shelfViewModel.shouldShowGetStartedInfo {
            VStack(alignment: .leading){
                gridcomponetImageView
                VStack(alignment: .leading){
                    gridcomponettitleAndDescription
                }
            }
            .frame(maxWidth: .infinity,alignment: .leading)
            .frame(height: shelfViewModel.isInHomeMode && shelfViewModel.shouldShowGetStartedInfo ? 135.0 : 60.0)
        }else{
            HStack{
                gridcomponetImageView
                VStack(alignment: .leading){
                    gridcomponettitleAndDescription
                }
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .leading)
        }
    }
}

extension FTShelfTopSectionItem{
    @ViewBuilder
    var gridcomponettitleAndDescription: some View {
        Text(type.displayTitle)
            .foregroundColor(.appColor(.black1))
            .font(Font.appFont(for: .medium, with: 15))
            .padding(.bottom,1)
        
        if isFirsttime && shelfViewModel.isInHomeMode{
            Text(type.description)
                .font(.appFont(for: .regular, with: 13))
                .foregroundColor(.appColor(.black70))
                .multilineTextAlignment(.leading)
                .font(Font.appFont(for: .regular, with: 13))
        }
    }
    var gridcomponetImageView: some View {
        Image(isFirsttime ? type.largeiconName : type.iconName)
            .resizable()
            .scaledToFit()
            .frame(width: shelfViewModel.isInHomeMode && isFirsttime && geometrySize > 400 ? 64.0 : (geometrySize < 400 && shelfViewModel.shouldShowGetStartedInfo ? 48.0 : 36.0),
                   height: shelfViewModel.isInHomeMode && isFirsttime && geometrySize > 400  ? 64.0 : (geometrySize < 400 && shelfViewModel.shouldShowGetStartedInfo ? 48.0 : 36.0))
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
