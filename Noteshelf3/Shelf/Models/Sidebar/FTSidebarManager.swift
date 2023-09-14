//
//  FTSidebarHelper.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 08/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTSidebarManager {

    static func copyBundleDataIfNeeded() {
        let fileManager = FileManager.default
        let sourcePlistURL = FTSidebarManager.resourcePlistUrl
        let sideBarPlistURL = FTSidebarManager.sidebarPlistURL

        if fileManager.fileExists(atPath: sideBarPlistURL.path) == false {
            do {
                try fileManager.copyItem(at: sourcePlistURL, to: sideBarPlistURL)
            }
            catch {
                print("There is a problem in copying Sidebar Database")
            }
        }
    }

    static var resourcePlistUrl: URL {
        guard let sourcePlistURL = Bundle.main.url(forResource: "FTSideBar", withExtension: "plist") else {
            fatalError("Programmer error, plit is not available")
        }
        return sourcePlistURL
    }
    static var sidebarPlistURL: URL {
        let documentURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let plistURL = documentURL.appendingPathComponent("FTSideBar.plist")
        return plistURL
    }

    static func getSideBarData() -> [String:AnyObject] {
        var sideBarDictionary: [String : Any] = [:]
        do {
            let sideBarData = try Data(contentsOf: self.sidebarPlistURL)
            if let sideBarDictionary = try PropertyListSerialization.propertyList(from: sideBarData, options: [], format: nil) as? [String : Any] {
                var sideBarDict: [String:AnyObject] = [:]
                sideBarDict["SideBarStatus"] = sideBarDictionary["SideBarStatus"] as AnyObject
                sideBarDict["SideBarItemsOrder"] = sideBarDictionary["SideBarItemsOrder"] as AnyObject
                return sideBarDict
            }
            else {
                sideBarDictionary = [String : AnyObject]()
            }
        }
        catch {
            sideBarDictionary = [String : AnyObject]()
        }
        return sideBarDictionary as [String:AnyObject]
    }

    public static func save(sideBarData : [String:Bool]) {
        do {
            let actualSideBarData = try Data(contentsOf: self.sidebarPlistURL)
            if var sideBarDictionary = try PropertyListSerialization.propertyList(from: actualSideBarData, options: [], format: nil) as? [String: Any] {
                sideBarDictionary["SideBarStatus"] = sideBarData
                let updatedData = try PropertyListSerialization.data(fromPropertyList: sideBarDictionary as AnyObject, format: PropertyListSerialization.PropertyListFormat.xml, options: 0)
                try updatedData.write(to: self.sidebarPlistURL, options: NSData.WritingOptions.atomic)
            }
        }
        catch {
            print("Error occured while saving" + "\(String(describing: "SideBarStatus"))" + "data.")
        }
    }
    public static func saveCategoriesBookmarData(_ categoriesBookmarData:FTCategoryBookmarkData) {
        do {
            let actualSideBarData = try Data(contentsOf: self.sidebarPlistURL)
            if var sideBarDictionary = try PropertyListSerialization.propertyList(from: actualSideBarData, options: [], format: nil) as? [String: Any] {
                if var actualSideBarItemsOrderDict = sideBarDictionary["SideBarItemsOrder"] as? [String:Any] {
                    let bookmarkData = try PropertyListEncoder().encode(categoriesBookmarData)
                    actualSideBarItemsOrderDict["categories"] = bookmarkData
                    sideBarDictionary["SideBarItemsOrder"] = actualSideBarItemsOrderDict
                    let updatedData = try PropertyListSerialization.data(fromPropertyList: sideBarDictionary as AnyObject, format: PropertyListSerialization.PropertyListFormat.xml, options: 0)
                    try updatedData.write(to: self.sidebarPlistURL, options: NSData.WritingOptions.atomic)
                }
            }
        }
        catch {
            print("Error occured while saving" + "\(String(describing: "SideBarStatus"))" + "data.")
        }
    }
}
