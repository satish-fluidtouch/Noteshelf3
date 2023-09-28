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
            FTVibrancyVisualEffectView()
                .cornerRadius(info.toastHeight/2.0)
            VStack {
                Text(info.title)
                    .font(Font(info.titleFont))
                    .foregroundColor(.white)
                    .truncationMode(.tail)

                Text(info.displaySubTitle)
                    .font(Font(info.subTitleFont))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, info.horzPadding)
            .padding(.vertical, info.vertPadding)
        }
        .frame(width: self.width, height: info.toastHeight)
        .toolbarOverlay(radius: info.toastHeight/2.0, borderWidth: 0.1)
        .onAppear {
            self.width = self.getRequiredWidth()
        }
    }

    private func getRequiredWidth() -> CGFloat {
        let titleWidth = info.title.widthOfString(usingFont: info.titleFont) + 2*info.horzPadding
        let subTitleWidth = info.displaySubTitle.widthOfString(usingFont: info.subTitleFont) + 2*info.horzPadding
        let maxWidth = max(min(max(titleWidth, subTitleWidth), 300.0), 150)
        return maxWidth
    }
}

struct FTVibrancyVisualEffectView: UIViewRepresentable {
    var bgColor: UIColor = UIColor.appColor(.bookInfoToastBgColor)
    @Environment(\.colorScheme) var colorScheme

    init(bgColor: UIColor = UIColor.appColor(.bookInfoToastBgColor)) {
        self.bgColor = bgColor
    }

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        let blurEffect: UIBlurEffect
        if colorScheme == .dark {
            blurEffect = UIBlurEffect(style: .dark)
        } else {
            blurEffect = UIBlurEffect(style: .light)
        }
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let visualEffectView = UIVisualEffectView(effect: vibrancyEffect)
        return visualEffectView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.backgroundColor = bgColor
    }
}

struct FTNotebookInfoToastView_Previews: PreviewProvider {
    static var previews: some View {
        FTNotebookInfoToastView(info: FTNotebookToastInfo(title: "", currentPageNum: 1, totalPageCount: 4))
    }
}
