//
//  Noteshelf3_Watch_WidgetsBundle.swift
//  Noteshelf3 Watch WidgetExtension
//
//  Created by Narayana on 19/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct Noteshelf3_Watch_WidgetsBundle: WidgetBundle {
    var body: some Widget {
        FTWatchComplication()
    }
}

struct FTWatchComplication: Widget {
    let kind: String = "FT-Complication"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            FTComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }

//        StaticConfiguration(kind: kind, provider: Provider()) { entry in
//            FTComplicationView(entry: entry)
//        }
//        .configurationDisplayName("NS3 Opener")
//        .description("Opens Noteshelf3 app")
//        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
//    }
}

struct FTComplicationView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .accessoryCorner:
            FTComplicationCorner(entry: entry)
        case .accessoryCircular:
            FTComplicationCircular(entry: entry)
        case .accessoryInline:
            FTComplicationInline(entry: entry)
        case .accessoryRectangular:
            FTComplicationRectangular(entry: entry)
        @unknown default:
            //mandatory as there are more widget families as in lockscreen widgets etc
            Text("Not an implemented widget yet")
        }
    }

}

struct FTComplicationInline : View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.date.formatted())
    }
}

struct FTComplicationCircular : View {
    var entry: Provider.Entry

    var body: some View {
        Image("watch_complication")
    }
}

struct FTComplicationCorner : View {
    var entry: Provider.Entry

    var body: some View {
        Image("watch_complication")
    }
}

struct FTComplicationRectangular : View {
    var entry: Provider.Entry

    var body: some View {
        Image("watch_complication")
    }
}

