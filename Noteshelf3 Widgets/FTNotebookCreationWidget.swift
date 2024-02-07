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

enum NotebookCreationType {
    case quickNote
    case newNotebook
    case audioNote
    case scan

    var title : String {
        let title : String
        switch self {
        case .quickNote:
            title = "Quick Note"
        case .newNotebook:
            title = "New Notebook"
        case .audioNote:
            title = "Audio Note"
        case .scan:
            title = "Scan"
        }
        return title
    }
    var iconName : String {
        let iconName : String
        switch self {
        case .quickNote:
            iconName = "plus.circle"
        case .newNotebook:
            iconName = "newNotebookIcon"
        case .audioNote:
            iconName = "mic"
        case .scan:
            iconName = "scanner"
        }
        return iconName
    }
    var hasASystemIcon : Bool {
        let isSystemIcon : Bool
        switch self {
        case .quickNote:
            isSystemIcon = true
        case .newNotebook:
            isSystemIcon = false
        case .audioNote:
            isSystemIcon = true
        case .scan:
            isSystemIcon = true
        }
        return isSystemIcon
    }
}
struct NotebookCreation_WidgetsEntryView : View {
    var body: some View {
        VStack(spacing:10.0) {
            headerView
                .frame(height: 24,alignment: .center)
            optionsView
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    private var optionsView : some View {
        Grid(alignment: .center, horizontalSpacing: 6,verticalSpacing: 6 ) {
            GridRow {
                optionViewForType(.quickNote)
                optionViewForType(.newNotebook)
            }
            GridRow {
                optionViewForType(.audioNote)
                optionViewForType(.scan)
            }
        }
        .frame(height: 88)
    }
    private func optionViewForType(_ type : NotebookCreationType) -> some View {
        Button(intent: SearchIntent()) {
            actionViewForType(type)
        }
        .frame(height: 42,alignment: .leading)
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var headerView : some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing:10) {
            Image("appIconSmall")
                .frame(width: 20,height: 20,alignment: .center)
                .padding(.leading,8)
            Text("Noteshelf")
                .frame(height: 24, alignment: .center)
                .font(.appFont(for: .bold, with: 13))
            Spacer()
            if #available(iOS 17.0, *) {
                Button(intent: SearchIntent()) {
                    Image("searchIcon")
                        .frame(width: 20,height: 20)
                }
                .frame(width: 20,height: 20)
                .border(.clear, width: 0)
                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
            } else {
                Button(action: {

                }, label: {
                    Text("Button")
                })
            }
        }
    }
    private func actionViewForType(_ type : NotebookCreationType) -> some View {
        return HStack(alignment: .center, spacing:8) {
            if type.hasASystemIcon {
                Image(systemName: type.iconName)
                    .frame(width: 20,height: 20,alignment: .center)
                    .padding(.leading,10)
                    .foregroundStyle(Color.appColor(.accent))
                    .font(.appFont(for: .medium, with: 17))
            } else {
                Image("\(type.iconName)")
                    .frame(width: 20,height: 20,alignment: .center)
                    .padding(.leading,10)
                    .foregroundStyle(Color.appColor(.accent))
                    .font(.appFont(for: .medium, with: 17))
            }
            Text(type.title)
                .font(.appFont(for: .bold, with: 11))
                .foregroundStyle(Color.black)
        }
        .frame(maxWidth: .infinity,maxHeight: 42,alignment: .leading)
        .background(Color(uiColor: UIColor(hexString: "#F5F0EB",alpha: 0.75)))
    }
}


