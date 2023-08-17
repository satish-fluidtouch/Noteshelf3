//
//  FTShelfItemContextualMenuButtons.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 07/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShelfItemContextualMenuButtons: View {
    @ObservedObject var item: FTShelfItemViewModel
    @ObservedObject var viewModel: FTShelfItemContextualMenuViewModel
    @EnvironmentObject var shelfViewModel : FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo

    var longPressOptions: [[FTShelfItemContexualOption]] = [[]]

    var body: some View {
        ForEach(longPressOptions.indices, id: \.self) { index in
            let options = longPressOptions[index]
            ForEach(options,id: \.self) { menuOption in
                Button(role: menuOption.isDestructiveOption ? .destructive : nil) {
                    viewModel.shelfItem = item
                    shelfMenuOverlayInfo.isMenuShown = false;
                    viewModel.performAction = menuOption
                } label: {
                    Label {
                        Text(menuOption.displayTitle)
                            .fontWeight(.regular)
                            .appFont(for: .regular, with: 15)
                            .foregroundColor(Color(menuOption.foreGroundColor))
                    } icon: {
                        Image(icon: menuOption.icon)
                            .frame(width: 16, height: 24, alignment: SwiftUI.Alignment.center)
                            .foregroundColor(Color(menuOption.foreGroundColor))
                            .font(Font.appFont(for: .regular, with: 15))
                    }
                }
            }
            Divider()
        }
    }
}
