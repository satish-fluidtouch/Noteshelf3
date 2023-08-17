//
//  FTShelfItemCategoryView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 21/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTShelfItemCategoryView: View {
    @ObservedObject var shelfItem: FTShelfItems
    var isLastItemInList: Bool = false
    var body: some View {
        VStack(spacing:0.0) {
            VStack(alignment: .center) {
                HStack(alignment: .center, spacing:0) {
                    Image(uiImage:UIImage(named: "folderIcon")!)
                        .frame(width: 51, height: 41,alignment: .center)
                        .padding(.top,7)
                        .padding(.leading,6)
                        .padding(.trailing,9)
                        .shadow(color: Color.appColor(.black16), radius: 1, x:0, y: 1)
                    Text(shelfItem.title)
                        .frame(alignment: .leading)
                        .appFont(for: .regular, with: 17)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.appColor(.black50))
                        .frame(width: 10, height: 24, alignment: SwiftUI.Alignment.center)
                        .font(Font.appFont(for: .regular, with: 17))
                        .padding(.trailing, 16)
                }
            }
            .frame(height: 63,alignment: .center)
            .contentShape(Rectangle())
            if !isLastItemInList {
                Rectangle()
                    .frame(height: 0.5,alignment: .bottom)
                    .foregroundColor(.appColor(.black10))
            }
        }

    }
}

struct FTShelfItemCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfItemCategoryView(shelfItem: FTShelfItems(collection: FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection))
    }
}
