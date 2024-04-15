//
//  FTCustomizeToolbarSection.swift
//  Noteshelf3
//
//  Created by Narayana on 27/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTToolbarSection {
    var tools: [FTDeskCenterPanelTool] { get }
    var type: FTCustomizeToolbarSectionType { get }
    var displayTitle: String { get }
    var displayTools: [FTDeskCenterPanelTool] { get set}
}

extension FTToolbarSection {
    var displayTitle: String {
        return self.type.localizedString()
    }
}

final class FTCurrentToolbarSection: FTToolbarSection {
    var type: FTCustomizeToolbarSectionType = .currentToolbar
    var tools: [FTDeskCenterPanelTool] = FTCurrentToolbarSection.fetchSavedToolTypes()
    var displayTools: [FTDeskCenterPanelTool] = []

    init() {
        self.displayTools = FTCurrentToolbarSection.fetchSavedToolTypes()
    }

    private static func fetchSavedToolTypes() -> [FTDeskCenterPanelTool] {
        var toolTypes: [FTDeskCenterPanelTool] = [
            .pen
            ,.highlighter
            ,.eraser
            ,.shapes
            ,.textMode
            ,.lasso
            ,.hand
        ]
        if FTNoteshelfAI.supportsNoteshelfAI {
            toolTypes.append(.openAI)
        }
        if let savedToolRawValues = UserDefaults.standard.value(forKey: currentCenterPanelTypesKey) as? [Int] {
            toolTypes = savedToolRawValues.map { intValue in
                FTDeskCenterPanelTool(rawValue: intValue) ?? .pen
            }
        }
        return toolTypes
    }

    static func saveCurrentToolTypes(_ types: [FTDeskCenterPanelTool]) {
        let toolRawValues = types.map { $0.rawValue }
        UserDefaults.standard.set(toolRawValues, forKey: currentCenterPanelTypesKey)
    }
}

final class FTBasicToolsSection: FTToolbarSection {
    var type: FTCustomizeToolbarSectionType = .basicTools
    var tools: [FTDeskCenterPanelTool] = [
        .pen
        ,.highlighter
        ,.eraser
        ,.shapes
        ,.textMode
        ,.presenter
        ,.lasso
        ,.hand
        ,.zoomBox
        ,.favorites
    ]

    var displayTools: [FTDeskCenterPanelTool] = []

    init() {
        if FTNoteshelfAI.supportsNoteshelfAI {
            tools.append(.openAI)
        }
        self.displayTools = self.tools.subtract(arr: FTCurrentToolbarSection().tools)
    }
}

final class FTAddMenuToolsSection: FTToolbarSection {
    var type: FTCustomizeToolbarSectionType = .addMenu
    var tools: [FTDeskCenterPanelTool] = [
        .photo,
        .audio,
        .unsplash,
        .pixabay,
        .emojis,
        .stickers,
        .savedClips
    ]
    
    var displayTools: [FTDeskCenterPanelTool] = []

    init() {
        self.displayTools = self.tools.subtract(arr: FTCurrentToolbarSection().tools)
    }
}

final class FTShortcutsToolsSection: FTToolbarSection {
    var type: FTCustomizeToolbarSectionType = .shortcuts
    var tools: [FTDeskCenterPanelTool] = [
        .page,
        .bookmark,
        .tag,
        .rotatePage,
        .duplicatePage,
        .deletePage,
        .scrolling,
        .camera
        
    ]

    var displayTools: [FTDeskCenterPanelTool] = []

    init() {
        self.displayTools = self.tools.subtract(arr: FTCurrentToolbarSection().tools)
    }
}

final class FTShareAndSaveToolsSection: FTToolbarSection {
    var type: FTCustomizeToolbarSectionType = .shareAndSave
    var tools: [FTDeskCenterPanelTool] = [
        .savePageAsPhoto,
        .sharePageAsPng,
        .shareNotebookAsPDF]

    var displayTools: [FTDeskCenterPanelTool] = []

    init() {
        self.displayTools = self.tools.subtract(arr: FTCurrentToolbarSection().tools)
    }
}
