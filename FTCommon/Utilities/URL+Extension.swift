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

    func documentUUID() -> String? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: self.path)
        if let existing = attributes?[.extendedAttributesKey] as? [AnyHashable: Any],
           let uuid = existing[FileAttributeKey.documentUUIDKey] as? Data,
           let docUUID = String(data: uuid, encoding: .utf8) {
            return docUUID
        } else {
            return nil
        }
    }

    func setDocumentUUID(_ uuid: String) {
        do {
            var attributes = try FileManager.default.attributesOfItem(atPath: self.path)
            if let uuid = uuid.data(using: .utf8) {
                if var xAttributes = attributes[.extendedAttributesKey] as? [AnyHashable: Any] {
                    xAttributes[FileAttributeKey.documentUUIDKey] = uuid
                    attributes[.extendedAttributesKey] = xAttributes
                } else {
                    attributes[.extendedAttributesKey] = [FileAttributeKey.documentUUIDKey: uuid]
                }
            }
            try FileManager.default.setAttributes(attributes, ofItemAtPath: self.path)
        } catch {
#if DEBUG
            print("⚠️ Unable to set document UUID", error.localizedDescription)
#endif
        }
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

private extension FileAttributeKey {
    //Reference: https://eclecticlight.co/2023/07/21/icloud-drive-changes-extended-attributes/
    static let extendedAttributesKey = FileAttributeKey("NSFileExtendedAttributes")
    static let documentUUIDKey = "com.fluidtouch.document.uuid#S"
}
