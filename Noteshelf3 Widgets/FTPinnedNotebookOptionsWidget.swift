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

    var body: some View {
        HStack(spacing: 0) {
            Button(intent: FTPinnedBookOpenIntent(path: entry.relativePath)) {
                sideView
            }.buttonStyle(.plain)
            VStack {
                optionsView
            }
            .frame(width: 155, height: 155)
        }
        .onAppear {
            color = entry.hasCover ? adaptiveColorFromImage() : UIColor(hexString: "#E06E51")
        }
    }
    
    private var sideView: some View {
        return VStack {
            Spacer()
            VStack {
                Text(entry.name)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(color.isLightColor() ? Color.black : Color.systemBackground)
                    .font(.appFont(for: .medium, with: 14))
                Text(entry.time)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.appFont(for: .medium, with: 12))
                    .foregroundColor(color.isLightColor() ? Color.black.opacity(0.7) : Color.systemBackground.opacity(0.7))
//                    .padding(.top,1)
            }
            .padding(.leading, 18)
            .padding(.bottom, 18)
        }
        .frame(width: 190, height: 155)
        .background(Color(uiColor: color))
        .overlay() {
            ZStack(alignment: .top) {
                if color.isLightColor() {
                    Color.black.opacity(0.2)
                } else {
                    Color.white.opacity(0.2)
                }
                Image(uiImage: imageFrom(entry: entry))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40,height: 55)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 18)
                    .padding(.top, 30)
            }
        }
    }
    
    private func imageFrom(entry : FTPinnedBookEntry) -> UIImage {
        var image = UIImage(named: "noCover")!
        if entry.hasCover {
            image = UIImage(contentsOfFile: entry.coverImage) ?? image
        }
        return image
    }

    private func adaptiveColorFromImage() -> UIColor {
        var uiColor = UIColor(hexString: "#E06E51")
        if let uiImage = UIImage(named: entry.coverImage), let colors = ColorThief.getPalette(from: uiImage, colorCount: 5), colors.count >= 2 {
            uiColor = colors[1].makeUIColor().withAlphaComponent(0.8)
        }
        return uiColor
    }

    private var optionsView : some View {
        Grid(alignment: .center, horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                optionViewForType(.pen(entry.relativePath), intent: FTPinnedPenIntent(path: entry.relativePath))
                optionViewForType(.audio(entry.relativePath), intent: FTPinnedAudioIntent(path: entry.relativePath))
            }

            GridRow {
                optionViewForType(.openAI(entry.relativePath), intent: FTPinnedOpenAIIntent(path: entry.relativePath))
                optionViewForType(.text(entry.relativePath), intent: FTPinnedTextIntent(path: entry.relativePath))
            }
        }
    }

    private func optionViewForType(_ type : FTPinndedWidgetActionType, intent: any AppIntent) -> some View {
        Button(intent: intent) {
            HStack {
                Image("\(type.iconName)")
                    .frame(width: 18,height: 18,alignment: .center)
                    .scaledToFit()
                    .tint(Color("creationWidgetButtonTint"))
            }
        }
        .buttonStyle(FTPinnedBookOptionButtonStyle())
    }
}

struct FTPinnedBookOptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 54, height: 54)
            .background(Color("pinnedBookOptionBgColor"))
            .clipShape(RoundedRectangle(cornerRadius: 12))

    }
}

struct FTPinnedNotebookOptionsWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        FTPinnedNotebookOptionsWidgetView(entry: FTPinnedBookEntry(date: Date(), name: "Notebook Title hdsfhhg", time: "12:00 PM", coverImage: "coverImage1", relativePath: "", hasCover: false))
    }
}

