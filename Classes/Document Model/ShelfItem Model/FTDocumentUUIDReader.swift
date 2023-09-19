//
//  FTDocumentUUIDReader.swift
//  Noteshelf
//
//  Created by Amar on 16/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTDocumentUUIDReader: NSObject {
    static let shared = FTDocumentUUIDReader();
    private var operationQueue = OperationQueue();
        
    override init() {
        operationQueue.name = "com.fluidtouch.documentuuid.reader"
        operationQueue.maxConcurrentOperationCount = 3;
        operationQueue.qualityOfService = QualityOfService.background;
    }
    
    func readDocumentUUID(_ url: URL,onCompletion: @escaping ((String?) -> ()))
    {
        // Try to read from the URL extended attributes.
        if let uuid = url.getExtendedAttribute(for: .documentUUIDKey)?.stringValue {
            onCompletion(uuid)
            debugLog("Document UUID Found on URL")
            return
        } else {
            // Fallback to old approach
            debugLog("Document UUID Falling back to Plist approach")
            let operation = FTDocumentUUIDReaderOperation(url: url, onCompletion: onCompletion);
            operationQueue.addOperation(operation);
        }
    }
}

private class FTDocumentUUIDReaderOperation: Operation
{
    private var URL: URL;
    private var onCompletion: ((String?) -> ());
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

    required init(url: URL,onCompletion block: @escaping ((String?) -> ())) {
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
        var documentUUID: String?
        let metaURL = self.URL.appendingPathComponent("\(METADATA_FOLDER_NAME)/\(PROPERTIES_PLIST)");
        var error : NSError?;
        NSFileCoordinator.init().coordinate(readingItemAt: metaURL,
                                            options:.immediatelyAvailableMetadataOnly,
                                            error: &error,
                                            byAccessor:
            { (url) in
                if let dictionary = NSDictionary.init(contentsOf: url) {
                    documentUUID = dictionary[DOCUMENT_ID_KEY] as? String;
                }
                self.didCompleteTask(documentUUID);
        });
        if(nil != error) {
            self.didCompleteTask(documentUUID);
        }
    }
    
    private func didCompleteTask(_ uuid:String?) {
        onCompletion(uuid);
        self.taskExecuting = false;
    }
}
