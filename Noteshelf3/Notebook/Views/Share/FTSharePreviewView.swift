//
//  FTSharePreviewView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 28/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTSharePreviewView: View {

    @EnvironmentObject var viewModel: FTShareFormatViewModel
    var body: some View {
        ZStack(alignment: .bottom) {
            ForEach(Array(viewModel.previewItems.enumerated()), id: \.element) { index,item in
                let previewItemView = previewViewForItem(item)
                let rotationAngle = rotationAngleForPreviewItemWithOrder(index)
                previewItemView
                    .rotationEffect(Angle(degrees:rotationAngle))
                    .zIndex(Double(-index))
            }
        }
        .onAppear {
        }
    }

    private func previewViewForItem(_ item: FTSharePreviewItemViewModel) -> some View {
        VStack {
            if let groupItem = item as? FTShareGroupItemPreviewViewModel {
                groupCoverViewForGroupItem(groupItem)
            } else if let notebookItem = item as? FTShareNotebookPreviewViewModel{
                FTShareNotebookPreviewView(itemViewModel: notebookItem)
            } else if let pageItem = item as? FTSharePageItemPreviewViewModel {
                FTSharePagePreviewView(itemViewModel: pageItem)
            }
        }
    }
    private func groupCoverViewForGroupItem(_ groupItem: FTShareGroupItemPreviewViewModel) -> some View {
        FTGroupCoverViewNew(groupModel: groupItem.group,
                            groupCoverViewModel: groupItem.groupCoverViewModel,
                            groupWidth: 214,
                            groupHeight: 298,
                            coverViewPurpose:.shareFormsheet)
        .frame(width: 214,height: 298,alignment: .center)
        .shadow(color: Color.appColor(.black8), radius: 5,x: 0,y: 2)
        .shadow(color: Color.appColor(.black8), radius: 20,x: 0,y: 12)
    }
    private func rotationAngleForPreviewItemWithOrder(_ order: Int) -> Double {
        if order == 1 {
            return 3
        } else if order == 2 {
            return -5
        }
        return 0
    }
}
struct FTShareNotebookPreviewView: View, FTShareBasePreviewView {
    @ObservedObject var itemViewModel: FTSharePreviewItemViewModel
    @EnvironmentObject var viewModel: FTShareFormatViewModel
    var body: some View {
        VStack(alignment: .center) {
            Image(uiImage: itemViewModel.coverImage!)
                .resizable()
                .frame(width: coverImageSize.width,height: coverImageSize.height,alignment: .bottom)
                .cornerRadius(leftCornerRadius, corners: [.topLeft, .bottomLeft])
                .cornerRadius(rightCornerRadius, corners: [.topRight, .bottomRight])
                .if(needEqualCorner) { view in
                    view.shadow(color: Color.appColor(.black8), radius: 5,x: 0,y: 2)
                        .shadow(color: Color.appColor(.black8), radius: 20,x: 0,y: 12)
                }
                .if(!needEqualCorner) { view in
                    view.shadow(color: Color.appColor(.black8), radius: 7.86,x: 0,y: 3.14)
                        .shadow(color: Color.appColor(.black8), radius: 31.47,x: 0,y: 18.88)
                }
        }
        .frame(width: coverImageSize.width,height: coverImageSize.height,alignment: .bottom)
        .onAppear {
            if let notebookItemVM = itemViewModel as? FTShareNotebookPreviewViewModel {
                notebookItemVM.fetchThumbnailsForShelfItem(notebookItemVM.shelfItem)
            }
        }
    }
    private var needEqualCorner: Bool {
        var needEqualCorners: Bool = false
        if let coverImage = itemViewModel.coverImage ,(coverImage.needEqualCorners || coverImage.isDefaultCover) {
            needEqualCorners = true
        }
        return needEqualCorners
    }
    private var coverImageSize: CGSize {
        var size = CGSize(width: 214, height: 298)
        if let coverImage = itemViewModel.coverImage, coverImage.size.width > coverImage.size.height {
            size = CGSize(width: 214, height: 154)
        }
        return size
    }
}
struct FTSharePagePreviewView: View, FTShareBasePreviewView {
    @ObservedObject var itemViewModel: FTSharePreviewItemViewModel
    @EnvironmentObject var viewModel: FTShareFormatViewModel

    var body: some View {
        VStack(alignment: .center) {
            Image(uiImage: itemViewModel.coverImage!)
                .resizable()
                .frame(width: pageImageSize.width,height: pageImageSize.height,alignment: .bottom)
                .cornerRadius(nbleftCornerRadius, corners: [.topLeft, .bottomLeft])
                .cornerRadius(nbRightCornerRadius, corners: [.topRight, .bottomRight])
                .shadow(color: Color.appColor(.black8), radius: 5,x: 0,y: 2)
                .shadow(color: Color.appColor(.black8), radius: 20,x: 0,y: 12)
                .if(viewModel.option == .allPages && viewModel.bookHasStandardCover) { view in
                    view.shadow(color: Color.appColor(.black8), radius: 7.86,x: 0,y: 3.14)
                        .shadow(color: Color.appColor(.black8), radius: 31.47,x: 0,y: 18.88)
                }
        }
        .frame(width: pageImageSize.width,height: pageImageSize.height,alignment: .bottom)
        .onAppear {
            if let pageItemVM = itemViewModel as? FTSharePageItemPreviewViewModel {
                pageItemVM.fetchPageThumbnail()
            }
        }
    }
    private var pageImageSize: CGSize {
        var size = CGSize(width: 214, height: 298)
        if let coverImage = itemViewModel.coverImage, coverImage.size.width > coverImage.size.height {
            size = CGSize(width: 214, height: 154)
        }
        return size
    }
    private var nbleftCornerRadius: CGFloat {
        var cornerRadius: CGFloat = leftCornerRadius
        if viewModel.option == .allPages,viewModel.bookHasStandardCover {
            cornerRadius = FTShelfItemProperties.Constants.Notebook.portNBCoverleftCornerRadius
        }
        return cornerRadius
    }
    private var nbRightCornerRadius: CGFloat {
        var cornerRadius: CGFloat = leftCornerRadius
        if viewModel.option == .allPages,viewModel.bookHasStandardCover {
            cornerRadius = FTShelfItemProperties.Constants.Notebook.portNBCoverRightCornerRadius
        }
        return cornerRadius
    }
}

struct FTSharePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        FTSharePreviewView()
    }
}
