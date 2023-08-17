//
//  FTUniqueNameProtocol.swift
//  Noteshelf
//
//  Created by Amar on 11/7/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTUniqueNameProtocol: NSObjectProtocol {

    func uniqueFileName(_ documentName: String, inItems items: [FTDiskItemProtocol]) -> String;
    func uniqueName(name: String, inGroup: FTGroupItemProtocol?, onCompletion : @escaping (String) -> Void);
}

extension FTUniqueNameProtocol {

    func uniqueName(name: String, inGroup: FTGroupItemProtocol?, onCompletion : @escaping (String) -> Void) {

    }

    func uniqueFileName(_ documentName: String, inItems items: [FTDiskItemProtocol]) -> String {
        var fileCount = 0;
        var newDocName: String? = nil;

        let validDocName = documentName.validateFileName() as NSString;
        let fileExtension = validDocName.pathExtension;
        let fileName = validDocName.deletingPathExtension;

        var nameExists = true;
        while (nameExists) {
          if(fileCount == 0) {
            newDocName = "\(fileName).\(fileExtension)";
          } else {
            newDocName = "\(fileName) \(fileCount).\(fileExtension)";
          }

          nameExists = self.fileExitsWith(newDocName!, inItems: items);
          if(nameExists == false) {
            break;
          } else {
            fileCount += 1;
          }
        }
        return newDocName!;
      }

    fileprivate func fileExitsWith(_ name: String, inItems items: [FTDiskItemProtocol]) -> Bool {

        var fileExists = false;
        for eachItem in items where eachItem.URL.lastPathComponent == name {
                fileExists = true;
                break;
        }
        return fileExists;
    }
}
