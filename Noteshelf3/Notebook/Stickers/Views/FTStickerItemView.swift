//
//  StickersListView.swift
//  ShowStickers
//
//  Created by Rakesh on 01/03/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct FTStickerItemView:View{
    @ObservedObject var viewModel = FTStickerRecentItemViewModel()

    var model: FTStickerCategoriesViewModel?
    let stickerSubCategory: FTStickerSubCategory?

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
                                viewModel.saveSticker(stickerInfo: subitem)
                                model?.stickerDelegate?.didTapSticker(with: UIImage(named: subitem.image) ?? UIImage())
                            }
                    }
                }
                .padding(.horizontal,16)
                .padding(.bottom,16)
            }
        }
        .background(Color.appColor(.popoverBgColor))
        .onDrop(of: [UTType.data.identifier], delegate: FTStickerDropDelegate(viewModel: model!))
    }
}

