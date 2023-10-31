//
//  FTPenSizeView.swift
//  Noteshelf3
//
//  Created by Narayana on 21/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles
import FTCommon

struct FTPenSizeView: View {
    let isSelected: Bool
    let showIndicator: Bool
    let viewSize: CGSize
    let favoriteSizeValue: CGFloat

    var body: some View {
        if showIndicator {
            VStack(spacing: 0.0) {
                self.penSizeIndicatorView.isHidden(toShowSizeIndicatorAtBottom())
                Spacer()
                    .frame(height: 8.0)
                self.penSizeStateView
                Spacer()
                    .frame(height: 8.0)
                self.penSizeIndicatorView.isHidden(!toShowSizeIndicatorAtBottom())
            }.contentShape(Rectangle())
        } else {
            self.penSizeStateView
                .contentShape(Rectangle())
        }
    }

    private func toShowSizeIndicatorAtBottom() -> Bool {
        var toShow = false
        let placement = FTShortcutPlacement.getSavedPlacement()
        if placement == .top {
            toShow = true
        }
        return toShow
    }

    private var penSizeIndicatorView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 100.0, style: .continuous)
                .frame(width: 31.0, height: 18.0)
                .foregroundColor(.systemBackground) // to be chnaged on confirmation
                .shadow(color: .primary.opacity(0.12), radius: 8, x: 0.0, y: 4.0)
            Text("\(self.favoriteSizeValue.roundToDecimal(1).formattedValue)")
                .foregroundColor(.label)
                .font(.caption2)
        }
    }

     private var penSizeStateView: some View {
         ZStack {
             self.backGround
                 .isHidden(!self.isSelected)
             VStack {
                 Circle()
                     .fill(self.isSelected ? .primary : Color.primary.opacity(0.2))
                     .frame(width: viewSize.width, height: viewSize.height)
            }.frame(width: 28.0, height: 28.0)
         }
    }

    private var backGround: some View {
        Circle()
            .fill(Color.appColor(.white100))
            .frame(width: 28.0, height: 28.0)
            .shadow(color: .primary.opacity(0.12), radius: 8, x: 0.0, y: 4.0)
    }
}

struct FTPenSizeView_Previews: PreviewProvider {
    static var previews: some View {
        FTPenSizeView(isSelected: true, showIndicator: true, viewSize: CGSize(width: 12.0, height: 3.0), favoriteSizeValue: 3.0)
    }
}
