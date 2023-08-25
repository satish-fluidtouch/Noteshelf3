//
//  StickerView.swift
//  ShowStickers
//
//  Created by Rakesh on 06/03/23.
//

import SwiftUI

struct FTStickerSubCategoryView: View {
    let stickerSubCategory: [FTStickerSubCategory]
    var ontap: ((FTStickerSubCategory) -> Void)?
    var model: FTStickerCategoriesViewModel?
    let stickerCategoryModel: FTStickerCategory?

    init(stickerSubCategory: [FTStickerSubCategory], model: FTStickerCategoriesViewModel,stickerCategoryModel: FTStickerCategory, ontap: ( (FTStickerSubCategory) -> Void)? = nil) {
        self.stickerSubCategory = stickerSubCategory
        self.ontap = ontap
        self.model = model
        self.stickerCategoryModel = stickerCategoryModel
    }
    
    private let columns = [
      GridItem(.fixed(120))
    ]
    
    var body: some View {
        ScrollView(.horizontal,showsIndicators: false) {
            LazyHGrid(rows: columns, spacing: 10) {
                ForEach(stickerSubCategory,id: \.title){ stickersubcat in
//                    if stickerCategoryModel?.title == "Fancy Titles"{
//                        NavigationLink(destination:  FTFancyTitlesView(stickerSubCategory: stickersubcat, model: model)) {
//                            StickerCategoryTileView(image: UIImage(named: stickersubcat.image) ?? UIImage(), title: stickersubcat.title)
//                        }
//                    }else{
//                        NavigationLink(destination: FTStickerItemView(stickerSubCategory: stickersubcat, model: model)) {
//                            StickerCategoryTileView(image: UIImage(named: stickersubcat.image) ?? UIImage(), title: stickersubcat.title)
//                        }
//                    }
                    NavigationLink(destination:  FTFancyTitlesView(stickerSubCategory: stickersubcat, model: model)) {
                        StickerCategoryTileView(image: UIImage(named: stickersubcat.image) ?? UIImage(), title: stickersubcat.title)
                    }
                    .macOnlyPlainButtonStyle()
                }
            }
            .padding(.trailing,10)
        }
    }
}
