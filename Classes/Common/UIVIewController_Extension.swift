//
//  UIVIewController_Extension.swift
//  Noteshelf
//
//  Created by Amar on 9/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension UIScene.ActivationState {
    var appState : UIApplication.State {
        var state = UIApplication.shared.applicationState;
        switch self {
        case .foregroundActive:
            state = .active;
        case .foregroundInactive:
            state = .inactive;
        case .background,.unattached:
            state = .background;
        }
        return state;
    }
}

protocol FTViewControllerSupportsScene : NSObjectProtocol {
    var addedObserverOnScene : Bool { get set };
    func canProceedSceneNotification(_ notification: Notification) -> Bool
}

extension FTViewControllerSupportsScene where Self: UIViewController
{
    func canProceedSceneNotification(_ notification: Notification) -> Bool
    {
        if #available(iOS 13.0, *) {
            if(self.addedObserverOnScene) {
                return true;
            }
            return notification.isSameScene(self.sceneToObserve as? UIWindowScene);
        }
        return true;
    }
}

extension UIViewController {
    
    @objc var shouldAvoidDismissOnSizeChange : Bool {
        return false;
    }
    
    @objc func applicationState() -> UIApplication.State
    {
        return self.view.applicationState();
    }
    
    func setWindowTitle(_ title:String?) {
        self.view.window?.windowScene?.title = title
    }
    
    var sceneToObserve : Any? {
        if #available(iOS 13.0, *) {
            if let windowScene = self.view.window?.windowScene {
                (self as? FTViewControllerSupportsScene)?.addedObserverOnScene = true;
                return windowScene;
            }
            var attrs = ["OS" : UIDevice.current.systemName,
                         "Build" : ProcessInfo.processInfo.operatingSystemVersionString];
            if(self.view.window == nil) {
                attrs = ["Window" : "Nil"];
            }
            FTLogError("WindowScene Not Available", attributes: attrs);
            #if DEBUG
            fatalError("view should be added to window before calling this");
            #endif
        }
        return nil;
    }
    
    func addConstraintForView(_ view:UIView, withrespectTo toView:UIView) {
        let widthConstraint = NSLayoutConstraint(item: view,
                                                 attribute: NSLayoutConstraint.Attribute.width,
                                                 relatedBy: NSLayoutConstraint.Relation.equal,
                                                 toItem: toView,
                                                 attribute: NSLayoutConstraint.Attribute.width,
                                                 multiplier: 1,
                                                 constant: 0);
        
        let heightConstraint = NSLayoutConstraint(item: view,
                                                  attribute: NSLayoutConstraint.Attribute.height,
                                                  relatedBy: NSLayoutConstraint.Relation.equal,
                                                  toItem: toView,
                                                  attribute: NSLayoutConstraint.Attribute.height,
                                                  multiplier: 1,
                                                  constant: 0);
        
        let centerXConstraint = NSLayoutConstraint(item: view,
                                                   attribute: NSLayoutConstraint.Attribute.centerX,
                                                   relatedBy: NSLayoutConstraint.Relation.equal,
                                                   toItem: toView,
                                                   attribute: NSLayoutConstraint.Attribute.centerX,
                                                   multiplier: 1,
                                                   constant: 0);
        
        let centerYConstraint = NSLayoutConstraint(item: view,
                                                   attribute: NSLayoutConstraint.Attribute.centerY,
                                                   relatedBy: NSLayoutConstraint.Relation.equal,
                                                   toItem: toView,
                                                   attribute: NSLayoutConstraint.Attribute.centerY,
                                                   multiplier: 1,
                                                   constant: 0);
        
        NSLayoutConstraint.activate([widthConstraint, heightConstraint, centerXConstraint, centerYConstraint]);
        
    }
    func containsLoadingActivity() -> Bool {
        let index = self.children.firstIndex(where: { (controller) -> Bool in
            return controller is FTLoadingIndicatorViewController
        })
        return (index != nil)
    }
    var isInLandscape: Bool {
        if let window = self.view.window {
            if window.ftStatusBarOrientation.isLandscape {
                return true
            } else {
                return false
            }
        }
        return false
    }
    
    @objc func refreshStatusBarAppearnce() {
        self.setNeedsStatusBarAppearanceUpdate();
        self.setNeedsUpdateOfHomeIndicatorAutoHidden();
    }
}

extension UIView {
    @objc func applicationState() -> UIApplication.State
    {
        if #available(iOS 13.0, *) {
            if let windoScene = self.window?.windowScene {
                return windoScene.activationState.appState;
            }
        }
        return UIApplication.shared.applicationState;
    }
    
    @objc func isRegularTrait() -> Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            return self.traitCollection.isRegular;
        #endif
    }
    
    func addEqualConstraintsToReferenceView(toView:UIView) -> [NSLayoutConstraint] {
        let attributes: [NSLayoutConstraint.Attribute] = [.width,.height,.centerX,.centerY];
        var constraints = [NSLayoutConstraint]();
        attributes.forEach { (eachAttribute) in
            let constraint = NSLayoutConstraint(item: self,
                                                attribute: eachAttribute,
                                                relatedBy: .equal,
                                                toItem: toView,
                                                attribute: eachAttribute,
                                                multiplier: 1,
                                                constant: 0);
            constraints.append(constraint);
        }
        return constraints;
    }
}

//Common UI Presentation methods from different areas are being added here for convenience.
extension UIViewController {
   
    //MARK:- Backup
    func showActiveBackupPage() {
        let storyboard = UIStoryboard(name: "FTSettings_Accounts", bundle: nil);
        if let accountsController = storyboard.instantiateViewController(withIdentifier: FTAccountsViewController.className) as? FTAccountsViewController  {
            let navController = UINavigationController(rootViewController: accountsController)
            navController.modalPresentationStyle = .formSheet
            self.present(navController, animated: true, completion: nil)
        }
    }

    func showCloudLoginPage() {
        let storyboard = UIStoryboard(name: "FTSettings_Accounts", bundle: nil);
        if let backUpOptionsVc = storyboard.instantiateViewController(withIdentifier: FTBackupOptionsViewController.className) as? FTBackupOptionsViewController  {
            backUpOptionsVc.shouldDismissAfterLogin = true
            backUpOptionsVc.hideDoneButton = false
            backUpOptionsVc.hideBackButton = true
            let navController = UINavigationController(rootViewController: backUpOptionsVc)
            navController.modalPresentationStyle = .formSheet
            self.present(navController, animated: true, completion: nil)
        }
    }

    func noteBookSplitViewController() -> FTNoteBookSplitViewController? {
        return self.splitViewController as? FTNoteBookSplitViewController
    }
}

extension Notification {
    /// Check whether the notfication is posted on the same window(session) or not.
    /// - Parameter window: Checks for both iOS 12 and 13 using `window` and `windowScene` respectively.
    /// - Important: If you pass `nil` for the window, this will always return true. In future refactors, remove this method by passing `window` as an object in `Notification` observation.
    func isSameSceneWindow(for window:UIWindow?) -> Bool {
        guard let _window = window else { return false }
        if _window == self.object as? UIWindow {
            return true
        } else {
            return false
        }
    }
    
    func isSameScene(_ scene : UIWindowScene?) -> Bool {
        if let windowScene = scene,
            let notObject = self.object as? UIScene,
            windowScene == notObject {
            return true;
        }
        return false;
    }
}

extension UIWindow {
    func isInBackgroundState() -> Bool {
        var isInbackground = false
        if let scene = self.windowScene  {
            if (scene.activationState == .unattached || scene.activationState ==  .background) {
                isInbackground = true
            }
        } else {
            isInbackground = true
        }
        return isInbackground
    }
}

extension UIApplication {

    static var sceneWillEnterForeground : Notification.Name {
        if #available(iOS 13.0, *) {
            return UIScene.willEnterForegroundNotification
        } else {
            return UIApplication.willEnterForegroundNotification
        }
    }

    static var sceneDidEnterBackground : Notification.Name {
        if #available(iOS 13.0, *) {
            return UIScene.didEnterBackgroundNotification
        } else {
            return UIApplication.didEnterBackgroundNotification
        }
    }

    static var sceneDidBecomeActive : Notification.Name {
         if #available(iOS 13.0, *) {
             return UIScene.didActivateNotification
         } else {
             return UIApplication.didBecomeActiveNotification
         }
     }

    static var sceneWillResignActive : Notification.Name {
         if #available(iOS 13.0, *) {
             return UIScene.willDeactivateNotification
         } else {
             return UIApplication.willResignActiveNotification
         }
     }

    static var releaseOnScreenRendererIfNeeded : Notification.Name {
        return Notification.Name(rawValue: "releaseOnScreenRendererIfNeeded")
    }
    
    static var releaseRecognitionHelperNotification : Notification.Name {
        return Notification.Name(rawValue: "releaseRecognitionHelperNotification")
    }
    static var releaseVisionRecognitionHelperNotification : Notification.Name {
        return Notification.Name(rawValue: "releaseVisionRecognitionHelperNotification")
    }
}

@objc protocol FTSceneBackgroundHandling where Self: UIViewController {
    func configureSceneNotifications()

    @objc optional func sceneWillEnterForeground(_ notification:Notification)
    @objc optional func sceneDidEnterBackground(_ notification:Notification)
    
    @objc optional func sceneDidBecomeActive(_ notification:Notification)
    @objc optional func sceneWillResignActive(_ notification:Notification)
}



extension UIScreen {
    func getWidth() -> CGFloat {
        let value = UIScreen.main.nativeBounds.width/UIScreen.main.nativeScale
        return  value
    }
}

func rootViewSafeAreaInsets() -> UIEdgeInsets {
    if let keyWindow = UIApplication.shared.keyWindow?.rootViewController?.view {
        return keyWindow.safeAreaInsets
    }
    return UIEdgeInsets.zero
}
