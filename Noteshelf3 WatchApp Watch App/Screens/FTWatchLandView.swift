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
    @StateObject private var viewModel = FTRecordViewModel()

    var body: some View {
        TabView(selection: $selectedPage) {
            FTRecordView(viewModel: viewModel)
            FTRecordingsView()
                .environmentObject(viewModel)
        }.watchOS10OnlyVerticalTabStyle()
    }
}

extension View {
    func watchOS10OnlyVerticalTabStyle() -> some View {
        return self.modifier(WatchOS10OnlyVerticalTabStyle())
    }

    @ViewBuilder func isHidden(_ isHidden: Bool) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }
}

struct WatchOS10OnlyVerticalTabStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(watchOS 10.0, *) {
            content.tabViewStyle(.verticalPage)
        }
    }
}
