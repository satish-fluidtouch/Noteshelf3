//
//  FTPinnedNotebookOptionsWidget.swift
//  Noteshelf3 WidgetsExtension
//
//  Created by Narayana on 15/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import AppIntents
import FTCommon
import FTStyles

struct FTPinnedNotebookOptionsWidgetView: View {
    let entry: FTPinnedBookEntry
    @State var color: UIColor = .black
    @State var image = UIImage(named: "noCover")!

    private let type: FTWidgetType = .medium

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Button(intent: entry.bookOpenintent) {
                    if entry.relativePath.isEmpty {
                        ZStack {
                            Color(uiColor: color)
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: self.getWidthPercentFactor(using: geometry, for: 150, for: type), height: self.getHeightPercentFactor(using: geometry, for: 120, for: type))
                                .foregroundColor(Color(uiColor: UIColor(hexString: "FFFFFF",alpha: 0.1)))
                            Text("widget.nonotes".localized)
                                .font(.appFont(for: .medium, with: 13))
                                .foregroundColor(Color(uiColor: UIColor(hexString: "FFFFFF")))
                        }
                        .frame(width: 0.55*geometry.size.width, height: geometry.size.height)
                    } else {
                        VStack {
                        }
                        .frame(width: 0.55*geometry.size.width, height: geometry.size.height)
                        .background(Color(uiColor: color))
                        .overlay() {
                            ZStack(alignment: .top) {
                                if entry.hasCover {
                                    if color.isLightColor() {
                                        Color.black.opacity(0.2)
                                    } else {
                                        Color.white.opacity(0.2)
                                    }
                                }
                                HStack{
                                    VStack(spacing:0) {
                                        HStack {
                                            Image(uiImage: image)
                                                .resizable()
                                                .frame(width: imageSize(for: entry, geometry: geometry).width,height: imageSize(for: entry, geometry: geometry).height)
                                                .clipShape(RoundedCorner(radius: entry.hasCover ? 2 : 4, corners: [.topLeft, .bottomLeft]))
                                                .clipShape( RoundedCorner(radius: 4, corners: [.topRight, .bottomRight]))
                                                .padding(.top, image.size.width > image.size.height ?  self.getHeightPercentFactor(using: geometry, for: 30, for: type) : self.getHeightPercentFactor(using: geometry, for: 20, for: type))
                                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
                                            Spacer()
                                        }
                                        HStack {
                                            Text(entry.name.lastPathComponent)
                                                .lineLimit(1)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundColor(color.isLightColor() ? Color.black : Color.white)
                                                .padding(.top, self.getHeightPercentFactor(using: geometry, for: 13, for: type))
                                                .font(.appFont(for: .medium, with: 16))
                                            Spacer(minLength: 14)
                                        }
                                        HStack {
                                            Text(entry.time)
                                                .lineLimit(1)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .font(.appFont(for: .medium, with: 12))
                                                .foregroundColor(color.isLightColor() ? Color.black.opacity(0.5) : Color.white.opacity(0.5))
                                                .padding(.top, 2)
                                            Spacer(minLength: 14)
                                        }
                                        Spacer()
                                    }.padding(.leading, self.getWidthPercentFactor(using: geometry, for: 20, for: type))
                                    Spacer()
                                }

                            }
                        }.isHidden(entry.relativePath.isEmpty)
                    }
                }.buttonStyle(.plain)
                VStack {
                    optionsView(geometry: geometry)
                }
                .frame(width: 0.45*geometry.size.width)
            }
        }
        .onAppear {
            image = imageFrom(entry: entry)
            color = entry.hasCover ? adaptiveColorFromImage() : UIColor(hexString: "#E06E51",alpha: 0.85)
        }
    }

    private func imageFrom(entry : FTPinnedBookEntry) -> UIImage {
        return UIImage(contentsOfFile: entry.coverImage) ?? UIImage(named: "noCover")!
    }
    
    private func imageSize(for entry: FTPinnedBookEntry, geometry: GeometryProxy) -> CGSize {
        let portraitDimension = self.getWidthPercentFactor(using: geometry, for: 49, for: type)
        let landscapeDimension = self.getHeightPercentFactor(using: geometry, for: 68, for: type)
        var size = CGSize(width: portraitDimension, height: landscapeDimension)
        if image.size.width > image.size.height {
            size = CGSize(width: landscapeDimension, height: portraitDimension)
        }
        return size
    }

    private func adaptiveColorFromImage() -> UIColor {
        var uiColor = UIColor(hexString: "#E06E51")
        if  let colors = ColorThief.getPalette(from: image, colorCount: 5), colors.count >= 2 {
            uiColor = colors[1].makeUIColor()//.withAlphaComponent(0.8)
        }
        return uiColor
    }

    private func optionsView(geometry: GeometryProxy) -> some View {
        Grid(alignment: .center, horizontalSpacing: self.getHeightPercentFactor(using: geometry, for: 8, for: type), verticalSpacing: self.getHeightPercentFactor(using: geometry, for: 8, for: type)) {
            GridRow {
                optionViewForType(.pen(entry.relativePath), intent: entry.penIntent, geometry: geometry)
                optionViewForType(.audio(entry.relativePath), intent: entry.audioIntent, geometry: geometry)
            }

            GridRow {
                optionViewForType(.openAI(entry.relativePath), intent: entry.aiIntent, geometry: geometry)
                optionViewForType(.text(entry.relativePath), intent: entry.textIntent, geometry: geometry)
            }
        }
    }

    private func optionViewForType(_ type : FTPinndedWidgetActionType, intent: any AppIntent, geometry: GeometryProxy, widgetType: FTWidgetType = .medium) -> some View {
        Button(intent: intent) {
            HStack {
                Image("\(type.iconName)")
                    .frame(height: self.getHeightPercentFactor(using: geometry, for: 54, for: widgetType))
                    .aspectRatio(1, contentMode: .fit)
                    .scaledToFit()
                    .foregroundStyle(Color(type.docId.isEmpty ? "imageDisabledTintColor" : "creationWidgetButtonTint"))
            }
        }
        .buttonStyle(FTPinnedBookOptionButtonStyle(color: Color(type.docId.isEmpty ? "pinnedBookEmptyBgColor" : "pinnedBookOptionBgColor"), geometry: geometry))
        .disabled(type.docId.isEmpty)
    }
}

struct FTPinnedBookOptionButtonStyle: ButtonStyle {
    let bgColor: Color
    let geometry: GeometryProxy

    public init(color: Color, geometry: GeometryProxy) {
        self.bgColor = color
        self.geometry = geometry
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: geometry.size.height*54/155, height: geometry.size.height*54/155)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FTPinnedNotebookOptionsWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        FTPinnedNotebookOptionsWidgetView(entry: FTPinnedBookEntry(date: Date(), name: "Notebook Title hdsfhhg", time: "12:00 PM", coverImage: "coverImage1", relativePath: "", hasCover: false, isLandscape: false, docId: ""))
    }
}

