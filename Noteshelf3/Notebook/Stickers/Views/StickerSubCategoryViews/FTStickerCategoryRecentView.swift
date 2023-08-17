//
//  FTStickerCategoryRecentView.swift
//  StickerModule
//
//  Created by Rakesh on 14/03/23.
//

import SwiftUI

struct FTStickerCategoryRecentView: View {
    
    @EnvironmentObject private var viewModel: FTStickerCategoriesViewModel
    
    private let columns = [
        GridItem(.fixed(100))
    ]
    
    var body: some View {
        if viewModel.recentStickerItems.count > 0 {
            VStack(alignment: .leading){
                CategoryTitleHeaderView(titleName: "Recents".localized)
                ScrollView(.horizontal,showsIndicators: false) {
                    LazyHGrid(rows: columns, spacing: 8) {
                        ForEach(viewModel.recentStickerItems.reversed(), id: \.image) { subitem in
                            StickerTileView(image: UIImage(named: subitem.image) ?? UIImage(),isFromRecent: true, title: "")
                                .background(Color.appColor(.white50))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.appColor(.grayDim), lineWidth: 0.75)
                                )
                                .contextMenu{
                                    Button("useSticker".localized) {
                                        viewModel.stickerDelegate?.didTapSticker(with: UIImage(named: subitem.image) ?? UIImage())
                                    }
                                    Divider()
                                    Button(role:.destructive,action: {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)){
                                            withAnimation() {
                                                viewModel.removeRecentStickerList(subitem)
                                            }
                                        }
                                    }, label: {
                                        Text("removefromRecents".localized)
                                    })
                                }
                                .onTapGesture {
                                    viewModel.stickerDelegate?.didTapSticker(with: UIImage(named: subitem.image) ?? UIImage())
                                }
                        }
                    }
                    .padding(.trailing,10)
                    .padding(.leading,1)
                }
            }
        }
        
    }
    
}

struct FTStickerCategoryRecentView_Previews: PreviewProvider {
    static var previews: some View {
        FTStickerCategoryRecentView()
    }
}
