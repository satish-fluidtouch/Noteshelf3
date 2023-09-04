//
//  FTMigrationView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 10/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTMigrationMessageView: View,FTShelfBaseView {
    var viewModel: FTShelfViewModel
    var body: some View {
        HStack(alignment: .center, spacing:16) {
            Image(uiImage: UIImage(named: "migrationIcon")!)
                .frame(width: 32,height: 32,alignment: .center)
            VStack(alignment: .leading, spacing:0) {
                Text(NSLocalizedString("shelf.migration.headerMessage", comment: "Migrate your notebooks to Noteshelf 3"))
                    .multilineTextAlignment(.leading)
                    .font(.appFont(for: .medium, with: 13))
                    .foregroundColor(.appColor(.black1))

                Text(NSLocalizedString("shelf.migration.Description", comment: "To migrate your book to Noteshef 3, tap on it or long-press  and choose the migration option from the menu."))
                    .font(.appFont(for: .regular, with: 13))
                    .foregroundColor(.appColor(.black1))
                    .multilineTextAlignment(.leading)
            }
            Spacer()
        }
        .padding(.vertical,12.5)
        .padding(.horizontal,16)
        .background(Color.appColor(.migrationHeaderBG))
        .border(Color.appColor(.migrationHeaderBorderBG), width: 0.5,cornerRadius: 12)
        .cornerRadius(12)
    }
}
struct FTMigrationMessage_Previews: PreviewProvider {
    static var previews: some View {
        FTMigrationMessageView(viewModel: FTShelfViewModel(sidebarItemType: .home))
    }
}

