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
    
    let displaySubTitle: String
    let contentMaxWidth: CGFloat = 300.0
    init(title: String, currentPageNum: Int, totalPageCount: Int, screenWidth: CGFloat) {
        self.title = title
        self.currentPageNum = currentPageNum
        self.totalPageCount = totalPageCount
        self.screenWidth = screenWidth
        self.displaySubTitle = String.localizedStringWithFormat("PageNofN".localized, self.currentPageNum, self.totalPageCount)
    }
}

struct FTNotebookInfoToastView: View {
    @ObservedObject var config: FTToastConfiguration
    @State private var size: CGSize = .zero

    var body: some View {
        ZStack {
            FTShortcutBarVisualEffectView()
                .cornerRadius(size.height/2.0)
            VStack {
                Text(config.title)
                    .font(Font(config.titleFont))
                    .foregroundColor(.primary)
                    .multilineTextStyle(lineLimit: 2, aligment: .center)
                    .truncationMode(.tail)

                Text(config.subTitle)
                    .font(Font(config.subTitleFont))
                    .foregroundColor(Color.appColor(.black50))
                    .multilineTextStyle(lineLimit: 1, aligment: .center)
            }
            .padding(.horizontal, config.horzPadding)
            .padding(.vertical, config.vertPadding)
        }
        .toolbarOverlay(radius: size.height/2.0)
        .frame(width: size.width)
        .frame(minHeight: size.height)
        .onAppear {
            size = config.getToastSize()
        }
    }
}

struct FTNotebookInfoToastView_Previews: PreviewProvider {
    static var previews: some View {
        FTNotebookInfoToastView(config: FTToastConfiguration(title: ""))
    }
}
