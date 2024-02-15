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
            VStack {
                Image(entry.coverImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40,height: 55)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 18)
                    .padding(.top, 18)

                Spacer()

                VStack {
                    Text(entry.name)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(color.isLightColor() ? Color.black : Color.systemBackground )
                        .font(.appFont(for: .medium, with: 13))
                    Text(entry.time)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.appFont(for: .regular, with: 12))
                        .foregroundColor(color.isLightColor() ? Color.black.opacity(0.7) : Color.systemBackground.opacity(0.7))
                }
                .padding(.leading, 18)
                .padding(.bottom, 18)
            }
            .frame(width: 190, height: 155)
            .background(Color(uiColor: color))
            .overlay {
                if color.isLightColor() {
                    Color.black.opacity(0.2)
                } else {
                    Color.white.opacity(0.2)
                }
            }
            VStack {
                optionsView
            }
            .frame(width: 155, height: 155)
        }
        .onAppear {
            color = adaptiveColorFromImage()
        }
    }

    private func adaptiveColorFromImage() -> UIColor {
        var uiColor = UIColor(hexString: "#E06E51")
        if let uiImage = UIImage(named: entry.coverImage), let colors = ColorThief.getPalette(from: uiImage, colorCount: 5), colors.count >= 2 {
            print(colors)
            uiColor = colors[1].makeUIColor().withAlphaComponent(0.8)
        }
        return uiColor
    }

    private var optionsView : some View {
        Grid(alignment: .center, horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                optionViewForType(.pen, intent: FTPinnedPenIntent())
                optionViewForType(.audio, intent: FTPinnedAudioIntent())
            }

            GridRow {
                optionViewForType(.openAI, intent: FTPinnedOpenAIIntent())
                optionViewForType(.text, intent: FTPinnedTextIntent())
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
        FTPinnedNotebookOptionsWidgetView(entry: FTPinnedBookEntry(date: Date(), name: "Notebook Title hdsfhhg", time: "12:00 PM", coverImage: "coverImage1"))
    }
}

