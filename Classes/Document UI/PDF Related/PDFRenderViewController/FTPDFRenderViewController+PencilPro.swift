//
//  FTPDFRenderViewController+PencilPro.swift
//  Noteshelf3
//
//  Created by Narayana on 31/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTPDFRenderViewController {
    @objc func showPencilProMenu(using anchorPoint: CGPoint = CGPoint(x: 160, y: 160)) {
        if let proMenu = UIStoryboard(name: "FTDocumentView", bundle: nil).instantiateViewController(withIdentifier: "FTPencilProMenuController") as? FTPencilProMenuController {
            proMenu.delegate = self
            self.add(proMenu, frame: CGRect(origin: anchorPoint, size: CGSize(width: 320, height: 400)))
        }
    }
}

extension FTPDFRenderViewController: FTPencilProMenuDelegate {
    func canPerformUndo() -> Bool {
        return self.canUndo()
    }
    
    func performUndo() {
        self.undoButtonAction()
    }
    
    func canPerformRedo() -> Bool {
        return self.canRedo()
    }
    
    func performRedo() {
        self.redoButtonAction()
    }
}
