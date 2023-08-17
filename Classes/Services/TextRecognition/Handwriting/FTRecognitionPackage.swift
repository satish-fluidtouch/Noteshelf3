//
//  FTRecognitionPackage.swift
//  Noteshelf
//
//  Created by Naidu on 02/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTRecognitionPackage: NSObject {
    private weak var editor: IINKEditor?
    private weak var engine: IINKEngine?
    private var partIdentifier: String = FTUtils.getUUID()
    convenience init(with editor: IINKEditor?, engine: IINKEngine?){
        self.init()
        self.editor = editor
        self.engine = engine
    }
    deinit {
        self.engine?.deletePackage(self.partIdentifier, error: nil)
        self.editor?.part = nil
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }

    func assignPartToEditor(){
        
        do{
            let package = try self.createPackage(withName: self.partIdentifier)
            if package?.partCount() ?? 0 > 0 {
                self.editor?.part = try package?.part(at: 0);
            }
        }
        catch{
            self.editor?.part = nil
            return
        }
    }
    
    private func createPackage(withName packageName: String) throws -> IINKContentPackage?
    {
        var resultPackage: IINKContentPackage?
        let fullPath = FileManager.default.pathForFileInDocumentDirectory(fileName: packageName) + ".iink"
        if let engine = self.engine {
            resultPackage = try engine.createPackage(fullPath.decomposedStringWithCanonicalMapping)
            // Add a blank page type Text Document
            if let part = try resultPackage?.createPart(with: "Text") /* Options are : "Diagram", "Drawing", "Math", "Text Document", "Text" */ {
                print(part.identifier)
            }
        }
        return resultPackage
    }
}
