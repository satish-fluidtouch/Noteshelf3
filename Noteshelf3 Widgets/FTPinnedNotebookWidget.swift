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
                        }.padding(.leading, self.getWidthPercentFactor(using: geometry, for: 20))
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
        let portraitDimension = self.getWidthPercentFactor(using: geometry, for: 49)
        let landscapeDimension = self.getHeightPercentFactor(using: geometry, for: 68)
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
        }.frame(height: geometry.size.height/3)
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
        .frame(height: 2*geometry.size.height/3)
    }
}

struct EmptyNotesView: View {
    var geometry: GeometryProxy

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)                
                .frame(width:self.getWidthPercentFactor(using: geometry, for: 119), height: self.getHeightPercentFactor(using: geometry, for: 64))
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
                    Spacer(minLength: self.getWidthPercentFactor(using: geometry, for: 16))
                }
                HStack {
                    Text(entry.time)
                        .lineLimit(1)
                        .font(.appFont(for: .medium, with: 12))
                        .foregroundColor(Color("black50"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: self.getWidthPercentFactor(using: geometry, for: 16))
                }
            }.padding(.leading, self.getWidthPercentFactor(using: geometry, for: 18))
                .padding(.bottom, self.getWidthPercentFactor(using: geometry, for: 18))
            Spacer()
        }
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

extension View {
    @ViewBuilder func isHidden(_ isHidden: Bool) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }
}
