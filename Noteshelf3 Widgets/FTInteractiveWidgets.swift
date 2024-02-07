//
//  FTInteractiveWidgets.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 07/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "😀")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "😀")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, emoji: "😀")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct NotebookCreation_Widget: Widget {
    let kind: String = "NotebookCreation_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                NotebookCreation_WidgetsEntryView()
                    .containerBackground(for: .widget, content: {
                        Rectangle().fill(LinearGradient(colors: [Color(uiColor: UIColor(hexString: "#F0EEEB")),Color(uiColor: UIColor(hexString: "#DCCDBC"))], startPoint: .top, endPoint: .bottom))
                    })
            } else {
                NotebookCreation_WidgetsEntryView()
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemMedium])
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    NotebookCreation_Widget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
}


struct FTPinnedWidget: Widget {
    let kind: String = "InteractiveWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) {  entry in
            if #available(iOS 17.0, *) {
                FTPinnedWidgetView()
                    .containerBackground(.fill.tertiary, for: .widget)
                    .widgetURL(appUrl())
            } else {
                FTPinnedWidgetView()
                    .padding()
                    .background()
                    .widgetURL(appUrl())
            }
        }
        .supportedFamilies([.systemSmall])
    }

    private func appUrl() -> URL? {
        var components = URLComponents();
        components.scheme = "com.fluidtouch.noteshelf3-dev"; //Should be dynamic
//        components.scheme = "com.fluidtouch.noteshelf3"; //Enable this for PROD
//        components.scheme = "com.fluidtouch.noteshelf3-Beta"; //Enale this For BETA

        components.path = "/"
        components.queryItems = [URLQueryItem(name: "intent", value: "pinnedWidget")];
        return components.url
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    FTPinnedWidget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
}
