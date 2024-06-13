//
//  FTCustomizeToolbarDataSource.swift
//  Noteshelf3
//
//  Created by Narayana on 27/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

let currentCenterPanelTypesKey = "CurrentCenterPanelToolTypes"

class FTCustomizeToolbarDataSource: NSObject {
    var sections: [FTToolbarSection] = []

    override init() {
        super.init()
        self.prepareSections()
    }

    private func prepareSections() {
        self.sections = [FTCurrentToolbarSection(),
                         FTBasicToolsSection(),
                         FTAddMenuToolsSection(),
                         FTShortcutsToolsSection()]
        if FTFeatureConfigHelper.shared.isFeatureEnabled(.Share) {
            self.sections.append(FTShareAndSaveToolsSection())
        }
    }

    func removeDisplayTool(_ tool: FTDeskCenterPanelTool, from section: FTToolbarSection) {
        if var reqSection = self.sections.filter({ sec in
            sec.type == section.type
        }).first {
            reqSection.displayTools.removeAll { type in
                type == tool
            }
        }
    }

    func insertTool(_ tool: FTDeskCenterPanelTool, at index: Int, in sectionType: FTCustomizeToolbarSectionType) {
        guard var reqSection = self.sections.filter({ sec in
            sec.type == sectionType
        }).first else {
            fatalError("Programmer error, no such sectioon type found")
        }
        reqSection.displayTools.insert(tool, at: index)
    }

    func insertTool(_ tool: FTDeskCenterPanelTool, of sectionType: FTCustomizeToolbarSectionType) -> Int {
        guard var reqSection = self.sections.filter({ sec in
            sec.type == sectionType
        }).first else {
            fatalError("Programmer error, no such sectioon type found")
        }
        let index = reqSection.displayTools.insertionIndexOf(tool) { $0.rawValue < $1.rawValue }
        reqSection.displayTools.insert(tool, at: index)
        return index
    }

    func appendToolToCurrentToolbarSection(tool: FTDeskCenterPanelTool) {
        if var reqSection = self.sections.filter({ sec in
            sec.type == .currentToolbar
        }).first {
            reqSection.displayTools.append(tool)
        }
    }

    func sectionType(for type: FTDeskCenterPanelTool) -> FTCustomizeToolbarSectionType {
        var reqSectionType: FTCustomizeToolbarSectionType = .currentToolbar
        if FTBasicToolsSection().tools.contains(type) {
            reqSectionType = .basicTools
        } else if FTAddMenuToolsSection().tools.contains(type) {
            reqSectionType = .addMenu
        } else if FTShortcutsToolsSection().tools.contains(type) {
            reqSectionType = .shortcuts
        } else if FTShareAndSaveToolsSection().tools.contains(type) {
            reqSectionType = .shareAndSave
        }
        return reqSectionType
    }

    func resetToDefaults() {
        var types: [FTDeskCenterPanelTool] = [.pen, .highlighter, .eraser, .shapes, .textMode, .lasso, .hand]
        if FTNoteshelfAI.supportsNoteshelfAI {
            types.append(.openAI)
        }
        FTCurrentToolbarSection.saveCurrentToolTypes(types)
    }
}

extension Array {
    func insertionIndexOf(_ elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
}
