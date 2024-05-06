//
//  FTNotebookCreationWidget.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 07/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import WidgetKit
import SwiftUI
import FTCommon
import AppIntents

struct NotebookCreation_WidgetsEntryView : View {
    var body: some View {
        VStack(spacing:16.0) {
            headerView
                .frame(height: 24,alignment: .center)
            optionsView
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal,16)
        .padding(.vertical,16)
    }
    private var optionsView : some View {
        Grid(alignment: .center, horizontalSpacing: 4,verticalSpacing: 4 ) {
            GridRow {
                optionViewForType(.quickNote, intent: QuickNoteIntent())
                optionViewForType(.newNotebook, intent: NewNotebookIntent())
            }
            GridRow {
                optionViewForType(.audioNote, intent: AudioNoteIntent())
                optionViewForType(.scan, intent: ScanIntent())
            }
        }
    }
    private func optionViewForType(_ type : FTNotebookCreateWidgetActionType, intent: any AppIntent) -> some View {
        Button(intent: intent) {
            actionViewForType(type)
        }
        .buttonStyle(CustomButtonStyle())
    }

    private var headerView : some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing:10) {
            Image("appIconSmall")
                .frame(width: 22,height: 22,alignment: .center)
                .padding(.leading,8)
            Text("Noteshelf")
                .frame(height: 24, alignment: .center)
                .font(.clearFaceFont(for: .bold, with: 17))
            Spacer()
            if #available(iOS 17.0, *) {
                Button(intent: SearchIntent()) {
                    Image("searchIcon")
                        .frame(width: 24,height: 24)
                }
                .frame(width: 24,height: 24,alignment: .center)
                .border(.clear, width: 0)
                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                .buttonStyle(.plain)
            } else {
                Button(action: {

                }, label: {
                    Text("Button")
                })
            }
        }
    }
    private func actionViewForType(_ type : FTNotebookCreateWidgetActionType) -> some View {
        return HStack(alignment: .center, spacing:10) {
            if type.hasASystemIcon {
                Image(systemName: type.iconName)
                    .frame(width: 24,height: 24,alignment: .center)
                    .padding(.leading,12)
                    .foregroundStyle(Color("creationWidgetButtonTint"))
                    .font(.appFont(for: .medium, with: 16))
            } else {
                Image("\(type.iconName)")
                    .frame(width: 24,height: 24,alignment: .center)
                    .padding(.leading,12)
                    .scaledToFit()
                    .foregroundStyle(Color("creationWidgetButtonTint"))
            }
            Text(type.title)
                .font(.appFont(for: .medium, with: 14))
                .foregroundStyle(Color("creationWidgetButtonTint"))
        }
        .frame(maxWidth: .infinity,maxHeight:.infinity, alignment: .leading)
    }
}
struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color("creationWidgetButtonBG"))
            .clipShape(RoundedRectangle(cornerRadius: 12))

    }
}
@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    NotebookCreation_Widget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
}


