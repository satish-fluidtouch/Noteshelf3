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
        CaffeineComplication()
    }
}


struct CaffeineComplication: Widget {
    let kind: String = "Caffeine-Complication"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            ComplcationSampleView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct ComplcationSampleView: View {
    var entry: Provider.Entry

    var body: some View {
        Text("In Progress")
    }
}
