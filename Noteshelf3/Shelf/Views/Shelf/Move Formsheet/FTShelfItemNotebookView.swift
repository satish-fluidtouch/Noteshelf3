//
//  FTShelfItemNotebookView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 22/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShelfItemNotebookView: View {
    var isLastItemInList: Bool = false
    @ObservedObject var notebookItem: FTShelfNotebookItem
    @State var defaultCoverImage: UIImage? = UIImage.shelfDefaultNoCoverImage
    @EnvironmentObject var viewModel: FTShelfItemsViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing:0.0){
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                VStack(alignment: .center){
                Image(uiImage: defaultCoverImage!)
                    .resizable()
                    .frame(width: notebookCoverSize.width,
                           height: notebookCoverSize.height,
                           alignment: Alignment.center)
                    .cornerRadius(nbLeftRadius, corners: [.topLeft,.bottomLeft])
                    .cornerRadius(nbRightRadius, corners: [.topRight,.bottomRight])
                    .zIndex(1)
                    .if(colorScheme == .light, transform: { view in
                        view.shadow(color: .appColor(.black8), radius: 1.41, x: 0, y: 0.56)
                            .shadow(color:.appColor(.black8), radius: 4.85, x:0, y:2.91)
                    })
                    }
                .frame(width: notebookCoverContainerSize.width,height: notebookCoverContainerSize.height,alignment: .center)
                .padding(.leading,12)
                .padding(.trailing,12)
                VStack(alignment: .leading,spacing: 0.0) {
                    Text(notebookItem.title)
                        .fontWeight(.regular)
                        .appFont(for: .regular, with: 17)
                        .foregroundColor(.primary)
                    Text(notebookItem.subTitle ?? "")
                        .fontWeight(.regular)
                        .appFont(for: .regular, with: 15)
                        .foregroundColor(.appColor(.black50))
                }
                Spacer()
                Image(icon: .checkmark)
                    .foregroundColor(Color.appColor(.accent))
                    .frame(width: 10, height: 24, alignment: SwiftUI.Alignment.center)
                    .font(Font.appFont(for: .regular, with: 17))
                    .padding(.trailing, 20)
                    .isHidden(!(viewModel.selectedShelfItemToMove?.uuid == notebookItem.notebook?.uuid))
        }
        }
        .frame(minHeight: 63.0,maxHeight: 63.0,alignment: .center)
        .contentShape(Rectangle())
            if !isLastItemInList {
                Rectangle()
                    .frame(height: 0.5,alignment: .bottom)
                    .foregroundColor(.appColor(.black10))
            }
    }
            .onFirstAppear(perform: {
                notebookItem.fetchCoverImage { coverImage in
                    defaultCoverImage = coverImage
                }
            })
    }

    private var notebookCoverContainerSize: CGSize {
        return CGSize(width: 41, height: 44)
    }
    private var notebookCoverSize: CGSize {
        if defaultCoverImage?.isLandscapeCover() ?? false {
            return CGSize(width: 41, height: 31)
        }else {
            return CGSize(width: 33, height: 44)
        }
    }
    private var nbLeftRadius: CGFloat {
        if defaultCoverImage?.needEqualCorners ?? false || notebookItem.isNotDownloaded {
            return 2.5
        }else {
            return 0.97
        }
    }
    private var nbRightRadius: CGFloat {
        if defaultCoverImage?.needEqualCorners ?? false || notebookItem.isNotDownloaded {
            return 2.5
        }else {
            return 2.43
        }
    }
}
