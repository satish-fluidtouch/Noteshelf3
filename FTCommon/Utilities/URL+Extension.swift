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

    func setExtendedAttributes(attributes: [FileAttributeKey.ExtendedAttribute]) throws {
        do {
            var fileAttributes = try FileManager.default.attributesOfItem(atPath: self.path)
            // fetch existing attributes and append
            var xAttributes = fileAttributes.extendedAttributes ?? [AnyHashable: Any]()

            xAttributes.merge(attributes.asDictionary){ (_, new) in new }
            fileAttributes[.extendedAttributesKey] = xAttributes

            try FileManager.default.setAttributes(fileAttributes, ofItemAtPath: self.path)
#if DEBUG
            print("✅  xAttr set for \(attributes.map{$0.key.rawValue})")
#endif

        } catch {
#if DEBUG
            print("⚠️  xAttr failed to set for \(attributes.map{$0.key.rawValue})")
#endif
            throw error
        }
    }

    func getExtendedAttribute(for key: FileAttributeKey) -> FileAttributeKey.ExtendedAttribute? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: self.path)
        if let xAttributes = attributes?.extendedAttributes,
           let data = xAttributes[key] as? Data {
            return FileAttributeKey.ExtendedAttribute(key: key, data: data)
        } else {
            return nil
        }
    }
    func urlByDeleteingPrivate() -> URL
    {
        var fileItemURL = self.standardizedFileURL;
        let filePath = fileItemURL.path;
        let searchString = "/private";
        if(filePath.hasPrefix(searchString)) {
            let range = filePath.startIndex..<filePath.endIndex;

            fileItemURL = URL.init(fileURLWithPath: filePath.replacingOccurrences(of: searchString, with: "", options: String.CompareOptions.anchored, range: range));
        }
        return fileItemURL;
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

//Reference: https://eclecticlight.co/2023/07/21/icloud-drive-changes-extended-attributes/
//https://developer.apple.com/documentation/fileprovider/nsfileprovideritemprotocol/3074511-extendedattributes
public extension FileAttributeKey {
    struct ExtendedAttribute {
        public let key: FileAttributeKey
        public let data: Data

        public init(key: FileAttributeKey, data: Data) {
            if dataToKilobytes(data) > 32 {
// https://developer.apple.com/documentation/fileprovider/nsfileprovideritemprotocol/3074511-extendedattributes
                fatalError("ExtendedAttribute is more than permitted size")
            }
            self.key = key
            self.data = data
        }

        public init(key: FileAttributeKey, string: String) {
            guard let data = string.data(using: String.Encoding.utf8) else {
                fatalError("Inavlid String passed, unable to convert to data")
            }
            self.init(key: key, data: data)
        }

        public init(key: FileAttributeKey, date: Date) {
            guard let data = date.data else {
                fatalError("unable to convert to data")
            }
            self.init(key: key, data: data)
        }

        public var stringValue: String? {
            String(data: self.data, encoding: .utf8)
        }

        public var dateValue: Date? {
            return self.data.date
        }
    }
}

public extension FileAttributeKey {
    //Root Key
    fileprivate static let extendedAttributesKey: FileAttributeKey = FileAttributeKey("NSFileExtendedAttributes")

    // sub keys
    static let documentUUIDKey: ExtendedAttributeKey = ExtendedAttributeKey("ft.doc.id#S")
    static let lastOpenDateKey: ExtendedAttributeKey = ExtendedAttributeKey("ft.doc.lod#S")
}

extension Sequence where Self == [FileAttributeKey.ExtendedAttribute] {
    var asDictionary: [AnyHashable: Data] {
        var attributes = [AnyHashable: Data]()
        self.forEach { attr in
            attributes[attr.key] = attr.data
        }
        return attributes
    }
}

extension Sequence where Self == [FileAttributeKey: Any] {
    var extendedAttributes: [AnyHashable: Any]? {
        let xAttributes = self[.extendedAttributesKey] as? [AnyHashable: Any]
        return xAttributes
    }
}

func dataToKilobytes(_ data: Data) -> Double {
    return Double(data.count) / 1024.0
}

public extension Date {
    var data: Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try? encoder.encode(self)
        return data
    }
}

public extension Data {
    var date: Date? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let date = try? decoder.decode(Date.self, from: self)
        return date
    }
}
