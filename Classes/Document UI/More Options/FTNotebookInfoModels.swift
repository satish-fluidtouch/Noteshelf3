//
//  FTNotebookInfoModels.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 05/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

//========================
struct FTNotebookInfoSection {
    var properties: [FTNotebookInfoProperty] = [FTNotebookInfoProperty]()
}
//========================

protocol FTNotebookInfoProperty {
    var title: String {get}
    var description: String {get set}
}

struct FTNotebookInfoTitle: FTNotebookInfoProperty {
    var title: String {
        return NSLocalizedString("Title", comment: "Title")
    }
    var description: String
    
    init(description: String) {
        self.description = description
    }
}

struct FTNotebookInfoCreated: FTNotebookInfoProperty {
    var title: String {
        return NSLocalizedString("Created", comment: "Created")
    }
    var description: String
    
    init(description: String) {
        self.description = description
    }
}

struct FTNotebookInfoUpdated: FTNotebookInfoProperty {
    var title: String {
        return NSLocalizedString("shelfItemInfo.modified", comment: "Modified")
    }
    var description: String
    
    init(description: String) {
        self.description = description
    }
}

struct FTNotebookInfoCategory: FTNotebookInfoProperty {
    var title: String {
        return NSLocalizedString("shelfItemInfo.where".localized, comment: "Where")
    }
    var description: String
    
    init(description: String) {
        self.description = description
    }
}

struct FTNotebookInfoGotoPage: FTNotebookInfoProperty {
    var title: String {
        return NSLocalizedString("GoToPage", comment: "Go to Page")
    }
    var description: String
    
    init(description: String) {
        self.description = description
    }
}


struct FTNotebookInfoPageNumber: FTNotebookInfoProperty {
    var title: String {
        return NSLocalizedString("Page", comment: "Page")
    }
    var description: String
    
    init(description: String) {
        self.description = description
    }
}

struct FTNotebookInfoPageCreated: FTNotebookInfoProperty {
    var title: String {
        return NSLocalizedString("PageCreated", comment: "Page Created")
    }
    var description: String
    
    init(description: String) {
        self.description = description
    }
}

struct FTNotebookInfoPageUpdated: FTNotebookInfoProperty {
    var title: String {
        return NSLocalizedString("pagemodified", comment: "Page Modified")
    }
    var description: String
    
    init(description: String) {
        self.description = description
    }
}
struct FTNotebookInfoPageDimensions : FTNotebookInfoProperty {
    var title:String {
        return NSLocalizedString("PageDimensions", comment: "Page Dimensions")
    }
    var description: String
    init(description: String) {
        self.description = description
    }
}
//========================
