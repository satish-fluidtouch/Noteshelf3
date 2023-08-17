//
//  FTAddMenuItemManager.swift
//  FTAddOperations
//
//  Created by Siva on 04/06/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import Foundation

class FTAddMenuItemManager {
    fileprivate lazy var pageMenuItems : [[FTAddMenuItemProtocol]] = {
        
        var section1 = [FTAddMenuItemProtocol]()
        section1.append(PageMenuItem())
        section1.append(PageFromTemplateMenuItem())
        section1.append(PhotoBackgroundMenuItem())
        section1.append(ImportDocumentMenuItem())
        
        #if !targetEnvironment(macCatalyst)
        section1.append(ImportScanDocumentMenuItem())
        #endif
        
        var section2 = [FTAddMenuItemProtocol]()
        if FTPasteBoardManager.shared.isUrlValid() {
            section2.append(InsertFromClipboardMenuItem())
        }
        
        let array = [section1,section2]
        return array
    }()
    
    fileprivate lazy var mediaMenuItems : [[FTAddMenuItemProtocol]] = {
        var section1 = [FTAddMenuItemProtocol]()
        section1.append(CameraMenuItem())
        section1.append(PhotoLibraryMenuItem())
        section1.append(EmojisMenuItem())
        
        var section2 = [FTAddMenuItemProtocol]()
        section2.append(RecordAudioMenuItem())
        section2.append(RecordingsMenuItem())
        
        var section3 = [FTAddMenuItemProtocol]()
        section3.append(MediaLibraryMenuItem())
        section3.append(InsertMenuItem())
        
        let array = [section1, section2, section3]
        return array
    }()
    
    fileprivate lazy var addMenuItems : [[FTAddMenuItemProtocol]] = {
        var arItems = [FTAddMenuItemProtocol]()
        arItems.append(PageTagMenuItem())
        arItems.append(BookmarkTagMenuItem())
        let array = [arItems]
        return array
    }()
    
    func fetchMenuItemsFor(_ menuType: AddMenuType) -> [[FTAddMenuItemProtocol]] {
        switch menuType {
        case .pages:
            return pageMenuItems
        case .media:
            return mediaMenuItems
        case .externalMedia:
            return addMenuItems
        }
    }
    func updateUserPreferences(with items:[FTAddMenuItemProtocol]) {
    }
}

