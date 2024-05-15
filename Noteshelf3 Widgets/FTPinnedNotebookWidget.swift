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
    @State var image = UIImage(named: "noCover")!
    @Environment(\.widgetContentMargins) var margins

    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack(spacing: 0) {
                    topView(entry: entry, geometry: geometry)
                    bottomView(entry: entry, geometry: geometry)
                }
            }
            .overlay(alignment: .topLeading) {
                if !entry.relativePath.isEmpty {
                    HStack {
                        VStack(spacing:0) {
                            HStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: imageSize(for: entry, geometry: geometry).width,height: imageSize(for: entry, geometry: geometry).height)
                                    .clipShape(RoundedCorner(radius: entry.hasCover ? 2 : 4, corners: [.topLeft, .bottomLeft]))
                                    .clipShape( RoundedCorner(radius: 4, corners: [.topRight, .bottomRight]))
                                    .padding(.top, image.size.width > image.size.height ? geometry.size.height * 0.19 : geometry.size.height * 0.13)
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
                                Spacer()
                            }
                        }.padding(.leading, geometry.size.width * FTPinnedWidgetConfigFactors.padding20)
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            image = imageFrom(entry : entry)
        }
    }
    
    private func imageFrom(entry : FTPinnedBookEntry) -> UIImage {
        let image = UIImage(contentsOfFile: entry.coverImage)
        return image ?? UIImage(named: "noCover")!
    }
    
    private func imageSize(for entry: FTPinnedBookEntry, geometry: GeometryProxy) -> CGSize {
        let portraitDimension = geometry.size.width * FTPinnedWidgetConfigFactors.thumbnailPortrait
        let landscapeDimension = geometry.size.height * FTPinnedWidgetConfigFactors.thumbnailLandscape
        var size = CGSize(width: portraitDimension, height: landscapeDimension)
        if image.size.width > image.size.height {
            size = CGSize(width: landscapeDimension, height: portraitDimension)
        }
        return size
    }
}
struct topView: View {
    let entry: FTPinnedBookEntry
    @State var color: UIColor = .black
    var geometry: GeometryProxy

    var body: some View {
        ZStack {
            Color(uiColor: color)
        }.frame(height: FTPinnedWidgetConfigFactors.topViewHeight * geometry.size.height)
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
        if let uiImage = UIImage(contentsOfFile: entry.coverImage), let colors = ColorThief.getPalette(from: uiImage, colorCount: 5), colors.count >= 2 {
            uiColor = colors[1].makeUIColor().withAlphaComponent(0.8)
        }
        return uiColor
    }
}

struct bottomView: View {
    let entry: FTPinnedBookEntry
    var geometry: GeometryProxy

    var body: some View {
        ZStack {
            Rectangle().fill(LinearGradient(colors: [Color("widgetBG1"),Color("widgetBG2")], startPoint: .top, endPoint: .bottom))
            HStack {
                if entry.relativePath.isEmpty {
                    EmptyNotesView(geometry: geometry)
                } else {
                    NoteBookInfoView(entry: entry, geometry: geometry)
                }
            }
        }
        .frame(height: FTPinnedWidgetConfigFactors.bottomViewHeight * geometry.size.height)
    }
}

struct EmptyNotesView: View {
    var geometry: GeometryProxy

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)                
                .frame(width:FTPinnedWidgetConfigFactors.emptyNotesWidth * geometry.size.width, height: FTPinnedWidgetConfigFactors.emptyNotesHeight * geometry.size.height)
            .foregroundColor(Color("EmptyNotesBG"))
            Text("widget.nonotes".localized)
                .font(.appFont(for: .medium, with: 13))
                .foregroundColor(Color("EmptyNotesTitle"))
        }
    }
}

struct NoteBookInfoView: View {
    let entry: FTPinnedBookEntry
    var geometry: GeometryProxy

    var body: some View {
        HStack {
            VStack(spacing: 3) {
                Spacer()
                HStack {
                    Text(entry.name.lastPathComponent)
                        .lineLimit(1)
                        .foregroundColor(Color.label)
                        .font(.appFont(for: .medium, with: 16))
                    Spacer(minLength: FTPinnedWidgetConfigFactors.padding16 * geometry.size.width)
                }
                HStack {
                    Text(entry.time)
                        .lineLimit(1)
                        .font(.appFont(for: .medium, with: 12))
                        .foregroundColor(Color("black50"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: FTPinnedWidgetConfigFactors.padding16 * geometry.size.width)
                }
            }.padding(.leading, FTPinnedWidgetConfigFactors.padding18 * geometry.size.width)
                .padding(.bottom, FTPinnedWidgetConfigFactors.padding18 * geometry.size.width)
            Spacer()
        }
    }
}

// Below factors are calculated based on widget size 155*155 as per figma to maintain in all devices properly
fileprivate struct FTPinnedWidgetConfigFactors {
    static let thumbnailPortrait: CGFloat = 0.31 // 49
    static let thumbnailLandscape: CGFloat = 0.43 // 68
    static let emptyNotesWidth = 0.76 // 119
    static let emptyNotesHeight = 0.41 // 64
    static let topViewHeight = 0.33 // 55
    static let bottomViewHeight = 0.67 // 110

    static let padding16 = 0.10 // 16
    static let padding18 = 0.115 // 18
    static let padding20 = 0.13 // 20
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

extension View {
    @ViewBuilder func isHidden(_ isHidden: Bool) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }
}
