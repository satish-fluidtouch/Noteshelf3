//
//  FTPinnedNotebookWidget.swift
//  FTPinnedNotebookWidget
//
//  Created by Ramakrishna on 05/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

struct FTPinnedWidgetView : View {
    let entry: FTPinnedBookEntry
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                topView(entry: entry)
                bottomView(entry: entry)
            }
        }.overlay(alignment: .topLeading) {
            Image(entry.coverImage)
                .resizable()
                .scaledToFit()
                .frame(width: 44,height: 60)
                .padding(.top, 20)
                .padding(.leading, 24)
        }
    }
}
struct topView: View {
    let entry: FTPinnedBookEntry
    var body: some View {
        HStack {
            Color(uiColor: UIColor(hexString: "#E06E51"))
        }.frame(width: 160, height: 48)
//        .background(Color.white.opacity(1))
//        .background(Color(uiColor: adaptiveColorFromImage()))
    }
    
    private func adaptiveColorFromImage() -> UIColor {
        var uiColor = UIColor(hexString: "#E06E51")
        if let uiImage = UIImage(named: entry.coverImage), let colors = ColorThief.getPalette(from: uiImage, colorCount: 5), colors.count >= 2 {
            print(colors)
            uiColor = colors[0].makeUIColor()
        }
        return uiColor
    }
}

struct bottomView: View {
    let entry: FTPinnedBookEntry
    var body: some View {
        HStack {
            VStack {
                Spacer()
                Text(entry.name)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.label)
                    .font(.appFont(for: .medium, with: 18))
                Text(entry.time)
                    .lineLimit(1)
                    .font(.appFont(for: .regular, with: 15))
                    .foregroundColor(Color("black70"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.padding(.leading, 20)
                .padding(.bottom, 16)
            Spacer()
        }.frame(width: 160, height: 110)
            .background(Rectangle().fill(LinearGradient(colors: [Color(uiColor: UIColor(hexString: "#F0EEEB")),Color(uiColor: UIColor(hexString: "#FFFFFF"))], startPoint: .top, endPoint: .bottom)))
    }
}


