//
//  FTPDFRenderViewController+PageNavigation.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 28/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private let edgesPadding: CGFloat = 40.0
private let navigatorSize: CGFloat = 56.0
private let minimumRequiredPages: Int  = 1

extension FTPDFRenderViewController {
    @objc private func createPageNavigatorIfNeeded() {
        if let document = self.pdfDocument,
            document.pages().count >= minimumRequiredPages,
            let currentPageIndex = self.currentlyVisiblePage()?.pageIndex(),
            self.pageNavigatorController == nil
        {
            self.pageNavigatorController = FTQuickPageNavigatorViewController.controller(nib: "FTQuickPageNavigatorViewController", document: document, pageIndex: UInt(currentPageIndex))
            self.pageNavigatorController!.direction = (UserDefaults.standard.pageLayoutType == .horizontal ? .horizontal : .vertical)
            self.pageNavigatorController!.delegate = self
            self.pageNavigatorController!.view.alpha = 0.0
            self.view.addSubview(self.pageNavigatorController!.view)
            self.addChild(self.pageNavigatorController!)
            
            let targetView: UIView = self.pageNavigatorController!.view
            let insets = self.view.safeAreaInsets
            targetView.translatesAutoresizingMaskIntoConstraints = false
            
            if self.pageNavigatorController!.direction == .vertical {
                targetView.topAnchor.constraint(equalTo: self.view.topAnchor,
                                                    constant: edgesPadding).isActive = true
                targetView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor,
                                                     constant: UIDevice.current.isIpad() ? -14 : (insets.right - edgesPadding)).isActive = true
                targetView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,
                                                   constant: -(max(insets.bottom, edgesPadding))).isActive = true
                targetView.widthAnchor.constraint(equalToConstant: navigatorSize).isActive = true
            }
            else {
                targetView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,
                                                    constant: insets.left + edgesPadding).isActive = true
                targetView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor,
                                                     constant: insets.right - edgesPadding).isActive = true
                targetView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,
                                                   constant: -(max(insets.bottom, 20))).isActive = true
                targetView.heightAnchor.constraint(equalToConstant: navigatorSize).isActive = true
            }
        }
    }
    
    @objc func handlePageChange() {
        guard let currentPageIndex = self.currentlyVisiblePage()?.pageIndex() else {
            return;
        }

        if self.previousVisiblePageIndex >= 0, self.previousVisiblePageIndex != currentPageIndex {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(resetPageSwipingCounter), object: nil)
            
            self.previousVisiblePageIndex = currentPageIndex
            self.pageSwipingCounter += 1;
            if (self.pageSwipingCounter >= 2) {
                self.showPageNavigator()
                self.resetPageSwipingCounter()
            }
            else {
                self.perform(#selector(resetPageSwipingCounter), with: nil, afterDelay: 1.0)
            }
            self.pageNavigatorController?.setCurrentPageIndex(currentPageIndex)
        }
    }
    
    @objc func triggerPageChangeNotification() {
        var sessionID = ""
        if #available(iOS 13.0, *) {
            if let sessionIdentifier = self.view.window?.windowScene?.session.persistentIdentifier {
                sessionID = sessionIdentifier
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name.didChangeCurrentPageNotification, object: sessionID)
    }
    
    @objc private func resetPageSwipingCounter() {
        self.pageSwipingCounter = 0
    }
    
    @objc func showPageNavigator() {
        self.createPageNavigatorIfNeeded()
        FTQuickPageNavigatorViewController.showPageNavigator(onController: self)
    }
        
    @objc private func destroyPageNavigator() {
        self.pageNavigatorController?.view.removeFromSuperview()
        self.pageNavigatorController?.removeFromParent()
        self.pageNavigatorController = nil
    }
}

extension FTPDFRenderViewController: FTQuickPageNavigatorDelegate {
    
    func pageNavigator(showPage atIndex: UInt, controller: FTQuickPageNavigatorViewController) {
        self.showPage(at: Int(atIndex), forceReLayout: false, animate: false)
    }
            
    func pageNavigatorDidHide(_ controller: FTQuickPageNavigatorViewController?) {
        self.destroyPageNavigator()
    }
}
