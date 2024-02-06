//
//  Noteshelf3_Widgets.swift
//  Noteshelf3 Widgets
//
//  Created by Ramakrishna on 05/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import WidgetKit
import SwiftUI
import FTCommon

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

struct Noteshelf3_WidgetsEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            HStack {
                Image("appIconSmall")
                    .padding(.trailing,10)
                    .padding(.leading,8)
                Text("Noteshelf")
                    //.font(.appFont(for: .regular, with: 13))
                Spacer()
                if #available(iOS 17.0, *) {
                    Button(intent: SearchIntent()) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            //.background(Color.appColor(.accent))
                    }
                } else {
                    Button(action: {

                    }, label: {
                        Text("Button")
                    })
                }
            }
            Spacer()
        }
    }
}

struct Noteshelf3_Widgets: Widget {
    let kind: String = "Noteshelf3_Widgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                Noteshelf3_WidgetsEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                Noteshelf3_WidgetsEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct InteractivePinnedWidget: Widget {
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

struct FTPinnedWidgetView : View {
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                topView()
                bottomView()
            }
        }.overlay(alignment: .topLeading) {
            Image("coverImage")
                .frame(width: 38,height: 52)
                .padding(.top, 24)
                .padding(.leading, 24)
        }
    }
}
struct topView: View {
    var body: some View {
        HStack {
            Spacer()
            Image("ns3Icon")
                .frame(width: 20,height: 20)
                .padding(.trailing, 16)
                .padding(.top, 10)
        }.frame(width: 160, height: 48)
        .background(Color(uiColor: UIColor(hexString: "#E06E51")))
    }
}

struct bottomView: View {
    var body: some View {
        HStack {
            VStack {
                Spacer()
                Text("Note book Title")
                    .lineLimit(2)
                Text("5:00 pm")
                    .lineLimit(1)
            }.padding(.leading, 10)
                .padding(.bottom, 12)
            Spacer()
        }.frame(width: 160, height: 110)
            .background(Rectangle().fill(LinearGradient(colors: [Color(uiColor: UIColor(hexString: "#F0EEEB")),Color(uiColor: UIColor(hexString: "#DCCDBC"))], startPoint: .top, endPoint: .bottom)))
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    Noteshelf3_Widgets()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
}
