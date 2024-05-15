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
            VStack(spacing:FTNotebookCreateWidgetConfigFactors.vertcalPadding16*geometry.size.height) {
                headerView(geometry: geometry)
                    .frame(height: FTNotebookCreateWidgetConfigFactors.headerHeight*geometry.size.height,alignment: .center)
                optionsView(geometry: geometry)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal,FTNotebookCreateWidgetConfigFactors.horizantalPadding16*geometry.size.width)
            .padding(.vertical,FTNotebookCreateWidgetConfigFactors.vertcalPadding16*geometry.size.height)
        }
    }
    private func optionsView(geometry: GeometryProxy) -> some View {
        Grid(alignment: .center, horizontalSpacing: FTNotebookCreateWidgetConfigFactors.space4*geometry.size.height,verticalSpacing: FTNotebookCreateWidgetConfigFactors.space4*geometry.size.height) {
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
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: FTNotebookCreateWidgetConfigFactors.hSpace10*geometry.size.width) {
            Image("appIconSmall")
                .frame(height: geometry.size.height*FTNotebookCreateWidgetConfigFactors.height22)
                .aspectRatio(1, contentMode: .fit)
                .padding(.leading,FTNotebookCreateWidgetConfigFactors.hSpace8*geometry.size.width)
            Text("Noteshelf")
                .frame(height: geometry.size.height*FTNotebookCreateWidgetConfigFactors.height24)
                .font(.clearFaceFont(for: .bold, with: 17))
            Spacer()
            Button(intent: SearchIntent()) {
                Image("searchIcon")
                    .frame(height: geometry.size.height*FTNotebookCreateWidgetConfigFactors.height24)
                    .aspectRatio(1, contentMode: .fit)
            }
            .frame(height: geometry.size.height*FTNotebookCreateWidgetConfigFactors.height24)
            .aspectRatio(1, contentMode: .fit)
            .border(.clear, width: 0)
            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
            .buttonStyle(.plain)
        }
    }
    private func actionViewForType(_ type : FTNotebookCreateWidgetActionType, geometry: GeometryProxy) -> some View {
        return HStack(alignment: .center, spacing:FTNotebookCreateWidgetConfigFactors.hSpace10 * geometry.size.width) {
            if type.hasASystemIcon {
                Image(systemName: type.iconName)
                    .frame(height: geometry.size.height*FTNotebookCreateWidgetConfigFactors.height24)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.leading,FTNotebookCreateWidgetConfigFactors.hSpace12*geometry.size.width)
                    .foregroundStyle(Color("creationWidgetButtonTint"))
                    .font(.appFont(for: .medium, with: 16))
            } else {
                Image("\(type.iconName)")
                    .frame(height: geometry.size.height*FTNotebookCreateWidgetConfigFactors.height24)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.leading,FTNotebookCreateWidgetConfigFactors.hSpace12*geometry.size.width)
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

// Below factors are calculated based on widget size as per figma to maintain in all devices properly
fileprivate struct FTNotebookCreateWidgetConfigFactors {
    static let vertcalPadding16: CGFloat = 0.10
    static let horizantalPadding16: CGFloat = 0.04
    static let headerHeight: CGFloat = 0.15
    static let space4: CGFloat = 0.025 // 4 - wrto height
    static let hSpace8: CGFloat = 0.02 // 10
    static let hSpace10: CGFloat = 0.034 // 10
    static let hSpace12: CGFloat = 0.035 // 12
    static let height22: CGFloat = 0.14 // 22
    static let height24: CGFloat = 0.15 // 24
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    NotebookCreation_Widget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
}


