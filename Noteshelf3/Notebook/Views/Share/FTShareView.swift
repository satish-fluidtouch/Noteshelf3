//
//  FTShareView.swift
//  Noteshelf3
//
//  Created by Narayana on 02/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTShareView: View {
    let viewModel: FTShareViewModel
    private let displayableOptions: [FTShareOption] = [.currentPage,.allPages, .selectPages]
    private let rightCornerRadius: CGFloat = 2.0
    var showBackButton = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .center, spacing: 10.0) {
                shareHeaderView.frame(height: 44)
                VStack(spacing: 0.0) {
                    ForEach(displayableOptions.indices, id: \.self) { index in
                        let option = displayableOptions[index]
                        HStack(spacing: FTSpacing.large) {
                            let thumbImage = viewModel.getthumbnailImage(option: option)
                            Image(uiImage: thumbImage)
                                .resizable()
                                .frame(width: thumbnailSizeForImage(thumbImage).width, height: thumbnailSizeForImage(thumbImage).height)
                                .cornerRadius(leftCornerRadiusForOption(option), corners: [.topLeft, .bottomLeft])
                                .cornerRadius(rightCornerRadius, corners: [.topRight, .bottomRight])
                                .if(option == .currentPage || (option == .allPages && !viewModel.info.bookHasStandardCover)) { view in
                                    view.shadow(color: Color.appColor(.black8), radius: 1.40,x: 0,y: 0.56)
                                        .shadow(color: Color.appColor(.black8), radius: 5.6,x: 0,y: 3.3)
                                }
                                .if((option == .allPages && viewModel.info.bookHasStandardCover)) { view in
                                    view.shadow(color: Color.appColor(.black8), radius: 1.21,x: 0,y: 0.48)
                                        .shadow(color: Color.appColor(.black8), radius: 4.85,x: 0,y: 2.91)
                                }
                            VStack(alignment: .leading){
                                Text(option.displayTitle)
                                    .appFont(for: .regular, with: 17)
                                    .foregroundColor(Color.appColor(.black1))
                                if viewModel.getPagetitleinfo(option: option) != ""{
                                    Text(viewModel.getPagetitleinfo(option: option))
                                        .appFont(for: .regular, with: 15)
                                        .foregroundColor(.appColor(.black50))
                                }
                            }
                            Spacer()
                            if option.showChevron {
                                Image(icon: .rightArrow)
                                    .font(Font.appFont(for: .regular, with: 17))
                                    .fontWeight(.regular)
                                    .foregroundColor(.appColor(.black50))
                            }
                        }
                        .frame(height: 62)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.viewModel.handleShareOptionSelection(option)
                        }
                        if(index < displayableOptions.count - 1) {
                            FTDividerLine()
                        }
                    }
                    .padding(.horizontal, FTSpacing.large)
                    .background(Color.appColor(.cellBackgroundColor))
                }
                .background(Color.appColor(.popoverBgColor))
                .cornerRadius(10.0)
                .padding(.horizontal, FTSpacing.large)
            }.padding(.top, 10)
        }
        .scrollDisabled(true)
    }
    
    private var shareHeaderView: some View {
        HStack{
            if showBackButton { 
                Button {
                    self.viewModel.delegate?.didTapBackButton()
                } label: {
                    Image(icon: .leftArrow)
                        .font(Font.appFont(for: .regular, with: 20))
                        .fontWeight(.regular)
                        .foregroundColor(Color.appColor(.accent))
                }
                .padding(.leading,0)
                .padding(.trailing,20)
            }
            Spacer()
            Text("Share".localized)
                .font(.clearFaceFont(for: .medium, with: 20))
                .padding(.leading,-30)
            Spacer()
        }
        .padding()
    }
    private func leftCornerRadiusForOption(_ option: FTShareOption)-> CGFloat {
        var radius : CGFloat = 2.0
        if option == .allPages, viewModel.info.bookHasStandardCover {
            radius = 1
        }
        return radius
    }

    private func thumbnailSizeForImage(_ image: UIImage) -> CGSize {
        var size = CGSize(width: 33, height: 44)
        if image.size.width > image.size.height {
            size = CGSize(width: 33, height: 26)
        }
        return size
    }
}

struct FTShareView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            FTShareView(viewModel: FTShareViewModel(info: FTShareOptionsInfo(currentPageThumbnail: UIImage(), bookCover: UIImage(), currentPageNumber: 0, allPagesCount: 0)))
        }
    }
}
