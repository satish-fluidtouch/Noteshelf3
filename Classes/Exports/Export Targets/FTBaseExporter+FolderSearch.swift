//
//  FTBaseExporter+FolderSearch.swift
//  Noteshelf
//
//  Created by Siva on 25/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTExporterProtocol {
    //MARK:- FolderCheck
    func checkIfFolderExists(withFolderPath folder: String!, andCompletionHandler completionHandler:@escaping  FolderCheckCompletionHandler);
    //MARK:- FolderSearch
    func fetchFolderObject(withCompletionHandler completionHandler: @escaping FolderSearchCompletionHandler);
}

extension FTExporterProtocol
{
    //MARK:- FolderCheck
    func checkIfFolderExists(withFolderPath folder: String!, andCompletionHandler completionHandler :@escaping  FolderCheckCompletionHandler) {
        
    }
    //MARK:- FolderSearch
    func fetchFolderObject(withCompletionHandler completionHandler: @escaping FolderSearchCompletionHandler) {
        //Subclasses must override
    }
}
