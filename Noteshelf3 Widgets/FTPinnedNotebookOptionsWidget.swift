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

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Button(intent: entry.bookOpenintent) {
                    if entry.relativePath.isEmpty {
                        ZStack {
                            Color(uiColor: color)
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: geometry.size.width * 0.43, height: geometry.size.height * 0.77)
                                .foregroundColor(Color(uiColor: UIColor(hexString: "FFFFFF",alpha: 0.1)))
                            Text("widget.nonotes".localized)
                                .font(.appFont(for: .medium, with: 13))
                                .foregroundColor(Color(uiColor: UIColor(hexString: "FFFFFF")))
                        }
                        .frame(width: geometry.size.width * 0.54, height: geometry.size.height)
                    } else {
                        VStack {
                        }
                        .frame(width: geometry.size.width * 0.54, height: geometry.size.height)
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
                                                .frame(width: imageSize(for: entry).width,height: imageSize(for: entry).height)
                                                .clipShape(RoundedCorner(radius: entry.hasCover ? 2 : 4, corners: [.topLeft, .bottomLeft]))
                                                .clipShape( RoundedCorner(radius: 4, corners: [.topRight, .bottomRight]))
                                                .padding(.top, image.size.width > image.size.height ? geometry.size.height * 0.19 : geometry.size.height * 0.13)
                                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
                                            Spacer()
                                        }
                                        HStack {
                                            Text(entry.name.lastPathComponent)
                                                .lineLimit(1)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundColor(color.isLightColor() ? Color.black : Color.white)
                                                .padding(.top, 13)
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
                                    }.padding(.leading, 20)
                                    Spacer()
                                }

                            }
                        }.isHidden(entry.relativePath.isEmpty)
                    }
                }.buttonStyle(.plain)
                VStack {
                    optionsView
                }
                .frame(width: geometry.size.width * 0.46)
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
    
    private func imageSize(for entry: FTPinnedBookEntry) -> CGSize {
        var size = CGSize(width: 49, height: 68)
        if image.size.width > image.size.height {
            size = CGSize(width: 68, height: 49)
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

    private var optionsView : some View {
        Grid(alignment: .center, horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                optionViewForType(.pen(entry.relativePath), intent: entry.penIntent)
                optionViewForType(.audio(entry.relativePath), intent: entry.audioIntent)
            }

            GridRow {
                optionViewForType(.openAI(entry.relativePath), intent: entry.aiIntent)
                optionViewForType(.text(entry.relativePath), intent: entry.textIntent)
            }
        }
    }

    private func optionViewForType(_ type : FTPinndedWidgetActionType, intent: any AppIntent) -> some View {
        Button(intent: intent) {
            HStack {
                Image("\(type.iconName)")
                    .frame(width: 18,height: 18,alignment: .center)
                    .scaledToFit()
                    .foregroundStyle(Color(type.docId.isEmpty ? "imageDisabledTintColor" : "creationWidgetButtonTint"))
            }
        }
        .buttonStyle(FTPinnedBookOptionButtonStyle(color: Color(type.docId.isEmpty ? "pinnedBookEmptyBgColor" : "pinnedBookOptionBgColor")))
        .disabled(type.docId.isEmpty)
    }
}

struct FTPinnedBookOptionButtonStyle: ButtonStyle {
    let bgColor: Color

    public init(color: Color) {
        self.bgColor = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 54, height: 54)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FTPinnedNotebookOptionsWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        FTPinnedNotebookOptionsWidgetView(entry: FTPinnedBookEntry(date: Date(), name: "Notebook Title hdsfhhg", time: "12:00 PM", coverImage: "coverImage1", relativePath: "", hasCover: false, isLandscape: false, docId: ""))
    }
}

