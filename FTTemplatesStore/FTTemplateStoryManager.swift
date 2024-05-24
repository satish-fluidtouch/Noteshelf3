//
//  FTTemplateStoryManager.swift
//  FTTemplatesStore
//
//  Created by Narayana on 22/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTTemplateStoryManager {
    static func loadStories() -> [FTTemplateStory] {
        var stories: [FTTemplateStory] = []
        guard let url = storeBundle.url(forResource: "templateStories_en", withExtension: "plist"),
              let data = try? Data(contentsOf: url) else {
            return stories
        }

        let decoder = PropertyListDecoder()
        do {
            stories = try decoder.decode([FTTemplateStory].self, from: data)
            stories = stories.map { story in
                var trimmedStory = story
                trimmedStory.title = story.title.trimmingCharacters(in: .whitespacesAndNewlines)
                trimmedStory.subtitle = story.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
                trimmedStory.titleViewBgColor = story.titleViewBgColor.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmedStory
            }
        } catch {
            NSLog("Not able to load stories: \(error.localizedDescription)")
        }
        return stories
    }
}

struct FTTemplateStory: Codable {
    let largeImageName: String
    let thumbnailRectXPercent: Double
    let thumbnailRectYPercent: Double
    let thumbnailRectWidthPercent: Double
    let thumbnailRectHeightPercent: Double
    var title: String
    var subtitle: String
    var titleViewBgColor: String
}
