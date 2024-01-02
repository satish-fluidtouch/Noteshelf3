//
//  FTThumbnailableCollection.swift
//  Noteshelf
//
//  Created by Siva on 28/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTThumbnailableCollection: AnyObject {
    var fileURL: URL { get };
    var pin: String! {get set};
    func documentPages() -> [FTThumbnailable];
    func isPinEnabled() -> Bool;
    
    //MARK:- UpdatePage
    
    func saveDocument(completionHandler : ((Bool) -> Void)?);
    
    //MARK:- EditOperations
    func duplicatePages(_ pages : [FTThumbnailable],onCompletion : @escaping ([FTThumbnailable]?) -> Void) -> Progress;
    func deletePages(_ pages : [FTThumbnailable]);
    func movePages(_ page: [FTThumbnailable], toIndex index: Int);
    func movePages(_ pages : [FTThumbnailable],
                   toDocument : URL,
                   pin: String?,
                   onCompletion : @escaping (Error?) -> Void) -> Progress;
    
    func startRecognitionIfNeeded();
}
