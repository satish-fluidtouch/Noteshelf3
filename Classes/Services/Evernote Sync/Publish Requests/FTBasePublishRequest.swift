//
//  FTBasePublishRequest.swift
//  Noteshelf
//
//  Created by Ramakrishna on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import CoreData

@objc protocol FTBasePublishRequestDelegate: AnyObject {
    @objc optional func didCompletePublishRequestWithError(request: FTBasePublishRequest?, error: Error?)
    @objc optional func didCompletePublishRequest(request: FTBasePublishRequest?, withIgnore ignoreEntry: FTENIgnoreEntry)
}

class FTBasePublishRequest: NSObject {
    weak var delegate: FTBasePublishRequestDelegate?
    
    init(object refObject: NSManagedObjectID?, delegate: FTBasePublishRequestDelegate?) {
        // subclass should override this method
    }
    
    func startRequest() {
        // subclass should override this method
    }
    
    func managedObjectContext() -> NSManagedObjectContext? {
        return FTENPublishManager.shared.managedObjectContext()
    }
    
    func commitDataChanges() {
        FTENPublishManager.shared.commitDataChanges()
    }
    
    func executeBlock(onPublishQueue block: @escaping () -> Void) {
        FTENPublishManager.shared.executeBlock(onPublishQueue: block)
    }
}
