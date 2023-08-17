//
//  FTGroupTitleView.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 19/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

struct FTGroupTitleView: View {
    @EnvironmentObject var groupItem: FTGroupItemViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                Text(groupItem.title)
                    .appFont(for: .medium, with: 16)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: false)
                    .lineLimit(2)
                Spacer()
            }
            HStack(alignment: .top) {
                Text(groupItem.noOfNotes)
                    .fontWeight(.regular)
                    .appFont(for: .regular, with: 13)
                    .foregroundColor(Color.appColor(.groupNotesCountTint))
                Spacer()
            }
        }
        .frame(height: 60)
    }
}
