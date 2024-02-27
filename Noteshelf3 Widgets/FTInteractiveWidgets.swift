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
        
        return FTPinnedBookEntry(date: Date(), name: "PlaceHolder", time: "5:00PM", coverImage: "coverImage1", relativePath: "", hasCover: false, isLandscape: false)
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
            var entry = placeholder(in: context)
            if let selectedBook = configuration.Books {
                entry = FTPinnedBookEntry(date: Date(), name: selectedBook.displayString , time: selectedBook.time ?? "5:00 PM", coverImage: selectedBook.coverImage ?? "coverImage1", relativePath: selectedBook.relativePath ?? "", hasCover: selectedBook.hasCover?.boolValue ?? false, isLandscape: selectedBook.isLandscape?.boolValue ?? false)
            } else {
                entry = defaultBookEntry()
            }
            executeTimelineCompletion(completion, timelineEntry: entry)
        }
    }
    
    private func showEmptyState(completion: @escaping (Timeline<FTPinnedBookEntry>) -> ()) {
        let entry = FTPinnedBookEntry(date: Date(), name: "Empty State", time: "6:00 PM", coverImage: "", relativePath: "", hasCover: false, isLandscape: false)

        
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
    
    private func defaultBookEntry() -> FTPinnedBookEntry {
        var entry = FTPinnedBookEntry(date: Date(), name: "PlaceHolder", time: "5:00PM", coverImage: "coverImage1", relativePath: "", hasCover: false, isLandscape: false)
        let sharedCacheURL = self.sharedCacheURL
        if FileManager().fileExists(atPath: sharedCacheURL.path(percentEncoded: false)) {
            if let urls = try? FileManager.default.contentsOfDirectory(at: sharedCacheURL,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles) {
                let notebookFilteredUrls = urls.filter { eachUrl in
                    return eachUrl.pathExtension == "ns3"
                }
                if let eachNotebookUrl = notebookFilteredUrls.first {
                    let relativePath : String
                    let time : String
                    let coverImage : String
                    let metaDataPlistUrl = eachNotebookUrl.appendingPathComponent("Metadata/Properties.plist")
                    relativePath = _relativePath(for: metaDataPlistUrl)
                    let pageAttrs = pageAttrs(for: eachNotebookUrl.path(percentEncoded: false))
                    coverImage = eachNotebookUrl.appending(path:"cover-shelf-image.png").path(percentEncoded: false);
                    time = timeFromDate(currentDate: eachNotebookUrl.fileCreationDate)
                    entry = FTPinnedBookEntry(date: Date(), name: relativePath.lastPathComponent.deletingPathExtension, time: time, coverImage: coverImage, relativePath: relativePath, hasCover: pageAttrs.0, isLandscape: pageAttrs.1)
                }

            }
        }
        return entry
    }
    
    private func _relativePath(for metaDataPlistUrl: URL) -> String {
        var relativePath = ""
        if let data = try? Data(contentsOf: metaDataPlistUrl) {
            if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any], let _relativePath = plist["relativePath"] as? String {
                relativePath = _relativePath
            }
        }
        return relativePath
    }
    
    private func pageAttrs(for notebookPath: String) -> (Bool, Bool) {
        var hasCover = false
        var isLandscape = false
        let docPlist = notebookPath.appending("Document.plist")
        do {
            let url = URL(fileURLWithPath: docPlist)
            let dict = try NSDictionary(contentsOf: url, error: ())
            if let pagesArray = dict["pages"] as? [NSDictionary], let firstPage = pagesArray.first {
                if let pageRectPDFKit = firstPage["pdfKitPageRect"] as? String {
                    let rect = NSCoder.cgRect(for: pageRectPDFKit);
                    if rect.width > rect.height {
                        isLandscape = true
                    }
                }
                hasCover = firstPage["isCover"] as? Bool ?? false
            }
        } catch {
            return (hasCover, isLandscape)
        }
        return (hasCover, isLandscape)
    }
    
    private func timeFromDate(currentDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.locale = .current // Set locale to ensure proper representation of AM/PM
        return dateFormatter.string(from: currentDate)
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
            //if #available(iOS 17.0, *) {
                FTPinnedWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .widgetURL(URLComponents(type: "pinnedWidget", entry: entry)?.url)
//            } else {
//                FTPinnedWidgetView(entry: entry)
//                    .padding()
//                    .background()
//                    .widgetURL(URLComponents(type: "pinnedWidget", entry: entry)?.url)          
//            }
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Notebook")
        .description(" Get quick access to one of your notebooks.")
    }
}

struct FTPinnedNotebookOptionsWidget: Widget {
    let kind: String = "InteractiveWidgets"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: FTPinnedIntentConfigurationIntent.self, provider: FTPinnedTimelineProvider()) { entry in
            FTPinnedNotebookOptionsWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
//                .widgetURL(URLComponents(type: "pinnedWidget", entry: entry)?.url)
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
