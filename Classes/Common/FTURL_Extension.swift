//
//  FTURL_Extension.swift
//  Noteshelf
//
//  Created by Amar on 25/10/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon
import UIKit

extension URL
{
    func thumbnailCacheHash() -> Int {
        return self.relativePathWRTCollection().hash
    }
    
    func relativePathWRTCollection() -> String
    {
        let original = self
        var urlComponents = original.pathComponents;
        var relativePaths = [String]();

        var eachComponent = urlComponents.last;
        while let lastComp = eachComponent, !lastComp.hasSuffix(shelfExtension)  {
            relativePaths.insert(eachComponent!, at: 0);
            urlComponents.removeLast();
            eachComponent = urlComponents.last;
        }
        if let comp = eachComponent {
            relativePaths.insert(comp, at: 0);
        }
        let returnPath = relativePaths.joined(separator: "/");
        return returnPath;
    }

    func relativePathWithOutExtension() -> String
    {
        let original = self
        var urlComponents = original.pathComponents;
        var relativePaths = [String]();
        
        var eachComponent = urlComponents.last;
        while let lastComp = eachComponent, !lastComp.hasSuffix(shelfExtension)  {
            relativePaths.insert(eachComponent!.deletingPathExtension, at: 0);
            urlComponents.removeLast();
            eachComponent = urlComponents.last;
        }
        relativePaths.insert(eachComponent!.deletingPathExtension, at: 0);
        let returnPath = relativePaths.joined(separator: "/");
        return returnPath;
    }
    
    func displayRelativePathWRTCollection() -> String {
        var urlComponents = self.pathComponents;
        var relativePaths = [String]();

        var eachComponent = urlComponents.last;
        while let lastComp = eachComponent, !lastComp.hasSuffix(shelfExtension) {
            let comp = lastComp.deletingPathExtension;
            relativePaths.insert(comp, at: 0);
            urlComponents.removeLast();
            eachComponent = urlComponents.last;
        }
        if let lastComp = eachComponent {
            let comp = lastComp.deletingPathExtension;
            relativePaths.insert(comp, at: 0);
        }
        let returnPath = relativePaths.joined(separator: "/");
        return returnPath;
    }

    func collectionURL() -> URL?
    {
        var newURl = self
        while newURl.lastPathComponent != "..", newURl.pathExtension != shelfExtension {
            newURl = newURl.deletingLastPathComponent();
        }
        if(newURl.lastPathComponent == ".."){
            return nil;
        }
        return newURl;
    }
}
