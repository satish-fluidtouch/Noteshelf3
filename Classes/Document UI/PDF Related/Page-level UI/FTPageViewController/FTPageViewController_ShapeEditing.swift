//
//  FTPageViewController_ShapeEditing.swift
//  Noteshelf
//
//  Created by Sameer on 19/01/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import MobileCoreServices

extension FTPageViewController {
    func performCutCommand(annotation: FTAnnotation) {
        self.copyShapeAnnotation(annotation: annotation)
        let hashKey = self.windowHash;
        annotation.setSelected(false, for: hashKey);
        self.removeAnnotations([annotation], refreshView: true);
    }
    
    func performDeleteCommand(annotation: FTAnnotation, shouldRefresh: Bool) {
        self.removeAnnotations([annotation], refreshView: true)
    }
    
    func copyShapeAnnotation(annotation: FTAnnotation) {
        // Get the General pasteboard.
        let pasteBoard = UIPasteboard.general;
        do {
            annotation.copyMode = true;
            let annotationData = try NSKeyedArchiver.archivedData(withRootObject: annotation, requiringSecureCoding: true);
            annotation.copyMode = false
            var pbInfo: [String: Any] = [String: Any]()
            pbInfo[UIPasteboard.pdfAnnotationUTI()] = annotationData
            pasteBoard.items = [pbInfo];
        }
        catch {
            FTCLSLog("Error - \(error.localizedDescription)")
        }
    }
}
