//
//  FTCollectionName_Utils.swift
//  Noteshelf
//
//  Created by Amar on 25/10/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

extension String
{
    var pathExtension: String {
        return (self as NSString).pathExtension;
    }
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent;
    }
    
    var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension;
    }
    
    var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent;
    }

    func collectionName() -> String?
    {
        var collectionName : String?;
        let paths = self.components(separatedBy: "/")
        for eachItem in paths {
            if eachItem.pathExtension.lowercased() == FTFileExtension.shelf {
                collectionName = eachItem;
                break;
            }
        }
        return collectionName;
    }
        
    func relativeGroupPathFromCollection() -> String? {
        var groupPath = [String]();
        
        let paths = self.components(separatedBy: "/")
        for eachItem in paths
        {
            if eachItem.pathExtension.lowercased() == FTFileExtension.group {
                groupPath.append(eachItem);
            }
        }
        return groupPath.isEmpty ? nil : groupPath.joined(separator: "/");
    }
    
    func documentName() -> String
    {
        let paths = self.components(separatedBy: "/");
        return paths.last!;
    }
}
