//
//  URL_Attributes_Extension.swift
//  Noteshelf
//
//  Created by Amar on 18/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension URL {
    var title : String {
        return self.deletingPathExtension().lastPathComponent;
    }
    
    var fileModificationDate : Date {
        var date: Date?;
        do {
            date = try self.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate;
        }
        catch {
        }
        return date ?? self.fileCreationDate
    }
    
    var fileCreationDate : Date {
        var date: Date?;
        do {
            date = try self.resourceValues(forKeys: [.creationDateKey]).creationDate;
        }
        catch {
        }
        return date ?? Date()
    }
    
    var fileLastOpenedDate: Date {
        get {
            var date: Date?;
            do {
                date = try self.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate;
            }
            catch {
                
            }
            return date ?? fileModificationDate;
        }
    }
/*
    public func updateLastOpenedDate(_ date: Date) {
        DispatchQueue.global().async {
            let coordinator = NSFileCoordinator(filePresenter: nil);
            var error: NSError?;
            coordinator.coordinate(writingItemAt: self,
                                   options: .contentIndependentMetadataOnly,
                                   error: &error) { writingURL in
                do {
                    var inURL = writingURL;
                    var resourceValue = URLResourceValues();
                    resourceValue.contentAccessDate = date;
                    try inURL.setResourceValues(resourceValue);
                }
                catch {
                    
                }
            }
        }
    }
    
    public func readLastOpenedDate(_ completion : @escaping (Date)->()) {
        DispatchQueue.global().async {
            let coordinator = NSFileCoordinator(filePresenter: nil);
            var error: NSError?;
            coordinator.coordinate(readingItemAt: self,
                                   options: .immediatelyAvailableMetadataOnly,
                                   error: &error) { readingURL in
                let date = readingURL.fileLastOpenedDate;
                completion(date);
            }
            if nil != error {
                completion(self.fileCreationDate);
            }
        }
    }
*/
    public mutating func updateLastOpenedDate(_ date: Date) {
        do {
            var resourceValue = URLResourceValues();
            resourceValue.contentAccessDate = date;
            try self.setResourceValues(resourceValue);
            debugLog("😄 Successfully set \(date) for \(self.lastPathComponent)")

        } catch {
            debugLog("😄🥵 error setting \(date) for \(self.lastPathComponent)")
        }
    }
    
    public func readLastOpenedDate(_ completion : @escaping (Date)->()) {
        let date = self.fileLastOpenedDate;
        debugLog("😄 Read lastOpen \(date) for \(self.lastPathComponent)")
        completion(date);
    }
}
