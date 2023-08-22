//
//  FTBookSessionRootViewController.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 05/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTBookSessionRootViewController: UIViewController {
    private weak var launchScreenController: UIViewController?
    private weak var notebookSplitController: FTNoteBookSplitViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.addLaunchScreen();
        self.loadNotebookShelfIten();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        if let scene = self.view.window?.windowScene {
            NotificationCenter.default.addObserver(self, selector: #selector(sceneDidDisconnect(_:)), name: UIScene.didDisconnectNotification, object: scene)
        }
    }
    
    @objc private func sceneDidDisconnect(_ scene: NSNotification) {
        if let sceneToObserve = scene.object as? UIScene {
            sceneToObserve.userActivity?.invalidate();
        }
        self.notebookSplitController?.documentViewController?.saveApplicationStateByClosingDocument(true, keepEditingOn: false, onCompletion: nil);
    }
}

private extension FTBookSessionRootViewController {
    func killSession() {
        if let scene = self.view.window?.windowScene?.session {
            UIApplication.shared.requestSceneSessionDestruction(scene, options: nil) { error in
                debugPrint("error");
            };
        }
    }
}

//MARK:- Launch Screen -
private extension FTBookSessionRootViewController {
    private func addLaunchScreen() {
        let launchInstanceStoryboard = UIStoryboard(name: "Launch Screen", bundle: nil);
        if let viewController = launchInstanceStoryboard.instantiateInitialViewController() {
            self.addChild(viewController);
            self.view.addSubview(viewController.view);
            viewController.view.addEqualConstraintsToView(toView: self.view);
            self.launchScreenController = viewController;
            if let activityView = viewController.view.viewWithTag(120) as? UIActivityIndicatorView {
                activityView.isHidden = false;
                activityView.startAnimating();
            }
        }
    }
    
    private func removeLaunchScreen() {
        if let launchScreen = self.launchScreenController {
            launchScreen.view.removeFromSuperview();
            launchScreen.removeFromParent();
        }
    }
}


private extension FTBookSessionRootViewController {
    func loadNotebookShelfIten() {
        if let userActivity = self.userActivity
            , userActivity.activityType == FTNoteshelfSessionID.openNotebook.activityIdentifier
            ,let docPath = userActivity.lastOpenedDocument {
            FTNoteshelfDocumentProvider.shared.getShelfItemDetails(relativePath: docPath) { [weak self] (collection, groupNotebookView, item) in
                guard let shelfItem = item else {
                    self?.killSession();
                    return;
                }
                let request = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .write);
                if let pin = userActivity.userInfo?["docPin"] as? String {
                    request.pin = pin;
                }
                let createWithAudio = userActivity.userInfo?["createWithAudio"] as? Bool ?? false
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { [weak self] token, docItem, error in
                    if let _docitem = docItem {
                        let docInfo = FTDocumentOpenInfo(document: _docitem, shelfItem: shelfItem);
                        docInfo.documentOpenToken = token;
                        self?.showNotebookView(docInfo);
                        if createWithAudio {
                            self?.notebookSplitController?.documentViewController?.startRecordingOnAudioNotebook()
                        }
                    }
                    else {
                        self?.killSession();
                    }
                }
            }
        }
        else {
            runInMainThread {
                self.killSession();
            }
        }
    }
    
    func showNotebookView(_ docInfo: FTDocumentOpenInfo) {
        let controller = FTNoteBookSplitViewController.viewController(docInfo,
                                                                      bounds: self.view.bounds,
                                                                      delegate: self);
        controller.view.frame = self.view.bounds;
        self.view.addSubview(controller.view)
        self.add(controller);
        controller.view.addEqualConstraintsToView(toView: self.view,safeAreaLayout: true);
        controller.didMove(toParent: self)
        
        controller.view.layoutIfNeeded();
        controller.documentViewController?.didMove(toParent: controller)
        
        self.notebookSplitController = controller;
    }
}

extension FTBookSessionRootViewController: FTOpenCloseDocumentProtocol {
    func openRecentItem(shelfItemManagedObject: FTDocumentItemWrapperObject, addToRecent: Bool) {
        
    }
    
    func closeDocument(shelfItemManagedObject:FTDocumentItemWrapperObject, animate: Bool, onCompletion : (() -> Void)?) {
        killSession();
    }
}
