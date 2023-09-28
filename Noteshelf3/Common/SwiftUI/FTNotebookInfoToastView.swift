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

    let displaySubTitle: String

    let toastHeight: CGFloat = 54.0
    let titleFont = UIFont.appFont(for: .bold, with: 15)
    let subTitleFont = UIFont.appFont(for: .regular, with: 13)
    let horzPadding: CGFloat = 28.0
    let vertPadding: CGFloat = 7.0
    
    init(title: String, currentPageNum: Int, totalPageCount: Int) {
        self.title = title
        self.currentPageNum = currentPageNum
        self.totalPageCount = totalPageCount
        self.displaySubTitle = String.localizedStringWithFormat("PageNofN".localized, self.currentPageNum, self.totalPageCount)
    }
}

struct FTNotebookInfoToastView: View {
    @State private var width: CGFloat = 100.0
    let info: FTNotebookToastInfo

    var body: some View {
        ZStack {
            FTShortcutBarVisualEffectView()
                .cornerRadius(info.toastHeight/2.0)
            VStack {
                Text(info.title)
                    .font(Font(info.titleFont))
                    .foregroundColor(.primary)
                    .truncationMode(.tail)

                Text(info.displaySubTitle)
                    .font(Font(info.subTitleFont))
                    .foregroundColor(.primary.opacity(0.5))
            }
            .padding(.horizontal, info.horzPadding)
            .padding(.vertical, info.vertPadding)
        }
        .frame(width: self.width, height: info.toastHeight)
        .onAppear {
            self.width = self.getRequiredWidth()
        }
    }

    private func getRequiredWidth() -> CGFloat {
        let titleWidth = info.title.widthOfString(usingFont: info.titleFont) + 2*info.horzPadding
        let subTitleWidth = info.displaySubTitle.widthOfString(usingFont: info.subTitleFont) + 2*info.horzPadding
        var maxThreshold: CGFloat = 300.0
        if let window = UIApplication.shared.keyWindow, window.frame.width > 500.0 {
            maxThreshold = 400.0
        }
        let maxWidth = max(min(max(titleWidth, subTitleWidth), maxThreshold), 150)
        return maxWidth
    }
}

struct FTNotebookInfoToastView_Previews: PreviewProvider {
    static var previews: some View {
        FTNotebookInfoToastView(info: FTNotebookToastInfo(title: "", currentPageNum: 1, totalPageCount: 4))
    }
}
