//
//  FTDownloadedStickersView.swift
//  StickerModule
//
//  Created by Rakesh on 16/03/23.
//

import SwiftUI

struct FTDownloadedStickersView: View {
    
    @State private var isShowDeleteButton = false
    @ObservedObject var downloadedviewModel = FTDownloadedStickerViewModel()
    @ScaledMetric var titleSize:CGFloat = 12
    @ObservedObject var stickerCategoryViewModel: FTStickerCategoriesViewModel
    @State private var showAlert = false    

    private let columns = [
      GridItem(.fixed(120))
    ]
    
    var body: some View {
        VStack{
            if downloadedviewModel.downloadedStickers.count > 0 {
                HStack{
                    CategoryTitleHeaderView(titleName: "downloadedStickers".localized)
                    Spacer()
                    Button {
                        isShowDeleteButton.toggle()
                    } label: {
                        Text(isShowDeleteButton ? "Done".localized : "Edit".localized)
                            .appFont(for: .regular, with: 15)
                            .foregroundColor(Color.appColor(.accent))
                    }
                    .macOnlyPlainButtonStyle()
                }
                    ScrollView(.horizontal,showsIndicators: false) {
                        LazyHGrid(rows: columns,alignment: .center, spacing: 11) {
                            ForEach(downloadedviewModel.downloadedStickers,id: \.title) { downloadModel in
                                NavigationLink(destination:FTStickerItemView(model: stickerCategoryViewModel, stickerSubCategory: downloadModel)) {
                                    VStack(alignment: .center){
                                        Image(uiImage: downloadedviewModel.getDownloadedStickerThumbnail(downloadModel.filename) ?? UIImage())
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 120,height: 120)
                                            .cornerRadius(8.0)
                                            .background(.clear)
                                            .overlay(isShowDeleteButton ? deleteview(model: downloadModel) : nil ,alignment:.topTrailing)

                                            Text(downloadModel.title)
                                            .appFont(for: .medium, with: titleSize)
                                            .foregroundColor(Color.label)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                }
                                .macOnlyPlainButtonStyle()
                            }
                        }
                    }
            }
        }
        .padding(.trailing,10)
        .onFirstAppear{
            stickerCategoryViewModel.menuItems.append("downloadedStickers".localized)
        }
    }
    
    func deleteview(model: FTStickerSubCategory) -> some View {
        return Button(action: {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)){
                withAnimation {
                    do {
                        try downloadedviewModel.removeDownloadedStickers(item: model)
                        downloadedviewModel.downloadedStickers.removeAll(where: { $0.title == model.title })
                        if downloadedviewModel.downloadedStickers.isEmpty{
                            stickerCategoryViewModel.menuItems.removeLast()
                        }
                    } catch {
                        downloadedviewModel.error = error
                        showAlert = true
                    }
                    isShowDeleteButton.toggle()
                }
            }
        }, label: {
            FTStickerDeleteImage(imagename: "trash")
        })
        .macOnlyPlainButtonStyle()
        .alert(isPresented: $showAlert) {
            return Alert(title: Text("stickers.alert.error".localized), message: Text(downloadedviewModel.error?.localizedDescription ?? "UnexpectedError".localized), dismissButton: .default(Text("stickers.alert.ok".localized)))
        }
    }
}
