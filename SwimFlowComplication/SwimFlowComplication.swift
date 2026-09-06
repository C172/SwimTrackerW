//
//  SwimFlowComplication.swift
//  SwimFlowComplication
//
//  Created by Nello Benini on 2026-09-05.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        // En statisk komplikation som aldrig behöver uppdateras dynamiskt
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct SwimFlowComplicationView: View {
    var entry: SimpleEntry

    // Används för att anpassa utseendet beroende på komplikationstyp
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            Image("ComplicationIcon")
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
        case .accessoryRectangular:
            HStack {
                Image(systemName: "figure.open.water.swim")
                Text("SwimTest")
                    .font(.headline)
            }
        case .accessoryCorner:
            Image(systemName: "figure.open.water.swim")
        default:
            Image(systemName: "figure.open.water.swim")
        }
    }
}


struct SwimFlowComplication: Widget {
    let kind: String = "SwimFlowComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SwimFlowComplicationView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("SwimFlow")
        .description("Starta SwimFlow direkt från urtavlan.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner
        ])
    }
}


