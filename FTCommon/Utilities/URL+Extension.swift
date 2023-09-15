//
//  File.swift
//  
//
//  Created by Narayana on 17/05/22.
//

import Foundation

public typealias ExtendedAttributeKey = FileAttributeKey

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

    func setExtendedAttribute(_ value: Data, for key: ExtendedAttributeKey) throws {
        do {
            var attributes = try FileManager.default.attributesOfItem(atPath: self.path)
            // fetch existing attributes and append
            var xAttributes = (attributes[.extendedAttributesKey] as? [AnyHashable: Any]) ?? [AnyHashable: Any]()
            xAttributes[key] = value

            attributes[.extendedAttributesKey] = xAttributes

            try FileManager.default.setAttributes(attributes, ofItemAtPath: self.path)
#if DEBUG
            print("✅  xAttr set for \(key.rawValue)")
#endif

        } catch {
#if DEBUG
            print("⚠️ Unable to set document UUID", error.localizedDescription)
#endif
            throw error
        }
    }

    func getExtendedAttribute(for key: ExtendedAttributeKey) -> String? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: self.path)
        if let xAttributes = attributes?[.extendedAttributesKey] as? [AnyHashable: Any],
           let data = xAttributes[key] as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        } else {
            return nil
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

public extension FileAttributeKey {
    //Reference: https://eclecticlight.co/2023/07/21/icloud-drive-changes-extended-attributes/
    //Root Key
    fileprivate static let extendedAttributesKey: FileAttributeKey = FileAttributeKey("NSFileExtendedAttributes")

    // sub keys
    static let documentUUIDKey: ExtendedAttributeKey = ExtendedAttributeKey("com.fluidtouch.document.uuid#S")
}
