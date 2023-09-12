//
//  ContentView.swift
//  DynamicGridView
//
//  Created by Rakesh on 11/04/23.
//

import SwiftUI
import FTCommon

struct FTShelfTopSectionView: View {

    @EnvironmentObject private var shelfViewModel:FTShelfViewModel
    
    var body: some View {
        VStack{
            GeometryReader { proxy in
                VStack(alignment: .center,spacing: 0){
                    if shelfViewModel.shouldShowGetStartedInfo && shelfViewModel.isInHomeMode{
                        Text("shefl.home.getStartedwithNoteShelf".localized)
                            .font(.clearFaceFont(for: .medium, with: 36))
                            .foregroundColor(.appColor(.black1))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom ,1)

                        Text("shefl.home.addnotestoyourshelfbegin".localized)
                            .font(.appFont(for: .regular, with: 16))
                            .foregroundColor(.appColor(.black70))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom , 28)
                    }
                    if proxy.size.width < 935 && shelfViewModel.shouldShowGetStartedInfo && shelfViewModel.isInHomeMode || proxy.size.width < 400  {
                        Grid {
                            GridRow{
                                getShelfDetailViewItem(.quicknote,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.size.width)
                                    .gridCellColumns(2)
                            }
                            GridRow{
                                getShelfDetailViewItem(.newNotebook,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.size.width)
                                getShelfDetailViewItem(.importFile,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.size.width)
                            }
                        }
                    }else{
                        Grid {
                            GridRow {
                                getShelfDetailViewItem(.quicknote,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.size.width)
                                getShelfDetailViewItem(.newNotebook,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.size.width)
                                getShelfDetailViewItem(.importFile,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.size.width)
                            }
                        }
                    }
                }
            }
        }.macOnlyPlainButtonStyle()
    }
    private func getShelfDetailViewItem(_ type: FTShelfHomeTopSectionModel,shelfViewModel:FTShelfViewModel, geometrySize: CGFloat) -> some View {
        FTShelfTopSectionItem(type: type,
                             isFirsttime: shelfViewModel.shouldShowGetStartedInfo, geometrySize: geometrySize,
                             shelfViewModel: shelfViewModel)
        .buttonInteractionStyle(scaleValue: 0.99)
    }
}

struct FTShelfTopSectionView_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfTopSectionView()
    }
}
