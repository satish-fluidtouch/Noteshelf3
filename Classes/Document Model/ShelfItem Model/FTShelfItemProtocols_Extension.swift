//
//  FTShelfItemAttributesProtocol_Extension.swift
//  Noteshelf
//
//  Created by Amar on 16/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTDiskItemProtocol
{
    var title : String {
        return self.URL.title;
    }
    
    var displayTitle : String {
        return self.title;
    };
}

extension FTShelfItemProtocol
{
    var type : RKShelfItemType {
        return RKShelfItemType.pdfDocument;
    };
    
    var fileModificationDate : Date {
        return self.URL.fileModificationDate;
    }
    
    var fileCreationDate : Date {
        return self.URL.fileCreationDate;
    }
    
    var fileLastOpenedDate: Date {
        return self.URL.fileLastOpenedDate;
    }

    var enSyncEnabled: Bool {
        return true;
    }
        
    func getParentsOfShelfItemTillRootParent() -> [FTGroupItemProtocol] {
        var parents: [FTGroupItemProtocol] = [FTGroupItemProtocol]()
        if let parent = self.parent {
            parents.append(parent)
            parents.append(contentsOf: parent.getParentsOfShelfItemTillRootParent())
        }
       return parents
   }

}

extension FTGroupItemProtocol
{
    func addChild(_ childItem : FTShelfItemProtocol)
    {
        self.childrens.append(childItem)
        childItem.parent = self
        childItem.shelfCollection = self.shelfCollection
        self.invalidateTop3Notebooks()
    }
    
    func removeChild(_ childItem : FTShelfItemProtocol)
    {
        let index = self.childrens.index { (eachItem) -> Bool in
            if(eachItem.URL == childItem.URL) {
                return true;
            }
            return false;
        }
        if(nil != index) {
            childItem.shelfCollection = nil
            self.childrens.remove(at: index!)
            self.invalidateTop3Notebooks()
        }
    }
    
    func invalidateTop3Notebooks() {
        (self as? FTGroupItem)?.clearTopMost3NoteBooks()
        if nil == self.parent {
            return
        }
        if let parent = self.parent {
            return parent.invalidateTop3Notebooks()
        }
    }    
}

extension FTShelfImage {
    var image : UIImage? {
        var thumbImage : UIImage?;
        do {
            var thumbnailInfoDict : AnyObject?;
            try (self.URL as NSURL).getPromisedItemResourceValue(&thumbnailInfoDict, forKey: URLResourceKey.thumbnailDictionaryKey);
            if(nil != thumbnailInfoDict) {
                thumbImage = (thumbnailInfoDict as! NSDictionary).object(forKey: URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey.rawValue) as? UIImage;
            }
        }
        catch {
            
        }
        return thumbImage;
    };
}

extension URL {
    func pathRelativeTo(_ inURL: URL) -> String {
        let url = inURL.urlByDeleteingPrivate().path;
        let selfURL = self.urlByDeleteingPrivate().path;
        
        let path = selfURL.replacingOccurrences(of: url, with: "").trimmingCharacters(in: CharacterSet(charactersIn: "/"));
        return path;
    }
}
