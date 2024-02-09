//
//  FTBookSessionRootViewController.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 05/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon
#if targetEnvironment(macCatalyst)

class FTBookSessionRootViewController: UIViewController {
    private weak var launchScreenController: UIViewController?
    private(set) weak var notebookSplitController: FTNoteBookSplitViewController?
    
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
    
    func openNotebook(using docId: String, pageId: String) {
        FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: docId) { docItem in
            guard let shelfItem = docItem else {
                FTTextLinkRouteHelper.handeDocumentUnAvailablity(for: docId, on: self)
                return
            }
            if let splitVc = self.notebookSplitController, let docVc = splitVc.documentViewController, let doc = docVc.getCurrentDocument(), doc.documentUUID == docId {
                docVc.navigateToPage(with: pageId, documentId: doc.documentUUID)
            } else {
                FTDocumentPasswordValidate.validateShelfItem(shelfItem: shelfItem,
                                                             onviewController: self,
                                                             onCompletion:
                                                                { [weak self] pin, success,_ in
                    guard let self else { return }
                    self.openItemInNewWindow(shelfItem, pageIndex: nil, pageUUID: pageId, docPin: pin)
                })
            }
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
                let createWithAudio = userActivity.createWithAudio
                let isQuickCreate = userActivity.isQuickCreate
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { [weak self] token, docItem, error in
                    guard let self else { return }
                    if let _docitem = docItem, let doc = _docitem as? FTNoteshelfDocument {
                        var reqIndex: Int?
                        if let pageId = userActivity.userInfo?["pageUUID"] as? String {
                            if let index = doc.pages().firstIndex(where: {$0.uuid == pageId }) {
                                reqIndex = index
                                continueProcessDocumentOpen()
                            } else {
                                UIAlertController.showAlertForPageNotAvailableAndSuggestToFirstPage(from: self, notebookTitle: doc.documentName) { yes in
                                    if yes {
                                        continueProcessDocumentOpen()
                                    } else {
                                        self.killSession()
                                    }
                                }
                            }
                        } else {
                            continueProcessDocumentOpen()
                        }

                        func continueProcessDocumentOpen() {
                            let shouldInsertCover = doc.propertyInfoPlist()?.object(forKey: INSERTCOVER) as? Bool ?? false
                            if shouldInsertCover {
                                doc.insertCoverForPasswordProtectedBooks { success, error in
                                    doc.propertyInfoPlist()?.setObject(false, forKey: INSERTCOVER)
                                    processDocumentOpen()
                                }
                            } else {
                                processDocumentOpen()
                            }
                        }

                        func processDocumentOpen() {
                            let docInfo = FTDocumentOpenInfo(document: _docitem, shelfItem: shelfItem, index: reqIndex ?? -1);
                            docInfo.documentOpenToken = token;
                            docItem?.isJustCreatedWithQuickNote = isQuickCreate
                            self.showNotebookView(docInfo);
                            FTNoteshelfDocumentProvider.shared.addShelfItemToList(shelfItem, mode: .recent)
                            if createWithAudio {
                                self.notebookSplitController?.documentViewController?.startRecordingOnAudioNotebook()
                            }
                        }
                    }
                    else {
                        self.killSession()
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
#endif
