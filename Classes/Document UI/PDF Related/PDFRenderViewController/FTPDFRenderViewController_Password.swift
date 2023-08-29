//
//  FTPDFRenderViewController_Password.swift
//  Noteshelf
//
//  Created by Akshay on 21/08/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

#if DEBUG
let backgroundLockTimeInterval = 10.0
#elseif BETA
let backgroundLockTimeInterval = 20.0
#else
let backgroundLockTimeInterval = 120.0
#endif

extension FTPDFRenderViewController {

    func canContinueToImportFiles() -> Bool {
        if goingToBackgroundAt == 0 || FTUserDefaults.isNotebookBackgroundLockEnabled() == false {
            return true
        } else {
            let interval = Date().timeIntervalSince1970
            let difference = fabs(interval-goingToBackgroundAt)
            if self.pdfDocument.isPinEnabled() && difference > backgroundLockTimeInterval {
                return false
            } else {
                return false
            }
        }
    }

    func showAlertAskingToEnterPwdToContinueOperation() {
        shouldShowPwdScreenOnBecomeActive = FTShowPWDStateAlert;
        showCannotImportFile {
            DispatchQueue.main.async { [weak self] in
                self?.askForPassword()
            }
        }
    }

    func avoidAskingPwd() {
        shouldShowPwdScreenOnBecomeActive = FTShowPWDStateNotNeeded;
    }

    func setPasswordStateNone() {
        shouldShowPwdScreenOnBecomeActive = FTShowPWDStateNone;
    }
}


extension FTPDFRenderViewController
{
    func didAddBlurEffect() -> Bool
    {
        if let presentedController = self.presentedViewController {
            if presentedController.modalPresentationStyle == .popover {
                presentedController.dismiss(animated: false, completion: nil)
            }
        }

        if(nil != self.blurWindow) {
            return false
        }

        let blurController = FTBlurViewController()
        blurController.view.backgroundColor = .clear
        let newWindow : UIWindow = UIWindow(frame: self.view.window?.bounds ?? UIScreen.main.bounds);
        if #available(iOS 13, *) {
            newWindow.windowScene = self.view.window?.windowScene
        }
        newWindow.rootViewController = blurController;
        newWindow.makeKeyAndVisible()
        self.blurWindow = newWindow;
        return true
    }

    @objc
    func removeBlurEffect(_ animated : Bool)
    {
        guard let blurWindow = self.blurWindow else {
            return;
        }

        if(animated) {
            UIView.animate(withDuration: 0.2, animations: {
                blurWindow.rootViewController?.view.alpha = 0;
            }) { [weak self] (_) in
                self?.removeBlurEffect(false);
            }
        }
        else {
            blurWindow.resignKey();
            self.blurWindow = nil;
            self.view.window?.makeKey();
        }
    }

    private func askForPassword() {
       
        isAskedForPassword = true
        
        guard let blurWindow = self.blurWindow else {
            return;
        }

        if blurWindow.rootViewController?.presentedViewController != nil {
            return;
        }
        if let presentedController = blurWindow.visibleViewController,
            presentedController.isKind(of: FTPinRequestViewController.self) {
            return
        }
        
        if let visibleController = blurWindow.rootViewController,
            let shelfItem = self.shelfItemManagedObject.documentItem as? FTShelfItemProtocol {
            FTDocumentPasswordValidate.validateShelfItem(shelfItem: shelfItem,
                                                         onviewController : visibleController)
            { [weak self] (_, success,_) in
                self?.setPasswordStateNone()
                self?.isAskedForPassword = false
                                                            
                if(success) {
                    self?.removeBlurEffect(true);
                }
                else {
                    self?.removeAnyPresentedController({
                        let backAction: FTNotebookBackAction = FTNormalAction
                        self?.back(toShelfButtonAction: backAction, with: shelfItem.title)
                    })
                }
            };
        }
    }

    private func removeAnyPresentedController(_ completion : @escaping () -> Void) {
        if let presentedController = self.presentedViewController as? UINavigationController {
            if (presentedController.viewControllers.first?.isKind(of: FTFinderViewController.self))!
                || (presentedController.viewControllers.first?.isKind(of: FTShelfItemsViewController.self))! {
                presentedController.dismiss(animated: false, completion: {
                    completion()
                })
            }
            else {
                completion()
            }
        } else {
            completion()
        }
    }

    func snapshotView(afterScreenUpdate : Bool) -> UIView? {
        var snapshotView : UIView?
        if let window = self.blurWindow {
            snapshotView = window.snapshotView(afterScreenUpdates: afterScreenUpdate)
            self.removeBlurEffect(false);
        }
        else if(self.view.window != nil) {
            let bgColor = self.view.backgroundColor;
            self.view.backgroundColor = nil;
            self.toolTypeContainerVc?.view.isHidden = true;
            snapshotView = self.view.snapshotView(afterScreenUpdates: afterScreenUpdate);
            self.toolTypeContainerVc?.view.isHidden = false;
            self.view.backgroundColor = bgColor;
        }
        else {
            if let keyWindo = UIApplication.shared.keyWindow,
                keyWindo.rootViewController is FTRootViewController,
                let presentedVC = keyWindo.visibleViewController {
                FTLogError("SNAPSHOT_ERROR", attributes: ["controller":presentedVC.description]);
            } else {
                FTLogError("SNAPSHOT_ERROR", attributes: ["controller":"Not availble"]);
            }
        }
        return snapshotView
    }

    @objc func waitForTheDocmentToBeOpened() {
        for eachController in self.visiblePageViewControllers() {
            eachController.writingView?.waitUntilComplete();
        }
    }
    
    @objc func didCompleteDocumentPresentation() {
        self.showZoomPanelIfNeeded();
    }
}

//MARK:- FTSceneBackgroundHandling
extension FTPDFRenderViewController: FTSceneBackgroundHandling,FTViewControllerSupportsScene {
    func configureSceneNotifications() {
        let object = self.sceneToObserve;
        self.currentSceneID = self.sceneID;
        FTDeviceAutoLockHelper.share.notebookWillConnectScene(self.sceneID);
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneWillEnterForeground(_:)),
                                               name: UIApplication.sceneWillEnterForeground,
                                               object: object)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidEnterBackground(_:)),
                                               name: UIApplication.sceneDidEnterBackground,
                                               object: object)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidBecomeActive(_:)),
                                               name: UIApplication.sceneDidBecomeActive,
                                               object: object)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneWillResignActive(_:)),
                                               name: UIApplication.sceneWillResignActive,
                                               object: object)
    }

    @objc func willDellocate() {
        if let currentSceneID {
            FTDeviceAutoLockHelper.share.notebookDidDisconnectScene(currentSceneID);
        }
    }
    
    func sceneWillEnterForeground(_ notification: Notification) {
        if let currentSceneID {
            FTDeviceAutoLockHelper.share.notebookWillEnterForeground(currentSceneID);
        }
        if(!self.canProceedSceneNotification(notification)) {
            return;
        }

        if FTUserDefaults.isNotebookBackgroundLockEnabled() {
            let interval = Date().timeIntervalSince1970
            let difference = fabs(interval-goingToBackgroundAt)
            if self.pdfDocument.isPinEnabled() && difference > backgroundLockTimeInterval {
                shouldShowPwdScreenOnBecomeActive = FTShowPWDStateShow;
            }
        }
    }

    func sceneDidEnterBackground(_ notification: Notification) {
        if let currentSceneID {
            FTDeviceAutoLockHelper.share.notebookDidEnterBackground(currentSceneID)
        }
        if(!self.canProceedSceneNotification(notification)) {
            return;
        }

        if FTUserDefaults.isNotebookBackgroundLockEnabled(),
            self.pdfDocument.isPinEnabled(),
            self.didAddBlurEffect() {
            goingToBackgroundAt = Date().timeIntervalSince1970
        }
    }

    func sceneDidBecomeActive(_ notification: Notification) {
        if(!self.canProceedSceneNotification(notification)) {
            return;
        }
        
        goingToBackgroundAt = 0;
        switch shouldShowPwdScreenOnBecomeActive {
        case FTShowPWDStateShow:
            if !isAskedForPassword {
                self.askForPassword()
            }
        case FTShowPWDStateNone:
            self.removeBlurEffect(true)
        default:
            break
        }
        
        if let thumbnailGenID = self.pdfDocument.thumbnailGenerator?.notificationObserverID {
            NotificationCenter.default.post(name: .resumeThumbnailGeneration(for: thumbnailGenID), object: nil)
        }
    }

    func sceneWillResignActive(_ notification: Notification) {
        if(!self.canProceedSceneNotification(notification)) {
            return;
        }

        self.pdfDocument.localMetadataCache?.saveMetadataCache();
        if let thumbnailGenID = self.pdfDocument.thumbnailGenerator?.notificationObserverID {
            NotificationCenter.default.post(name: .pauseThumbnailGeneration(for: thumbnailGenID), object: nil)
        }
    }
}

private extension FTPDFRenderViewController {
    var sceneID: String {
            if let scene = self.sceneToObserve as? UIWindowScene {
                return scene.session.persistentIdentifier;
            }
        return "NO_SCENE";
    }
}
