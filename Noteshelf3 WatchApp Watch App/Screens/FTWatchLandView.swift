//
//  FTWatchLandView.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 07/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import WidgetKit
import UIKit

struct FTWatchLandView: View {
    @State var selectedPage: Int = 0
    @StateObject private var viewModel = FTRecordViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedPage) {
            FTRecordView(viewModel: viewModel)
            FTRecordingsView()
                .environmentObject(viewModel)
        }.watchOS10OnlyVerticalTabStyle()
            .onChange(of: scenePhase) { newValue in
                switch newValue {
                case .active, .background:
                    if viewModel.isRecording && !FTWidgetDefaults.shared().isRecording ||  !viewModel.isRecording && FTWidgetDefaults.shared().isRecording {
                        print("zzzz - viewModel.isRecording - \(viewModel.isRecording) \n FTWidgetDefaults.shared().isRecording - \(FTWidgetDefaults.shared().isRecording)")
                        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
                    }
                default:
                    break
                }
            }
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
