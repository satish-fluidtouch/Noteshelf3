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
    let relativePath: String
    let hasCover: Bool
    let isLandscape: Bool
    let docId: String
    
    public var bookOpenintent: FTPinnedBookOpenIntent {
        let intent = FTPinnedBookOpenIntent();
        intent.docId = self.docId;
        return intent
    }
    
    public var penIntent: FTPinnedPenIntent {
        let intent = FTPinnedPenIntent();
        intent.docId = self.docId;
        return intent
    }
    
    public var audioIntent: FTPinnedAudioIntent {
        let intent = FTPinnedAudioIntent();
        intent.docId = self.docId;
        return intent
    }
    
    public var aiIntent: FTPinnedOpenAIIntent {
        let intent = FTPinnedOpenAIIntent();
        intent.docId = self.docId;
        return intent
    }
    
    public var textIntent: FTPinnedTextIntent {
        let intent = FTPinnedTextIntent();
        intent.docId = self.docId;
        return intent
    }
}
struct FTPinnedTimelineProvider: IntentTimelineProvider {
    typealias Entry = FTPinnedBookEntry
    
    typealias Intent = FTPinnedIntentConfigurationIntent
    
    private var sharedCacheURL: URL {
        if let url = FileManager().containerURL(forSecurityApplicationGroupIdentifier: FTSharedGroupID.getAppGroupID()) {
            let directoryURL = url.appending(path: FTSharedGroupID.notshelfDocumentCache);
            return directoryURL
        }
        fatalError("Failed to get path");
    }
    func placeholder(in context: Context) -> FTPinnedBookEntry {
        
        return FTPinnedBookEntry(date: Date(), name: "PlaceHolder", time: "5:00PM", coverImage: "coverImage1", relativePath: "", hasCover: false, isLandscape: false, docId: "")
    }

    func getSnapshot(for configuration: FTPinnedIntentConfigurationIntent,
                     in context: Context,
                     completion: @escaping (FTPinnedBookEntry) -> ()) {
        let entry = defaultBookEntry()
        completion(entry)
    }

    func getTimeline(for configuration: FTPinnedIntentConfigurationIntent,
                     in context: Context,
                     completion: @escaping (Timeline<FTPinnedBookEntry>) -> ()) {
        Task {
            var entry = emptyEntry()
            if var selectedBook = configuration.Books {
                if FTWidgetIntentDataHelper.checkIfBookExists(for: selectedBook) {
                    FTWidgetIntentDataHelper.updateNotebookIfNeeded(for: &selectedBook)
                    entry = FTPinnedBookEntry(date: Date(), name: FTWidgetIntentDataHelper.displayName(from: selectedBook.relativePath ?? ""), time: selectedBook.time ?? "5:00 PM", coverImage: selectedBook.coverImage ?? "coverImage1", relativePath: selectedBook.relativePath ?? "", hasCover: selectedBook.hasCover?.boolValue ?? false, isLandscape: selectedBook.isLandscape?.boolValue ?? false, docId: selectedBook.identifier ?? "")
                }
            } else {
                entry = defaultBookEntry()
            }
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
    
    private func emptyEntry() -> FTPinnedBookEntry {
        return FTPinnedBookEntry(date: Date(), name: "Empty State", time: "6:00 PM", coverImage: "", relativePath: "", hasCover: false, isLandscape: false, docId: "")
    }
    
    private func showEmptyState(completion: @escaping (Timeline<FTPinnedBookEntry>) -> ()) {
        let entry = emptyEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func defaultBookEntry() -> FTPinnedBookEntry {
        var entry = emptyEntry()
        if let book = FTWidgetIntentDataHelper.defaultBookEntry() {
            entry = FTPinnedBookEntry(date: Date(), name: book.relativePath.lastPathComponent.deletingPathExtension, time: book.createdTime, coverImage: book.coverImageName, relativePath: book.relativePath, hasCover: book.hasCover, isLandscape: book.isLandscape, docId: book.docId)
        }
        return entry
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
        .description("Create a blank notebook, record audio or scan")
        .supportedFamilies([.systemMedium])
    }
}

struct FTPinnedWidget: Widget {
    let kind: String = FTWidgetKind.pinnedWidget.rawValue
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: FTPinnedIntentConfigurationIntent.self, provider: FTPinnedTimelineProvider()) { entry in
                FTPinnedWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .widgetURL(URLComponents(type: "pinnedWidget", entry: entry)?.url)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Notebook")
        .description(" Get quick access to one of your notebooks.")
    }
}

struct FTPinnedNotebookOptionsWidget: Widget {
    let kind: String = FTWidgetKind.pinnedOptionsWidget.rawValue

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: FTPinnedIntentConfigurationIntent.self, provider: FTPinnedTimelineProvider()) { entry in
            FTPinnedNotebookOptionsWidgetView(entry: entry)
                .containerBackground(for: .widget, content: {
                    Rectangle().fill(LinearGradient(colors: [Color("widgetBG1"),Color("widgetBG2")], startPoint: .top, endPoint: .bottom))
                })
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
                    }).widgetURL(URLComponents(type: "quickNote")?.url)
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
}

private extension URLComponents {
    init?(type: String, entry: TimelineEntry? = nil) {
        self.init()
        self.scheme = FTSharedGroupID.getAppBundleID()
        self.path = "/"
        let param1 = URLQueryItem(name: "intent", value: type)
        self.queryItems = [param1]
        if let entry = entry as? FTPinnedBookEntry {
            self.queryItems?.append(URLQueryItem(name: "relativePath", value: entry.relativePath))
            self.queryItems?.append(URLQueryItem(name: "docId", value: entry.docId))
        }
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    FTPinnedWidget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
}
