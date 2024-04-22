//
//  FTDeskCenterPanlel_Mac_Extension.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 04/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
extension FTDeskCenterPanelTool {    
    static func toolFor(identifier: NSToolbarItem.Identifier) -> FTDeskCenterPanelTool? {
        let tool = FTDeskCenterPanelTool.allCases.first { eachItem in
            return eachItem.toolbarIdentifier == identifier;
        }
        return tool;
    }

    var toolbarIdentifier: NSToolbarItem.Identifier {
        return NSToolbarItem.Identifier("FTDeskToolbarItem_\(self.rawValue)");
    }
        
    var deskMode: RKDeskMode? {
        switch(self) {
        case .pen:
            return .deskModePen;
        case .highlighter:
            return .deskModeMarker;
        case .shapes:
            return .deskModeShape;
        case .eraser:
            return .deskModeEraser;
        case .lasso:
            return .deskModeClipboard;
        case .textMode:
            return .deskModeText;
        case .favorites:
            return .deskModeFavorites;
        default:
            return nil
        }
    }
    
    static var customizableTools: [NSToolbarItem.Identifier] {
        var customizableItems = [
            FTDeskCenterPanelTool.pen.toolbarIdentifier
            ,FTDeskCenterPanelTool.highlighter.toolbarIdentifier
            ,FTDeskCenterPanelTool.eraser.toolbarIdentifier
            ,FTDeskCenterPanelTool.shapes.toolbarIdentifier
            ,FTDeskCenterPanelTool.textMode.toolbarIdentifier
            ,FTDeskCenterPanelTool.lasso.toolbarIdentifier
            ,FTDeskCenterPanelTool.presenter.toolbarIdentifier
            ,FTDeskCenterPanelTool.hand.toolbarIdentifier
            ,FTDeskCenterPanelTool.favorites.toolbarIdentifier
            ,FTDeskCenterPanelTool.photo.toolbarIdentifier
            ,FTDeskCenterPanelTool.audio.toolbarIdentifier
            ,FTDeskCenterPanelTool.unsplash.toolbarIdentifier
            ,FTDeskCenterPanelTool.pixabay.toolbarIdentifier
            ,FTDeskCenterPanelTool.emojis.toolbarIdentifier
            ,FTDeskCenterPanelTool.stickers.toolbarIdentifier
            ,FTDeskCenterPanelTool.savedClips.toolbarIdentifier
            ,FTDeskCenterPanelTool.page.toolbarIdentifier
            ,FTDeskCenterPanelTool.deletePage.toolbarIdentifier
            ,FTDeskCenterPanelTool.bookmark.toolbarIdentifier
            ,FTDeskCenterPanelTool.tag.toolbarIdentifier
            ,FTDeskCenterPanelTool.rotatePage.toolbarIdentifier
            ,FTDeskCenterPanelTool.duplicatePage.toolbarIdentifier
            ,FTDeskCenterPanelTool.camera.toolbarIdentifier
            ,FTDeskCenterPanelTool.scrolling.toolbarIdentifier
            ,FTDeskCenterPanelTool.savePageAsPhoto.toolbarIdentifier
            ,FTDeskCenterPanelTool.sharePageAsPng.toolbarIdentifier
            ,FTDeskCenterPanelTool.shareNotebookAsPDF.toolbarIdentifier
        ]
        if FTNoteshelfAI.supportsNoteshelfAI {
            customizableItems.append(FTDeskCenterPanelTool.openAI.toolbarIdentifier)
        }
        return customizableItems
    }
    
    static var defaultTools: [NSToolbarItem.Identifier] {
        var items = [
            FTDeskCenterPanelTool.pen.toolbarIdentifier
            ,FTDeskCenterPanelTool.highlighter.toolbarIdentifier
            ,FTDeskCenterPanelTool.eraser.toolbarIdentifier
            ,FTDeskCenterPanelTool.shapes.toolbarIdentifier
            ,FTDeskCenterPanelTool.textMode.toolbarIdentifier
            ,FTDeskCenterPanelTool.lasso.toolbarIdentifier
        ]
        
        if FTNoteshelfAI.supportsNoteshelfAI {
            items.append(FTDeskCenterPanelTool.openAI.toolbarIdentifier)
        }
        
        return items;
    }
    
    static var selectableTools: [NSToolbarItem.Identifier] {
        return [
            FTDeskCenterPanelTool.pen.toolbarIdentifier
            ,FTDeskCenterPanelTool.highlighter.toolbarIdentifier
            ,FTDeskCenterPanelTool.eraser.toolbarIdentifier
            ,FTDeskCenterPanelTool.shapes.toolbarIdentifier
            ,FTDeskCenterPanelTool.textMode.toolbarIdentifier
            ,FTDeskCenterPanelTool.lasso.toolbarIdentifier
            ,FTDeskCenterPanelTool.presenter.toolbarIdentifier
            ,FTDeskCenterPanelTool.hand.toolbarIdentifier
            ,FTDeskCenterPanelTool.favorites.toolbarIdentifier
        ]
    }
    
    static func toolFor(mode : RKDeskMode) -> FTDeskCenterPanelTool? {
        switch mode {
        case .deskModePen:
            return FTDeskCenterPanelTool.pen;
        case .deskModeMarker:
            return FTDeskCenterPanelTool.highlighter;
        case .deskModeEraser:
            return FTDeskCenterPanelTool.eraser;
        case .deskModeShape:
            return FTDeskCenterPanelTool.shapes;
        case .deskModeText:
            return FTDeskCenterPanelTool.textMode;
        case .deskModeClipboard:
            return FTDeskCenterPanelTool.lasso;
        case .deskModeLaser:
            return FTDeskCenterPanelTool.presenter;
        case .deskModeView:
            return FTDeskCenterPanelTool.hand;
        case .deskModeFavorites:
            return FTDeskCenterPanelTool.favorites;
        case .deskModeReadOnly:
            return FTDeskCenterPanelTool.hand;
        default:
            break;
        }
        return nil;
    }
    
}

#endif
