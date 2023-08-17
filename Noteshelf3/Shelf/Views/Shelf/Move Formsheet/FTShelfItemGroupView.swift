//
//  FTShelfItemGroupView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 22/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShelfItemGroupView: View {
    @ObservedObject var groupItem: FTShelfGroupItem
    var isLastItemInList: Bool = false
    var body: some View {
        VStack(alignment: .leading,spacing:0.0) {
            HStack(alignment: .center,spacing: 0.0) {
                FTGroupCoverViewNew(groupModel: groupItem.group,
                                    groupCoverViewModel: groupCoverViewModel,
                                    groupWidth: groupCoverSize.width,
                                    groupHeight: groupCoverSize.height,
                                    coverViewPurpose:.movePopover)
                .environmentObject(groupItem)
                .frame(width: groupCoverContainerSize.width,height: groupCoverContainerSize.height,alignment: .center)
                .padding(.leading,12)
                VStack(alignment: .leading,spacing: 0.0) {
                    Text(groupItem.title)
                        .fontWeight(.regular)
                        .appFont(for: .regular, with: 16)
                        .foregroundColor(.primary)
                    Text(groupItem.subTitle ?? "")
                        .fontWeight(.regular)
                        .appFont(for: .regular, with: 14)
                        .foregroundColor(.appColor(.black50))
                }
                .padding(.leading,16)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.appColor(.black50))
                    .frame(width: 10, height: 24, alignment: SwiftUI.Alignment.center)
                    .font(Font.appFont(for: .regular, with: 15))
                    .padding(.trailing, 16)
            }
            .frame(minHeight: 61.0,maxHeight: 61.0,alignment: .center)
            .contentShape(Rectangle())
            if !isLastItemInList {
                Rectangle()
                    .frame(height: 0.5,alignment: .bottom)
                    .foregroundColor(.appColor(.black10))
            }
        }
    }
    private var groupCoverContainerSize: CGSize {
        CGSize(width: 41, height: 44)
    }
    private var groupCoverViewModel: FTGroupCoverViewModel {
        return groupItem.groupCoverViewModel
    }
    private var groupCoverSize: CGSize {
        CGSize(width: 33, height: 44)
    }
}

//struct FTShelfItemGroupView_Previews: PreviewProvider {
//    static var previews: some View {
//        FTShelfItemGroupView(groupItem: FTShelfGroupItem(group: <#T##FTGroupItemProtocol#>)  FTShelfItems(collection: FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection))
//    }
//}
