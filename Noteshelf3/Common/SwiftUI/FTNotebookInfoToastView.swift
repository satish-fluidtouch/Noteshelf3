//
//  FTNotebookInfoToastView.swift
//  Noteshelf3
//
//  Created by Narayana on 15/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTNotebookToastInfo {
    let title: String
    let currentPageNum: Int
    let totalPageCount: Int
    let toastHeight: CGFloat = 24.0
}

struct FTNotebookInfoToastView: View {
    let info: FTNotebookToastInfo
    @State var width: CGFloat = 270.0

    var body: some View {
        ZStack {
            FTShortcutBarVisualEffectView()
                .cornerRadius(6.0)
            HStack(spacing: FTSpacing.small) {
                Text(info.title)
                    .ftNotebookToastTextStyle()
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(".")
                    .ftNotebookToastTextStyle()

                Text("\(info.currentPageNum) of \(info.totalPageCount)")
                    .ftNotebookToastTextStyle()
                    .lineLimit(1)
            }
            .padding(.horizontal, FTSpacing.small)
            .frame(width: width, height: info.toastHeight)
        }
        .toolbarOverlay(radius: 6.0)
        .onAppear {
            // To optimize - using geometry reader
            self.width = self.getRequiredWidth() + (4 * FTSpacing.small)
        }
    }

    private func getRequiredWidth() -> CGFloat {
        let font = UIFont.appFont(for: .medium, with: 15)
        let width = info.title.widthOfString(usingFont: font) + ".".widthOfString(usingFont: font) + "\(info.currentPageNum) of \(info.totalPageCount)".widthOfString(usingFont: font)
        return width
    }
}

extension Text {
    func ftNotebookToastTextStyle() -> some View {
        self
            .foregroundColor(Color.appColor(.accent))
            .font(Font.appFont(for: .medium, with: 15.0))
    }
}

struct FTNotebookInfoToastView_Previews: PreviewProvider {
    static var previews: some View {
        FTNotebookInfoToastView(info: FTNotebookToastInfo(title: "Sample Notebook 1", currentPageNum: 3, totalPageCount: 24))
    }
}
