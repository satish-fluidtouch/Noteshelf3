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

                    if proxy.isCompact && shelfViewModel.shouldShowGetStartedInfo && shelfViewModel.isInHomeMode{
                        Grid {
                            GridRow{
                                getShelfDetailViewItem(.quicknote,
                                                       isCompact: proxy.isCompact,
                                                       shelfViewModel: shelfViewModel)
                            }
                            GridRow{
                                getShelfDetailViewItem(.newNotebook,
                                                       isCompact: proxy.isCompact,
                                                       shelfViewModel: shelfViewModel)
                            }
                            GridRow{
                                getShelfDetailViewItem(.importFile,
                                                       isCompact: proxy.isCompact,
                                                       shelfViewModel: shelfViewModel)
                            }
                        }
                    }else if (proxy.width > 500 && proxy.width < 700) && shelfViewModel.shouldShowGetStartedInfo && shelfViewModel.isInHomeMode{
                        Grid {
                            GridRow{
                                getShelfDetailViewItem(.quicknote,
                                                       isCompact: proxy.isCompact,
                                                       shelfViewModel: shelfViewModel)
                                    .gridCellColumns(2)
                            }
                            GridRow{
                                getShelfDetailViewItem(.newNotebook,
                                                       isCompact: proxy.isCompact,
                                                       shelfViewModel: shelfViewModel)
                                getShelfDetailViewItem(.importFile,
                                                       isCompact: proxy.isCompact,
                                                       shelfViewModel: shelfViewModel)
                            }
                        }
                    }else{
                        Grid(horizontalSpacing: 16) {
                            GridRow {
                                getShelfDetailViewItem(.quicknote,
                                                       isCompact: proxy.isCompact,
                                                       shelfViewModel: shelfViewModel)
                                getShelfDetailViewItem(.newNotebook,
                                                       isCompact: proxy.isCompact,
                                                       shelfViewModel: shelfViewModel)
                                getShelfDetailViewItem(.importFile,
                                                       isCompact: proxy.isCompact,
                                                       shelfViewModel: shelfViewModel)
                            }
                        }
                    }
                }
            }
        }.macOnlyPlainButtonStyle()
    }
    private func getShelfDetailViewItem(_ type: FTShelfHomeTopSectionModel,isCompact:Bool,shelfViewModel:FTShelfViewModel) -> some View {
        FTShelfTopSectionItem(type: type,
                             isFirsttime: shelfViewModel.shouldShowGetStartedInfo,
                             isCompact: isCompact,
                             shelfViewModel: shelfViewModel)
    }
}

struct FTShelfTopSectionView_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfTopSectionView()
    }
}
