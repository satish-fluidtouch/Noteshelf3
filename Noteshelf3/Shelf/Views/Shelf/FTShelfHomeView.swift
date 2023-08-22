//
//  FTShelfHomeView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 02/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShelfHomeView: FTShelfBaseView {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var viewModel: FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo

    let supportedDropTypes = FTDragAndDropHelper.supportedTypesForDrop()

    var body: some View {
        GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack(alignment: .center,spacing:0) {
                        if geometry.size.width > 400 && viewModel.canShowCreateNBButtons {
                            FTShelfTopSectionView()
                                .frame(height: showMinHeight(geometrySize: geometry.size.width))
                                .padding(.horizontal,gridHorizontalPadding)
                                .padding(.top,10)
                                .environmentObject(viewModel)
                        }
                        homeShelfItemsViewForGeometrySize(geometry.size)
                        if viewModel.shelfDidLoad {
                            FTGetInspireView(viewmodel: FTGetInspiredViewModel())
                                .environmentObject(viewModel)
                                .macOnlyPlainButtonStyle()
                                .padding(.horizontal,gridHorizontalPadding)
                                .padding(.top,40)
                                .padding(.bottom,28)
                            FTDiscoverWhatsNewView()
                                .environmentObject(viewModel)
                                .macOnlyPlainButtonStyle()
                                .padding(.horizontal,gridHorizontalPadding)
                                .padding(.bottom,24)
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
                .detectOrientation($viewModel.orientation)
                .shelfNavBarItems()
                .allowsHitTesting(viewModel.allowHitTesting)
                .navigationTitle(((geometry.size.width > 400 && viewModel.shouldShowGetStartedInfo) ? "" : viewModel.navigationTitle))
#if targetEnvironment(macCatalyst)
                .navigationBarBackButtonHidden(true)
#else
                .navigationBarBackButtonHidden(viewModel.mode == .selection)
#endif
                .environmentObject(viewModel)
                .shelfBottomToolbar()
                .environmentObject(viewModel.toolbarViewModel)
                .environmentObject(viewModel)
                .onTapGesture {
                    self.hideKeyboard() // if any textfield is in editing state we exit from that mode and perform action. eg.rename category.
                }
                .onDrop(of: supportedDropTypes, delegate: FTShelfScrollViewDropDelegate(viewModel: viewModel))
        }
    }

    private func showMinHeight(geometrySize: CGFloat) -> CGFloat {
        let isInPortrait = UIScreen.main.bounds.height > UIScreen.main.bounds.width
        if viewModel.shouldShowGetStartedInfo && viewModel.isInHomeMode {
            if geometrySize < 540 {
                return geometrySize > 465 ? 416 : 456
            } else if geometrySize > 540 && geometrySize < 800 {
                return geometrySize > 600 ? 292 : 396
            } else{
                return isInPortrait ? 193 : 189
            }
        } else {
            if geometrySize < 600 || (isInPortrait && viewModel.isSidebarOpen) {
                return 96
            } else {
                return 68
            }
        }
    }

    private func homeShelfItemsViewForGeometrySize(_ size: CGSize) -> some View {
        let homeShelfItems = homeShelfItemsForScreenSize(size)
        return VStack(spacing:0) {
            shelfGridView(items: homeShelfItems, size: size)
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
            .frame(maxWidth:.infinity)
            .frame(height: 36)
        }
    .frame(maxWidth:.infinity,alignment: .center)
    .frame(height: 36)
    .background(Color.appColor(.seeAllBtnBG))
    .cornerRadius(10)
    .padding(.horizontal,gridHorizontalPadding)
    .padding(.top,28)
    }

    private var seeAllNotesButtonTitle: String {
        let notesCount = viewModel.notesCount
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
        viewModel.notesCount > shelfItemsCount
    }
}
