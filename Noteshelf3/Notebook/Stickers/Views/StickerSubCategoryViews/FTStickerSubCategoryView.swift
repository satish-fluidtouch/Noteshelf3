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

    init(stickerSubCategory: [FTStickerSubCategory], model: FTStickerCategoriesViewModel, ontap: ( (FTStickerSubCategory) -> Void)? = nil) {
        self.stickerSubCategory = stickerSubCategory
        self.ontap = ontap
        self.model = model
    }
    
    private let columns = [
      GridItem(.fixed(120))
    ]
    
    var body: some View {
        ScrollView(.horizontal,showsIndicators: false) {
            LazyHGrid(rows: columns, spacing: 10) {
                ForEach(stickerSubCategory,id: \.title){ stickersubcat in
                    NavigationLink(destination:FTStickerItemView(model: model, stickerSubCategory: stickersubcat)) {
                        StickerCategoryTileView(image: UIImage(named: stickersubcat.image) ?? UIImage(), title: stickersubcat.title)
                    }
                }
            }
            .padding(.trailing,10)
        }
    }
}
