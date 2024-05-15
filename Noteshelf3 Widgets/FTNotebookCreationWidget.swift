//
//  FTNotebookCreationWidget.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 07/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import WidgetKit
import SwiftUI
import FTCommon
import AppIntents

struct NotebookCreation_WidgetsEntryView : View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: self.getHeightPercentFactor(using: geometry, for: 16)) {
                headerView(geometry: geometry)
                    .frame(height: self.getHeightPercentFactor(using: geometry, for: 24),alignment: .center)
                optionsView(geometry: geometry)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal,self.getWidthPercentFactor(using: geometry, for: 16))
            .padding(.vertical,self.getHeightPercentFactor(using: geometry, for: 16))
        }
    }
    private func optionsView(geometry: GeometryProxy) -> some View {
        Grid(alignment: .center, horizontalSpacing: self.getHeightPercentFactor(using: geometry, for: 4),verticalSpacing: self.getHeightPercentFactor(using: geometry, for: 4)) {
            GridRow {
                optionViewForType(.quickNote, intent: QuickNoteIntent(), geometry: geometry)
                optionViewForType(.newNotebook, intent: NewNotebookIntent(), geometry: geometry)
            }
            GridRow {
                optionViewForType(.audioNote, intent: AudioNoteIntent(), geometry: geometry)
                optionViewForType(.scan, intent: ScanIntent(), geometry: geometry)
            }
        }
    }
    private func optionViewForType(_ type : FTNotebookCreateWidgetActionType, intent: any AppIntent, geometry: GeometryProxy) -> some View {
        Button(intent: intent) {
            actionViewForType(type, geometry: geometry)
        }
        .buttonStyle(CustomButtonStyle())
    }

    private func headerView(geometry: GeometryProxy) -> some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: self.getWidthPercentFactor(using: geometry, for: 10)) {
            Image("appIconSmall")
                .frame(height: self.getWidthPercentFactor(using: geometry, for: 22))
                .aspectRatio(1, contentMode: .fit)
                .padding(.leading,self.getWidthPercentFactor(using: geometry, for: 8))
            Text("Noteshelf")
                .frame(height: self.getWidthPercentFactor(using: geometry, for: 24))
                .font(.clearFaceFont(for: .bold, with: 17))
            Spacer()
            Button(intent: SearchIntent()) {
                Image("searchIcon")
                    .frame(height: self.getHeightPercentFactor(using: geometry, for: 24))
            }
            .frame(height: self.getHeightPercentFactor(using: geometry, for: 24))
            .aspectRatio(1, contentMode: .fit)
            .border(.clear, width: 0)
            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
            .buttonStyle(.plain)
        }
    }
    private func actionViewForType(_ type : FTNotebookCreateWidgetActionType, geometry: GeometryProxy) -> some View {
        return HStack(alignment: .center, spacing:self.getWidthPercentFactor(using: geometry, for: 10)) {
            if type.hasASystemIcon {
                Image(systemName: type.iconName)
                    .frame(height: self.getHeightPercentFactor(using: geometry, for: 24))
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.leading,self.getWidthPercentFactor(using: geometry, for: 12))
                    .foregroundStyle(Color("creationWidgetButtonTint"))
                    .font(.appFont(for: .medium, with: 16))
            } else {
                Image("\(type.iconName)")
                    .frame(height: self.getHeightPercentFactor(using: geometry, for: 24))
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.leading,self.getWidthPercentFactor(using: geometry, for: 12))
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

extension View {
     func getWidthPercentFactor(using geometry: GeometryProxy, for value: CGFloat) -> CGFloat {
        let reqValue = (value/geometry.size.width) *  geometry.size.width
        return reqValue
    }

     func getHeightPercentFactor(using geometry: GeometryProxy, for value: CGFloat) -> CGFloat {
        let reqValue = (value/geometry.size.height) *  geometry.size.height
        return reqValue
    }
}
