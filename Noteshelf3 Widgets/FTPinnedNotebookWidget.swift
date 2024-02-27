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
            Image(uiImage: imageFrom(entry: entry))
                .resizable()
                .scaledToFit()
                .frame(width: imageSize(for: entry).width,height: imageSize(for: entry).height)
                .padding(.top, 20)
                .padding(.leading, 24)
//                .clipShape(RoundedCorner(radius: entry.hasCover ? 2 : 4, corners: [.topLeft, .bottomLeft]))
//                .clipShape( RoundedCorner(radius: 4, corners: [.topRight, .topRight]))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private func imageFrom(entry : FTPinnedBookEntry) -> UIImage {
        return UIImage(contentsOfFile: entry.coverImage) ?? UIImage(named: "noCover")!
    }
    
    private func imageSize(for entry: FTPinnedBookEntry) -> CGSize {
        var size = CGSize(width: 40, height: 55)
        if entry.isLandscape {
            size = CGSize(width: 52, height: 38)
        }
        return size
    }
}
struct topView: View {
    let entry: FTPinnedBookEntry
    @State var color: UIColor = .black
    
    var body: some View {
        ZStack {
            Color(uiColor: color)
        }.frame(width: 160, height: 48)
            .onAppear {
                color = entry.hasCover ? adaptiveColorFromImage() : UIColor(hexString: "#E06E51")
            }
            .overlay {
                if entry.hasCover {
                    if color.isLightColor() {
                        Color.black.opacity(0.2)
                    } else {
                        Color.white.opacity(0.2)
                    }
                }
            }
    }
    
    private func adaptiveColorFromImage() -> UIColor {
        var uiColor = UIColor(hexString: "#E06E51")
        if let uiImage = UIImage(named: entry.coverImage), let colors = ColorThief.getPalette(from: uiImage, colorCount: 5), colors.count >= 2 {
            uiColor = colors[1].makeUIColor().withAlphaComponent(0.8)
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
                    .font(.appFont(for: .medium, with: 14))
                Text(entry.time)
                    .lineLimit(1)
                    .font(.appFont(for: .medium, with: 12))
                    .foregroundColor(Color("black70"))
                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.top,1)
            }.padding(.leading, 20)
                .padding(.bottom, 16)
            Spacer()
        }.frame(width: 160, height: 110)
            .background(Rectangle().fill(LinearGradient(colors: [Color(uiColor: UIColor(hexString: "#F0EEEB")),Color(uiColor: UIColor(hexString: "#FFFFFF"))], startPoint: .top, endPoint: .bottom)))
    }
}



extension UIColor {
    func isLightColor() -> Bool {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get HSB components of the color
        if self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            if brightness > 0.88 {
                return true
            }
        }
        return false
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
