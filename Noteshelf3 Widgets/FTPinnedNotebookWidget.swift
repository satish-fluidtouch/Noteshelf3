//
//  FTPinnedNotebookWidget.swift
//  FTPinnedNotebookWidget
//
//  Created by Ramakrishna on 05/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTPinnedWidgetView : View {
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                topView()
                bottomView()
            }
        }.overlay(alignment: .topLeading) {
            Image("coverImage")
                .frame(width: 38,height: 52)
                .padding(.top, 24)
                .padding(.leading, 24)
        }
    }
}
struct topView: View {
    var body: some View {
        HStack {
            Spacer()
            Image("ns3Icon")
                .frame(width: 20,height: 20)
                .padding(.trailing, 16)
                .padding(.top, 10)
        }.frame(width: 160, height: 48)
        .background(Color(uiColor: UIColor(hexString: "#E06E51")))
    }
}

struct bottomView: View {
    var body: some View {
        HStack {
            VStack {
                Spacer()
                Text("Note book Title")
                    .lineLimit(2)
                Text("5:00 pm")
                    .lineLimit(1)
            }.padding(.leading, 10)
                .padding(.bottom, 12)
            Spacer()
        }.frame(width: 160, height: 110)
            .background(Rectangle().fill(LinearGradient(colors: [Color(uiColor: UIColor(hexString: "#F0EEEB")),Color(uiColor: UIColor(hexString: "#DCCDBC"))], startPoint: .top, endPoint: .bottom)))
    }
}


