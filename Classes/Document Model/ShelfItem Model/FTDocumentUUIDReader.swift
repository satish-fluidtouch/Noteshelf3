//
//  FTDocumentPropertiesReader.swift
//  Noteshelf
//
//  Created by Amar on 16/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTDocumentProperties: NSObject {
    var documentID: String?;
    var lastOpnedDate: Date?
}

class FTDocumentPropertiesReader: NSObject {
    static let USE_EXTENDED_ATTRIBUTE = false;
    private let USE_COORDINATED_RED = true;
    
    static let shared = FTDocumentPropertiesReader();
    private var operationQueue = OperationQueue();
        
    override init() {
        operationQueue.name = "com.fluidtouch.documentuuid.reader"
        operationQueue.maxConcurrentOperationCount = 3;
        operationQueue.qualityOfService = QualityOfService.background;
    }
    
    func readDocumentUUID(_ url: URL,onCompletion: @escaping ((FTDocumentProperties) -> ()))
    {
        guard FTDocumentPropertiesReader.USE_EXTENDED_ATTRIBUTE else {
            let operation = FTDocumentPropertiesReaderOperation(url: url, onCompletion: onCompletion);
            operationQueue.addOperation(operation);
            return;
        }
        // Try to read from the URL extended attributes.
        if !USE_COORDINATED_RED, let uuid = url.getExtendedAttribute(for: .documentUUIDKey)?.stringValue {
            let item = FTDocumentProperties();
            item.documentID = uuid;
            if let lastOpendate = url.getExtendedAttribute(for: .lastOpenDateKey)?.dateValue {
                item.lastOpnedDate = lastOpendate;
            }
            onCompletion(item)
            return
        } else {
            // Fallback to old approach
            let operation = FTDocumentPropertiesReaderOperation(url: url, onCompletion: onCompletion);
            operationQueue.addOperation(operation);
        }
    }
}

private class FTDocumentPropertiesReaderOperation: Operation
{
    private var URL: URL;
    private var onCompletion: ((FTDocumentProperties) -> ());
    var taskExecuting:Bool = false {
        willSet{
            if(self.taskExecuting != newValue) {
                self.willChangeValue(forKey: "isFinished");
            }
        }
        didSet {
            if(self.taskExecuting != oldValue) {
                self.didChangeValue(forKey: "isFinished");
            }
        }
    }

    required init(url: URL,onCompletion block: @escaping ((FTDocumentProperties) -> ())) {
        URL = url;
        onCompletion = block;
    }
    
    override var isConcurrent: Bool {
        return true;
    }
    
    override var isFinished: Bool {
        return !taskExecuting;
    }
    
    override func main() {
        self.taskExecuting = true;
        let docProperties = FTDocumentProperties();
        FTCLSLog("NFC - UUID reader: \(self.URL.title)");
//        let metaURL = self.URL.appendingPathComponent("\(METADATA_FOLDER_NAME)/\(PROPERTIES_PLIST)");
        var error : NSError?;
        NSFileCoordinator.init().coordinate(readingItemAt: self.URL
                                            ,options:.withoutChanges
                                            ,error: &error
                                            ,byAccessor: { (readingURL) in
            if FTDocumentPropertiesReader.USE_EXTENDED_ATTRIBUTE
                ,let docUUID = readingURL.getExtendedAttribute(for: .documentUUIDKey)?.stringValue {
                docProperties.documentID = docUUID
            }
            let metaURL = readingURL.appendingPathComponent("\(METADATA_FOLDER_NAME)/\(PROPERTIES_PLIST)");
            if let dictionary = NSDictionary(contentsOf: metaURL),
               let docUUID = dictionary[DOCUMENT_ID_KEY] as? String {
                if docProperties.documentID != docUUID {
                    // Storing document UUID for older notebooks, once it is retrieved.
//                    let uuidAttribute = FileAttributeKey.ExtendedAttribute(key: .documentUUIDKey,  string: docUUID)
//                    try? self.URL.setExtendedAttributes(attributes: [uuidAttribute])
//                    debugLog("fileModDate: docID mismatch: \(self.URL.title) curID: \(docProperties.documentID) newID: \(docUUID)")
                    docProperties.documentID = docUUID
                }
            }
            if FTDocumentPropertiesReader.USE_EXTENDED_ATTRIBUTE
                ,let lastOpenedDate = readingURL.getExtendedAttribute(for: .lastOpenDateKey)?.dateValue {
                docProperties.lastOpnedDate = lastOpenedDate;
            }
        });
        self.didCompleteTask(docProperties);
    }
    
    private func didCompleteTask(_ docProperties:FTDocumentProperties) {
        onCompletion(docProperties);
        self.taskExecuting = false;
    }
}
