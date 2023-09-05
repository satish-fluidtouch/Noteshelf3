//
//  FTShelfItemAttributes.swift
//  Noteshelf
//
//  Created by Amar on 14/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
enum RKShelfItemType: Int {
    case noteBook
    case userGuide
    case group
    case pdfDocument
    case shelfCollection
}

@objc enum FTShelfSortOrder : Int ,Equatable {
    case none = -1
    case byModifiedDate
    case byName
    case manual // None - will be displayed in the UI
    case byCreatedDate //Should be private
    case byLastOpenedDate
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue;
    }
    
    static func supportedSortOptions() -> [FTShelfSortOrder] {
        return [.byLastOpenedDate, .byModifiedDate, .byName, .manual]
    }

    static func supportedSortOptionsForNS2Books() -> [FTShelfSortOrder] {
        return [.byModifiedDate, .byName]
    }
    
    var displayTitle: String {
        switch self {
        case .none:
            return "NoSort" //Never be used for UI
        case .byModifiedDate:
            return NSLocalizedString("shelf.sort.dateModified", comment: "Date Modified")
        case .byName:
            return NSLocalizedString("shelf.sort.name", comment: "Name")
        case .manual: //None will be displayed in the UI
            return NSLocalizedString("shelf.sort.custom", comment: "Custom")
        case .byCreatedDate:
            return NSLocalizedString("SortByCreationDate", comment: "Created Date")
        case .byLastOpenedDate:
            return NSLocalizedString("shelf.sort.dateOpen", comment: "Date Last Opened")
        }
    }
    
    var eventNameString: String {
        var order = "Date";
        switch self {
        case .none:
            order = "Created Date"
        case .byModifiedDate:
            order = "Shelf_TapDate"
        case .byName:
            order = "Shelf_TapName"
        case .manual:
            order = "Shelf_TapCustom"
        case .byCreatedDate:
            order = "Created Date"
        case .byLastOpenedDate:
            order = "Last Open Date"
        }
        return order;
    }
    var iconName: String {
        let iconName: String
        switch self {
        case .byModifiedDate:
            iconName = "clock"
        case .byName:
            iconName = "character"
        case .manual:
            iconName = "rectangle.3.group"
        case .byCreatedDate,.none:
            iconName = ""
        case .byLastOpenedDate:
            iconName = "calendar"
        }
        return iconName
    }
}

protocol FTDiskItemProtocol : NSObjectProtocol {
    init(fileURL : Foundation.URL);

    var title : String {get};
    var displayTitle : String {get};
    var URL : Foundation.URL {get set};
    
    var uuid : String {get set};
    var type : RKShelfItemType {get};
}

protocol FTShelfItemProtocol : FTDiskItemProtocol {
    //basic properties
    var fileModificationDate : Date {get};
    var fileCreationDate : Date {get};
    var fileLastOpenedDate : Date {get};

    var parent : FTGroupItemProtocol? {get set};
    var shelfCollection : FTShelfItemCollection! {get set};
    var enSyncEnabled: Bool {get};
}

protocol FTDocumentItemProtocol : FTShelfItemProtocol{
    //download progress info
    var isDownloaded : Bool {get set};
    var downloadProgress : Float {get set};
    var isDownloading  : Bool {get set};
    
    //upload progress info
    var isUploaded : Bool {get set};
    var uploadProgress : Float {get set};
    var isUploading  : Bool {get set};

    //updated once the package is downloaded
    var documentUUID : String? {get set};
    
    func updateShelfItemInfo(_ metaData : NSMetadataItem);
    func updateLastOpenedDate();
}

protocol FTGroupItemProtocol : FTShelfItemProtocol {
    var childrens : [FTShelfItemProtocol] { get set};
    func addChild(_ childItem : FTShelfItemProtocol);
    func removeChild(_ childItem : FTShelfItemProtocol);
    func invalidateTop3Notebooks()
    var isUpdated: Bool {get set};
}

protocol FTShelfImage : FTDiskItemProtocol {
    var image : UIImage? {get};
}

#if targetEnvironment(macCatalyst)
extension FTShelfSortOrder {
    var menuIdentifier: UIAction.Identifier? {
        switch self {
        case .byLastOpenedDate:
            return UIAction.Identifier("shelfSortLastOpened");
        case .byModifiedDate:
            return UIAction.Identifier("shelfSortLastModified");
        case .byName:
            return UIAction.Identifier("shelfSortName");
        case .manual:
            return UIAction.Identifier("shelfSortCustom");
        case .byCreatedDate:
            return UIAction.Identifier("");
        case .none:
            return nil
        }
    }
    #if !NOTESHELF_ACTION
    var menuItem: UIKeyCommand {
        var command: UIKeyCommand;
        switch self {
        case .byCreatedDate:
            command = UIKeyCommand(title: self.displayTitle,
                                   image: nil,
                                   action: #selector(FTMenuActionResponder.sortByCreatedDate(_:)),
                                   input: "5",
                                   modifierFlags: [.command, .control, .alternate],
                                   propertyList: nil)
        case .byLastOpenedDate:
            command = UIKeyCommand(title: self.displayTitle,
                                   image: nil,
                                   action: #selector(FTMenuActionResponder.sortByLastOpenedDate(_:)),
                                   input: "1",
                                   modifierFlags: [.command, .control, .alternate],
                                   propertyList: nil)
        case .byModifiedDate:
            command = UIKeyCommand(title: self.displayTitle,
                                    image: nil,
                                    action: #selector(FTMenuActionResponder.sortByModifiedDate(_:)),
                                    input: "2",
                                   modifierFlags: [.command, .control, .alternate],
                                    propertyList: nil)
        case .byName:
            command = UIKeyCommand(title: self.displayTitle,
                                    image: nil,
                                    action: #selector(FTMenuActionResponder.sortByName(_:)),
                                    input: "3",
                                   modifierFlags: [.command, .control, .alternate],
                                    propertyList: nil)
        case .manual:
            command = UIKeyCommand(title: self.displayTitle,
                                    image: nil,
                                    action: #selector(FTMenuActionResponder.sortByManual(_:)),
                                    input: "4",
                                   modifierFlags: [.command, .control, .alternate],
                                    propertyList: nil)
        case .none:
            fatalError("Should not come here");
        }
        return command;
    }
    #endif
}
#endif
