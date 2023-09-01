//
//  File.swift
//  
//
//  Created by Narayana on 17/05/22.
//

import Foundation

public extension URL {
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

}

public extension URL {
    var isSuportedBookExtension: Bool {
        return [FTFileExtension.ns2, FTFileExtension.ns3].contains(self.pathExtension)
    }

    var isNS2Book: Bool {
        if self.pathExtension == FTFileExtension.ns2 {
            return true
        }
        return false
    }
}
