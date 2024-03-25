//
//  Noteshelf3_Watch_Widget.swift
//  Noteshelf3 Watch Widget
//
//  Created by Narayana on 19/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

extension View {
    @ViewBuilder func widgetBackground(_ backgroundView: @autoclosure @escaping () -> some View) -> some View {
        if #available(watchOS 10.0, *) {
            containerBackground(for: .widget) {
                backgroundView()
            }
        } else {
            background(backgroundView())
        }
    }
}
