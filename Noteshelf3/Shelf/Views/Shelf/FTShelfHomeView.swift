//
//  FTShelfHomeView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 02/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

struct FTShelfHomeView: FTShelfBaseView {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var viewModel: FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo
    @AppStorage("discoverIsExpanded") var discoverExpandStaus: Bool = false

    let supportedDropTypes = FTDragAndDropHelper.supportedTypesForDrop()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        VStack(alignment: .center,spacing:0) {
                            /*
                             1. show description and top section in compact and ipad very first time
                             2. once a notebook is created, dont show top section in compact but show in ipad.
                             */
                            if viewModel.mode == .normal, (viewModel.shouldShowGetStartedInfo || geometry.size.width > 450) {
                                FTShelfTopSectionView()
                                    .frame(height: showMinHeight(geometrySize: geometry.size.width))
                                    .padding(.horizontal,gridHorizontalPadding)
                                    .padding(.top,10)
                                    .environmentObject(viewModel)
                            }
                            if viewModel.showNoShelfItemsView {
                                FTGetStartedPlaceHolderView(noResultsImageName: "noHomeItems",
                                                            title: "home.getStarted.title".localized,
                                                            description: "home.getStarted.descrption".localized, placeHolderType: .medium)
                                .frame(minHeight: 350)
                            } else {
                                homeShelfItemsViewForGeometrySize(geometry.size, scrollViewProxy: proxy)
                            }
                            Spacer()
                            if viewModel.shelfDidLoad {
                                FTDiscoverWhatsNewView(isExpanded: discoverExpandStaus)
                                    .environmentObject(viewModel)
                                    .macOnlyPlainButtonStyle()
                                    .padding(.horizontal,gridHorizontalPadding)
                                    .padding(.bottom,20)
                                    .padding(.top,16)
                            }
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                }

            }

        }
                .overlay(content: {
                    if viewModel.showDropOverlayView {
                        withAnimation {
                            FTDropOverlayView()
                                .environmentObject(viewModel)
                        }
                    }
                })
                .overlay(alignment: .bottom, content: {
                        FTAdBannerView()
                            .padding(.bottom,8)
                })
                .detectOrientation($viewModel.orientation)
                .shelfNavBarItems()
                .allowsHitTesting(viewModel.allowHitTesting)
                .navigationTitle(viewModel.navigationTitle)
#if targetEnvironment(macCatalyst)
                .navigationBarBackButtonHidden(true)
#else
                .navigationBarBackButtonHidden(viewModel.mode == .selection)
#endif
                .shelfBottomToolbar()
                .environmentObject(viewModel.toolbarViewModel)
                .environmentObject(viewModel)
                .onTapGesture {
                    self.hideKeyboard() // if any textfield is in editing state we exit from that mode and perform action. eg.rename category.
                }
                .onDrop(of: supportedDropTypes, delegate: FTShelfScrollViewDropDelegate(viewModel: viewModel))
        }
    private func homeShelfItemsViewForGeometrySize(_ size: CGSize, scrollViewProxy: ScrollViewProxy) -> some View {
        let homeShelfItems = homeShelfItemsForScreenSize(size)
        return VStack(spacing:0) {
            shelfGridView(items: homeShelfItems, size: size, scrollViewProxy: scrollViewProxy)
                .if(viewModel.shelfItems.count > 0, transform: { view in
                    view.padding(.top,showSeeAllOption(shelfItemsCount: homeShelfItems.count) ? 16 : 20)
                })
                    if showSeeAllOption(shelfItemsCount: homeShelfItems.count) {
                    seeAllNotesView
                        .macOnlyPlainButtonStyle()
                }
        }
    }

    private var seeAllNotesView: some View {
        Button {
            self.viewModel.didTapOnSeeAllNotes?()
        } label: {
            HStack(alignment:.center, spacing:4) {
                Text(seeAllNotesButtonTitle)
                    .frame(height: 36)
                    .font(Font.appFont(for: .medium, with: 13))
                    .foregroundColor(Color.appColor(.black70))
                Image(systemName: "chevron.right")
                    .font(Font.appFont(for: .medium, with: 13))
                    .foregroundColor(Color.appColor(.black70))
            }
            .frame(maxWidth:.infinity,alignment: .center)
            .frame(height: 36)
            .background(Color.appColor(.seeAllBtnBG))
            .cornerRadius(10)
            .padding(.horizontal,gridHorizontalPadding)
            .padding(.top,28)
        }
        .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: .slow))
    }

    private var seeAllNotesButtonTitle: String {
        let notesCount = viewModel.shelfItems.count
        let seeAllString = NSLocalizedString("shelf.home.seeAllNotes", comment: "See All Notes") + " " + "(" + "\(notesCount)" + ")"
        return seeAllString
    }

    private func homeShelfItemsForScreenSize(_ size: CGSize) -> [FTShelfItemViewModel] {
        let isInLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        if self.viewModel.isSidebarOpen {
            if isInLandscape {
                return size.width > 550 ? Array(viewModel.shelfItems.prefix(9)) : Array(viewModel.shelfItems.prefix(8))
            } else {
                return Array(viewModel.shelfItems.prefix(8))
            }
        } else {
            if isInLandscape {
                return size.width >= 820 ? Array(viewModel.shelfItems.prefix(8)) : Array(viewModel.shelfItems.prefix(9))
            } else {
                return Array(viewModel.shelfItems.prefix(9))
            }
        }
    }

    private func showSeeAllOption(shelfItemsCount:Int) -> Bool {
        viewModel.shelfItems.count > shelfItemsCount
    }
}
