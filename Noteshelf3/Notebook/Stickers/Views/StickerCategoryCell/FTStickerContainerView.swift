//
//  FTStickerContainerView.swift
//  ShowStickers
//
//  Created by Rakesh on 02/03/23.
//

import SwiftUI

struct FTStickerCategoryItemView: View {
    let stickerCategoryModel: FTStickerCategory
    @ObservedObject var stickerViewModel: FTStickerCategoriesViewModel

    var body: some View {
        VStack(alignment: .leading) {
            CategoryTitleHeaderView(titleName: stickerCategoryModel.title)
            FTStickerSubCategoryView(stickerSubCategory: stickerCategoryModel.subcategories, model: stickerViewModel,stickerCategoryModel: stickerCategoryModel) { stickerInfo in
            }
        }
       
    }
}


