//
//  FTSearchProcessorProtocols.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 04/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTGlobalSearchType {
    case titles
    case tags
    case content
    case all
}

protocol FTSearchProcessor {
    func setDataToProcess(shelfCategories: [FTShelfItemCollection], shelfItems: [FTShelfItemProtocol])
    var progress: Progress {get set}
    @discardableResult func startProcessing() -> String
    func cancelSearching()
    
    var onSectionFinding: (([FTSearchSectionProtocol], String) -> Void)? {get set}
    var onCompletion : ((_ token: String) -> ())? {get set}
}

class FTGlobalSearchOperation : BlockOperation
{
    weak var document : FTDocumentProtocol?;
    var documentToken : FTDocumentOpenToken = FTDocumentOpenToken();
    private var _isFinished = false {
        didSet {
            didChangeValue(forKey: "isFinished");
        }
        willSet {
            willChangeValue(forKey: "isFinished");
        }
    }
    deinit {
        #if DEBUG
        debugPrint("deinit \(self.classForCoder)");
        #endif
    }
    
    override func start() {
        super.start();
    }
    
    override var isFinished: Bool {
        return _isFinished;
    }
    
    override var isAsynchronous: Bool {
        return true;
    }

    func taskCompleted() {
        if let doc = self.document {
            FTNoteshelfDocumentManager.shared.closeDocument(document: doc,
                                                            token: self.documentToken,
                                                            onCompletion: nil);
        }
        _isFinished = true;
    }

    override func cancel() {
        super.cancel();
        (self.document as? FTDocumentSearchProtocol)?.cancelSearchOperation(onCompletion: {[weak self] in
            self?.taskCompleted()
        });
    }
}
