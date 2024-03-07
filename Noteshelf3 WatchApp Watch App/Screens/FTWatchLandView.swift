//
//  FTWatchLandView.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 07/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTWatchLandView: View {
    @State var selectedPage: Int = 0

    var body: some View {
        TabView(selection: $selectedPage) {
            FTRecordView()
            FTRecordingsView()
        }.tabViewStyle(.page)
    }
}
