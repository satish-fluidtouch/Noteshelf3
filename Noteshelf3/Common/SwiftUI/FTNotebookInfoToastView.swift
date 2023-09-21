//
//  FTNotebookInfoToastView.swift
//  Noteshelf3
//
//  Created by Narayana on 15/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

class FTNotebookToastInfo {
    let title: String
    let currentPageNum: Int
    let totalPageCount: Int
    var screenWidth: CGFloat // used to calculate width of toast based on info at view level.

    let toastHeight: CGFloat = 24.0
    let font = UIFont.appFont(for: .medium, with: 15.0)
    let textColor = UIColor.appColor(.accent)
    let regularPadding: CGFloat = 50.0
    let compactPadding: CGFloat = 10.0
    let compactUpperThreshold: CGFloat = 600.0
    let cornerRadius: CGFloat = 6.0

    init(title: String, currentPageNum: Int, totalPageCount: Int, screenWidth: CGFloat) {
        self.title = title
        self.currentPageNum = currentPageNum
        self.totalPageCount = totalPageCount
        self.screenWidth = screenWidth
    }
}

struct FTNotebookInfoToastView: View {
    let info: FTNotebookToastInfo
    @State var width: CGFloat = 270.0

    var body: some View {
        ZStack {
            FTShortcutBarVisualEffectView()
                .cornerRadius(info.cornerRadius)
            HStack(spacing: FTSpacing.zero) {
                Text(info.title)
                    .foregroundColor(Color(uiColor: info.textColor))
                    .font(Font(info.font))
                    .truncationMode(.tail)

                Text(" . \(info.currentPageNum) of \(info.totalPageCount)")
                    .foregroundColor(Color(uiColor: info.textColor))
                    .font(Font(info.font))
            }
            .padding(.horizontal, FTSpacing.small)
        }
        .frame(width: width, height: info.toastHeight)
        .toolbarOverlay(radius: info.cornerRadius)
        .onAppear {
            self.width = self.getRequiredWidth() + (2 * FTSpacing.small) + 4.0 // extra offset to avoid truncation during string length caluclation
        }
    }

    private func getRequiredWidth() -> CGFloat {
        var width = info.title.widthOfString(usingFont: info.font, color: info.textColor) + " . \(info.currentPageNum) of  \(info.totalPageCount)".widthOfString(usingFont: info.font, color: info.textColor)
        var padding: CGFloat = 2 * info.regularPadding
        if info.screenWidth < info.compactUpperThreshold {
            padding = 2 * info.compactPadding
        }
        if width > info.screenWidth - padding {
            width = info.screenWidth - padding
        }
        return width
    }
}

struct FTNotebookInfoToastView_Previews: PreviewProvider {
    static var previews: some View {
        FTNotebookInfoToastView(info: FTNotebookToastInfo(title: "Sample Notebook 1", currentPageNum: 3, totalPageCount: 24, screenWidth: 450))
    }
}

extension String {
    func widthOfString(usingFont font: UIFont, color: UIColor) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}
