//
//  FTPenShortcutView.swift
//  Noteshelf3
//
//  Created by Narayana on 14/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTPenShortcutView: View {
    @StateObject var colorModel: FTFavoriteColorViewModel
    @StateObject var sizeModel: FTFavoriteSizeViewModel

    var body: some View {
        ZStack {
            FTShortcutBarVisualEffectView()
                .cornerRadius(100.0)
            VStack(spacing: 0.0) {
                FTPenColorShortcutView()
                    .environmentObject(colorModel)
                    .padding(.vertical, 8.0)
                FTToolSeperator()
                    .padding(.vertical, 2.0)
                FTPenSizeShortcutView()
                    .environmentObject(sizeModel)
                    .padding(.vertical, 6.0)
            }
        }
        .toolbarOverlay()
    }
}

struct FTPenShortcutView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // test preview here
        }
    }
}
