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
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: Provider()) { entry in
            FTComplicationView(entry: entry)
                .widgetBackground(Color.clear)
        }
        .configurationDisplayName("Noteshelf3")
        .description("Opens Noteshelf3 app")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}


struct FTComplicationView: View {
    var entry: SimpleEntry
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
            Text("Noteshelf3")
        }
    }
}

struct FTComplicationInline : View {
    var entry: Provider.Entry

    var body: some View {
        Text("Noteshelf3")
    }
}

struct FTComplicationCircular : View {
    var entry: SimpleEntry
    @Environment(\.widgetRenderingMode) var widgetRenderingMode

    var body: some View {
        Image(widgetRenderingMode == .fullColor ? "circular_complication" : "circular_complication_gray")
            .resizable()
    }
}

struct FTComplicationCorner : View {
    var entry: SimpleEntry
    @Environment(\.widgetRenderingMode) var widgetRenderingMode

    var body: some View {
        Image(widgetRenderingMode == .fullColor ? "corner_complication" : "corner_complication_gray")
            .resizable()
    }
}

struct FTComplicationRectangular : View {
    var entry: SimpleEntry
    @Environment(\.widgetRenderingMode) var widgetRenderingMode

    var body: some View {
        HStack(spacing: 8) {
            Image(widgetRenderingMode == .fullColor ? "circular_complication" : "circular_complication_gray")
                .resizable()
                .frame(width: 44, height: 44)
            
            if entry.isRecording {
                Text("Recording")
                    .font(Font.system(size: 18))
                    .foregroundStyle(.white)
            }
        }
    }
}
