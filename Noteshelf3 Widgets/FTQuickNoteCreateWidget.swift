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
        VStack {
            Image("createQuickNote")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.top, .leading], 16.0)
            Spacer()
            Text(quickNoteTitle)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.clearFaceFont(for: .bold, with: 20))
                .foregroundColor(Color.white)
                .padding([.bottom, .leading], 20.0)
        }
        .frame(width: 155, height: 155)
        .clipShape(RoundedRectangle(cornerRadius: 24.0))
    }
    
    private var quickNoteTitle : String {
        let create = "Create".localized
        let quickNote = "QuickNote".localized
        return "\(create) \n\(quickNote)"
    }
}

struct FTQuickNoteCreateView_Previews: PreviewProvider {
    static var previews: some View {
        FTQuickNoteCreateView()
    }
}

