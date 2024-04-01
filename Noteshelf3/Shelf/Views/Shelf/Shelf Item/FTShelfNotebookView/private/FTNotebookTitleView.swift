//
//  FTNotebookTitleView.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 19/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

struct FTNotebookTitleView: View {
    @EnvironmentObject var shelfItem: FTShelfItemViewModel
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    let formatter = FTShortStyleDateFormatter.shared
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        VStack(alignment: shelfViewModel.displayStlye == .List ? .leading : .center, spacing: isLargeSize() ? 6 : 2) {
            HStack(alignment: .top,spacing:4) {
                Text(shelfItem.title)
                    .appFont(for: .medium, with: 16)
//                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.primary)
                    .lineLimit(isLargeSize() ? 2 : titleLineLimit)
                    .padding(.top,2)
                    .if(shelfViewModel.displayStlye != .List, transform: { view in
                        view.multilineTextAlignment(.center)
                    })
                    if shelfViewModel.displayStlye == .List {
                        Spacer()
                    }
            }
            VStack(alignment: shelfViewModel.displayStlye == .List ? .leading : .center,spacing: isLargeSize() ? 6 : 2) {
                if shelfViewModel.showNotebookModifiedDate {
                    Text(formatter.shortStyleFormat(for: shelfItem.model.fileModificationDate))
                        .appFont(for: .regular, with: 13)
                        .frame(minHeight: 18,alignment:.center)
                        .lineLimit(isLargeSize() ? 2 : 1)
                        .foregroundColor(Color.appColor(.black70))
                }
                if shelfViewModel.collection.isAllNotesShelfItemCollection {
                    Text(displayTitle)
                        .appFont(for: .regular, with: 13)
//                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(Color.appColor(.black50))
                        .lineLimit(isLargeSize() ? 2 : 1)
                }
            }
        }
//        .frame(height: 60,alignment:shelfViewModel.displayStlye == .List ? .center : .top)
    }
    
   func isLargeSize() -> Bool {
       return isLargerTextEnabled(for: dynamicTypeSize)
   }

    private var displayTitle: String {
        let displayTitle: String
        if let collection = shelfItem.model.shelfCollection, collection.isUnfiledNotesShelfItemCollection {
            displayTitle = shelfItem.model.URL.displayRelativePathWRTCollection().deletingLastPathComponent.replacingOccurrences(of: uncategorizedShefItemCollectionTitle, with: NSLocalizedString("sidebar.topSection.unfiled", comment: "Unfiled"));
        } else  {
           displayTitle = shelfItem.model.URL.displayRelativePathWRTCollection().deletingLastPathComponent
        }
        return displayTitle
    }
    private var titleLineLimit: Int {
        if shelfViewModel.collection.isAllNotesShelfItemCollection {
            return shelfViewModel.showNotebookModifiedDate ? 1 : 2
        }
        return 2
    }
}
