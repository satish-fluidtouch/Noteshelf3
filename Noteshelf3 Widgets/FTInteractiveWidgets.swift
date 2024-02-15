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
import FTCommon

struct FTPinnedBookEntry: TimelineEntry {
    let date: Date
    let name: String
    let time: String
    let coverImage: String
}
struct FTPinnedTimelineProvider: IntentTimelineProvider {
    typealias Entry = FTPinnedBookEntry
    
    typealias Intent = FTPinnedIntentConfigurationIntent
    
    
    func placeholder(in context: Context) -> FTPinnedBookEntry {
        
        return FTPinnedBookEntry(date: Date(), name: "PlaceHolder", time: "5:00PM", coverImage: "coverImage1")
    }

    func getSnapshot(for configuration: FTPinnedIntentConfigurationIntent,
                     in context: Context,
                     completion: @escaping (FTPinnedBookEntry) -> ()) {
        let entry = FTPinnedBookEntry(date: Date(), name: "Notebook 1", time: "5:00PM", coverImage: "coverImage1")
        completion(entry)
    }

    func getTimeline(for configuration: FTPinnedIntentConfigurationIntent,
                     in context: Context,
                     completion: @escaping (Timeline<FTPinnedBookEntry>) -> ()) {
        Task {
            let entry = FTPinnedBookEntry(date: Date(), name: configuration.Books?.displayString ?? "Notebook 1", time: configuration.Books?.time ?? "5:00 PM", coverImage: configuration.Books?.coverImage ?? "coverImage1")
            executeTimelineCompletion(completion, timelineEntry: entry)
        }
    }
    
    private func showEmptyState(completion: @escaping (Timeline<FTPinnedBookEntry>) -> ()) {
        let entry = FTPinnedBookEntry(date: Date(), name: "Empty State", time: "6:00 PM", coverImage: "")

        
        // Trigger completion & next fetch happens 15 minutes later
        executeTimelineCompletion(completion, timelineEntry: entry)
    }
    
    func executeTimelineCompletion(_ completion: @escaping (Timeline<FTPinnedBookEntry>) -> (),
                                   timelineEntry: FTPinnedBookEntry) {
        
        // Next fetch happens 15 minutes later
        let nextUpdate = Calendar.current.date(
            byAdding: DateComponents(minute: 15),
            to: Date()
        )!
        
        let timeline = Timeline(
            entries: [timelineEntry],
            policy: .after(nextUpdate)
        )
        
        completion(timeline)
    }
}
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
    @Environment(\.colorScheme) var colorScheme

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                NotebookCreation_WidgetsEntryView()
                    .containerBackground(for: .widget, content: {
                        Rectangle().fill(LinearGradient(colors: [Color("widgetBG1"),Color("widgetBG2")], startPoint: .top, endPoint: .bottom))
                    })
            } else {
                NotebookCreation_WidgetsEntryView()
                    .padding()
                    .background()
            }
        }.contentMarginsDisabled()
        .configurationDisplayName("Take Notes")
        .description("Create a blank notebook, record audio or scan and import a document instantly")
        .supportedFamilies([.systemMedium])
    }
    var widgetGradientBG : [Color] {
        if colorScheme == .light {
            return [Color(uiColor: UIColor(hexString: "#F0EEEB")),Color(uiColor: UIColor(hexString: "#FFFFFF"))]
        } else {
            return [Color(uiColor: UIColor(hexString: "#282828")),Color(uiColor: UIColor(hexString: "#141414"))]
        }
    }
}

struct FTPinnedWidget: Widget {
    let kind: String = "InteractiveWidgets"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: FTPinnedIntentConfigurationIntent.self, provider: FTPinnedTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                FTPinnedWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .widgetURL(appUrl())
            } else {
                FTPinnedWidgetView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Notebook")
        .description(" Get quick access to one of your notebooks.")
    }

    private func appUrl() -> URL? {
        var components = URLComponents();
        components.scheme = FTSharedGroupID.getAppBundleID()
        components.path = "/"
        components.queryItems = [URLQueryItem(name: "intent", value: "pinnedWidget")];
        return components.url
    }
}

struct FTPinnedNotebookOptionsWidget: Widget {
    let kind: String = "InteractiveWidgets"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: FTPinnedIntentConfigurationIntent.self, provider: FTPinnedTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                FTPinnedNotebookOptionsWidgetView(entry: entry)
                    .containerBackground(.clear, for: .widget)
            } else {
                FTPinnedNotebookOptionsWidgetView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Notebook")
        .description(" Get quick access to one of your notebooks.")
    }
}

struct FTQuickNoteCreateWidget: Widget {
    let kind: String = "QuickNoteCreationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                FTQuickNoteCreateView()
                    .containerBackground(for: .widget, content: {
                        Rectangle().fill(LinearGradient(colors: [Color(hex: "E78971"), Color(hex: "E06E51")], startPoint: .top, endPoint: .bottom))
                    }).widgetURL(appUrl())
            } else {
                FTQuickNoteCreateView()
                    .padding()
                    .background()
            }
        }.contentMarginsDisabled()
            .configurationDisplayName("Quick Note")
            .description("Create a quick note")
            .supportedFamilies([.systemSmall])
    }

    private func appUrl() -> URL? {
        var components = URLComponents();
        components.scheme = FTSharedGroupID.getAppBundleID()
        components.path = "/"
        components.queryItems = [URLQueryItem(name: "intent", value: "quickNote")]
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
