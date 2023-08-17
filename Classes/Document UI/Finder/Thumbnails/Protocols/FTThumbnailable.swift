//
//  FTThumbnailable.swift
//  Noteshelf
//
//  Created by Siva on 09/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTThumbnailable: AnyObject {
    //MARK:- Properties
    var uuid: String {get};
    var isBookmarked: Bool {get set};
    var bookmarkTitle: String! {get set};
    var bookmarkColor: String! {get set};
    var pdfPageRect : CGRect { get };
    
    //MARK:- Methods
    func pageIndex() -> Int;
    func thumbnail() -> FTPageThumbnailProtocol?;
    func tags() -> [String];
    func rotate()
}
