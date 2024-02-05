//
//  StickersListView.swift
//  ShowStickers
//
//  Created by Rakesh on 01/03/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct FTStickerItemView:View{
    @ObservedObject var recentViewModel = FTStickerRecentItemViewModel()
    var model: FTStickerCategoriesViewModel?
    let stickerSubCategory: FTStickerSubCategory?
    @ObservedObject var downloadviewModel = FTDownloadedStickerViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 90,maximum: 100))
    ]

    var body: some View {
        VStack{
            StickerNavigationView(name: stickerSubCategory?.title ?? "")
            ScrollView(.vertical,showsIndicators: false){
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(stickerSubCategory?.stickerItems ?? [],id: \.image){ subitem in
                        StickerTileView(image: UIImage(named: subitem.image) ?? UIImage(),isFromRecent: false, title: stickerSubCategory?.title ?? "")
                            .padding(.trailing,8)
                            .onTapGesture {
                                let newSubitem = downloadviewModel.getStickerSubitem(subitem: subitem, fileName: stickerSubCategory?.filename ?? "",type: stickerSubCategory?.type ?? .staticSticker)
                                    recentViewModel.saveSticker(stickerInfo: newSubitem)
                                    model?.stickerDelegate?.didTapSticker(with: UIImage(named: newSubitem.image) ?? UIImage())
                            }
                    }
                }
                .padding(.horizontal,16)
                .padding(.bottom,16)
            }.onAppear{
                FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker
                    .nbk_addmenu_stickers_subcategory_tap,params: ["title": stickerSubCategory?.title ?? ""])
            }
        }
        .background(Color.appColor(.popoverBgColor))
        .onDrop(of: [UTType.data.identifier], delegate: FTStickerDropDelegate(viewModel: model!))
    }
}

