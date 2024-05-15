//
//  FTQuickNoteCreateWidget.swift
//  Noteshelf3
//
//  Created by Narayana on 14/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon
import WidgetKit
import AppIntents

struct FTQuickNoteCreateView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Image("createQuickNote")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.top, .leading], geometry.size.width * FTQuickNoteWidgetConfigFactors.padding16)
                Spacer()
                Text(quickNoteTitle)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.clearFaceFont(for: .bold, with: 20))
                    .foregroundColor(Color.white)
                    .padding([.bottom, .leading], FTQuickNoteWidgetConfigFactors.padding20 * geometry.size.width)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24.0))
        }
    }
    
    private var quickNoteTitle : String {
        let create = "Create".localized
        let quickNote = "QuickNote".localized
        return "\(create) \n\(quickNote)"
    }
}

// Below factors are calculated based on widget size as per figma to maintain in all devices properly
fileprivate struct FTQuickNoteWidgetConfigFactors {
    static let padding16 = 0.10 // 16
    static let padding20 = 0.13 // 20
}

struct FTQuickNoteCreateView_Previews: PreviewProvider {
    static var previews: some View {
        FTQuickNoteCreateView()
    }
}

