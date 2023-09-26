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
        VStack {
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
        .frame(width: size.width)
        .frame(minHeight: size.height)
        .background(Color.appColor(.toastBgColor))
        .cornerRadius(size.height/2.0)
        .border(Color.appColor(.black10), width: 1.0, cornerRadius: size.height/2.0)
        .shadow(color: Color.primary.opacity(0.2), radius: 60, x: 0, y: 10)
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
