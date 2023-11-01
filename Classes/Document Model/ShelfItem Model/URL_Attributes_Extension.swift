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
            return readLastOpenedDate() ?? fileModificationDate;
        }
    }

    public mutating func updateLastOpenedDate(_ date: Date) {
        let lastOpenAttribute = FileAttributeKey.ExtendedAttribute(key: .lastOpenDateKey, date: date)
        try? self.setExtendedAttributes(attributes: [lastOpenAttribute])
    }

    public func readLastOpenedDate() -> Date? {
        if let date = self.getExtendedAttribute(for: .lastOpenDateKey)?.dateValue {
            return date
        } else {
            let date = try? self.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate
            return date
        }
    }
}
