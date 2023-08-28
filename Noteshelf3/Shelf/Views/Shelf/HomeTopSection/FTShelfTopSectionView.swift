//
//  ContentView.swift
//  DynamicGridView
//
//  Created by Rakesh on 11/04/23.
//

import SwiftUI

struct FTShelfTopSectionView: View {

    @EnvironmentObject private var shelfViewModel:FTShelfViewModel
    
    var body: some View {
        VStack{
            WidthThresholdReader(widthThreshold: 550) { proxy in
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

                    if proxy.width < 700 && shelfViewModel.isInHomeMode || proxy.width < 500 && !shelfViewModel.isInHomeMode {
                        Grid {
                            GridRow{
                                getShelfDetailViewItem(.quicknote,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.width)
                                    .gridCellColumns(2)
                            }
                            GridRow{
                                getShelfDetailViewItem(.newNotebook,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.width)
                                getShelfDetailViewItem(.importFile,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.width)
                            }
                        }
                    }else{
                        Grid {
                            GridRow {
                                getShelfDetailViewItem(.quicknote,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.width)
                                getShelfDetailViewItem(.newNotebook,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.width)
                                getShelfDetailViewItem(.importFile,
                                                       shelfViewModel: shelfViewModel,
                                                       geometrySize: proxy.width)
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
    }
}

struct FTShelfTopSectionView_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfTopSectionView()
    }
}
