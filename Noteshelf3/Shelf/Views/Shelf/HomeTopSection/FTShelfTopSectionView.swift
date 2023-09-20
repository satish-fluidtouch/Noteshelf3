//
//  ContentView.swift
//  DynamicGridView
//
//  Created by Rakesh on 11/04/23.
//

import SwiftUI
import FTCommon

struct FTShelfTopSectionView: View {

    @EnvironmentObject private var shelfViewModel: FTShelfViewModel
    
    var body: some View {
        VStack{
            WidthThresholdReader(widthThreshold: 550) { proxy in
                VStack(alignment: .center,spacing: 0){
                    if proxy.width < 935 && shelfViewModel.shouldShowGetStartedInfo && shelfViewModel.isInHomeMode || proxy.width < 400  {
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
        }
    }
    private func getShelfDetailViewItem(_ type: FTShelfHomeTopSectionModel,shelfViewModel:FTShelfViewModel, geometrySize: CGFloat) -> some View {
        FTShelfTopSectionItem(type: type,
                             isFirsttime: shelfViewModel.shouldShowGetStartedInfo, geometrySize: geometrySize,
                             shelfViewModel: shelfViewModel)
        .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: 0.92))
    }
}

struct FTShelfTopSectionView_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfTopSectionView()
    }
}

struct FTShelfGetStartedDescription: View {

    var body: some View {
            VStack{
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
            }
            .padding(.bottom , 28)
            .padding(.horizontal,16)
        }
}

struct FTShelfGetStartedDescription_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfGetStartedDescription()
    }
}

