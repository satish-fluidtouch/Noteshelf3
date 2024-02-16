//
//  SceneDelegate.swift
//  FTMultiWindow
//
//  Created by Akshay on 11/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private extension UIScene {
    var clsLogTitle : String {
        var title = self.session.persistentIdentifier;
        if let sceneTitle = self.title,!sceneTitle.isEmpty {
            title = sceneTitle;
        }
        return title;
    }
    
    func logCLS(key : String) {
        FTCLSLog("--- Scene: \(key) :\(self.clsLogTitle) ---");
    }
}


class SceneDelegate: FTSceneDelegate {
//    var window: UIWindow?
    private var shortcutItemToProcess: UIApplicationShortcutItem?
//    private weak var observer: NSObjectProtocol?;

    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        #if !targetEnvironment(macCatalyst)
            if let shortcutItem = connectionOptions.shortcutItem  {
                print("Scene shortcutItem \(shortcutItem) \(self)")
                shortcutItemToProcess = shortcutItem
            }
        #endif
        super.scene(scene, willConnectTo: session, options: connectionOptions);
        let usrActivity : NSUserActivity;
        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity, shortcutItemToProcess == nil {
            usrActivity = userActivity;
        } else {
            usrActivity = NSUserActivity(activityType: "com.fluidtouch.noteshelf.default")
            usrActivity.userInfo = [AnyHashable:Any]()
        }
        
        #if DEBUG
        print("Scene willConnectTo UserActivity \(usrActivity.description)")
        #endif
        scene.logCLS(key: "willConnect");
        usrActivity.sortOrder = FTUserDefaults.sortOrder()
        window?.userActivity = usrActivity
        scene.userActivity = usrActivity
        
        #if targetEnvironment(macCatalyst)
        if let windowScene = scene as? UIWindowScene {
            windowScene.sizeRestrictions?.minimumSize = CGSize.init(width: 1080, height: 640)
            let restrictedSize = CGSizeScale(UIScreen.main.nativeBounds.size,2);
            windowScene.sizeRestrictions?.maximumSize = restrictedSize;
        }
        #endif
        window?.rootViewController?.userActivity = scene.userActivity
        if let windowScene = scene as? UIWindowScene {
            #if targetEnvironment(macCatalyst)
            windowScene.titlebar?.titleVisibility = .hidden
            #endif
        }
        let urlContext = connectionOptions.urlContexts;
        if !urlContext.isEmpty {
            self.scene(scene, openURLContexts: urlContext);
        }
        updateSessionCountInFabric()
    }
    
    override func sceneDidDisconnect(_ scene: UIScene) {
        super.sceneDidDisconnect(scene);
        scene.logCLS(key: "disconnect");
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        scene.logCLS(key: "become active");
        if let shortcutItem = shortcutItemToProcess, let handlingController = window?.rootViewController as? FTIntentHandlingProtocol {
            let handler = FTAppIntentHandler(with: handlingController)
            handler.handleShortcutItem(item: shortcutItem)
            shortcutItemToProcess = nil
        }
        FabricHelper.configure()
        self.performWidgetActionIfRequired()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        scene.logCLS(key: "resign active");
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        scene.logCLS(key: "enter foreground");
        FTiRateManager.checkForApplicationForegroundActions();
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        scene.logCLS(key: "enter background");
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if let handlingController = window?.rootViewController as? FTIntentHandlingProtocol {
            let handler = FTAppIntentHandler(with: handlingController)
            handler.handleShortcutItem(item: shortcutItem)
        }
    }
    
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }
    
    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
        #if DEBUG
        print(#function,userActivityType)
        #endif
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let userInfo =  userActivity.userInfo, let url = userInfo["url"] as? URL, let openInPlace = userInfo["openInPlace"] as? Bool  {
            let sourceApplication = userInfo["sourceApplication"] as? String
            let annotation = userInfo["annotation"]
            var options = FTURLOptions(sourceApplication: sourceApplication,
                                       annotation: annotation)
            if let handlingController = window?.rootViewController as? FTIntentHandlingProtocol {
                let handler = FTAppIntentHandler(with: handlingController)
                options.openInPlace = openInPlace;
                handler.open(url, options: options)
            }
        }
        if let handlingController = window?.rootViewController as? FTIntentHandlingProtocol {
            let handler = FTAppIntentHandler(with: handlingController)
            handler.continueUserActivity(userActivity)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else { return }
        var options = FTURLOptions(sourceApplication: context.options.sourceApplication,
                                   annotation: context.options.annotation)
        if let handlingController = window?.rootViewController as? FTIntentHandlingProtocol {
            let handler = FTAppIntentHandler(with: handlingController)
            options.openInPlace = context.options.openInPlace;
            handler.open(context.url, options: options)
        }
    }
    
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        #if DEBUG
        print(#function,userActivityType)
        #endif
    }
    
    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) {
        #if DEBUG
        print(#function,userActivity.userInfo?.description ?? "--")
        #endif
    }
    func performWidgetActionIfRequired() {
        if let widgetActionType = FTWidgetActionController.shared.actionToExecute {
            switch widgetActionType {
            case FTPinndedWidgetActionType.pen:
                alertForPen()
            case FTPinndedWidgetActionType.audio:
                alertForAudio()
            case FTPinndedWidgetActionType.openAI:
                alertForAI()
            case FTPinndedWidgetActionType.text:
                alertForText()
            default:
                if let intentHandler = self.window?.rootViewController as? FTIntentHandlingProtocol {
                    let handler = FTAppIntentHandler(with: intentHandler)
                    handler.handleWidgetAction(for: widgetActionType)
                }
            }
            FTWidgetActionController.shared.resetWidgetAction()
        }
    }
}

func updateSessionCountInFabric() {
    let openSessions = Int32(UIApplication.shared.openSessions.count)
    let connectedScenes = Int32(UIApplication.shared.connectedScenes.count)
    let sessionInfo = ["OpenSessions" : openSessions,
                       "ConnectedScenes":connectedScenes];
    FabricHelper.updateFabric(key: "Sessions", value: sessionInfo)
}

extension URL {
    func copyInPlaceURLToTemp(onCompletion : @escaping (URL?) -> ())
    {
        if(!self.startAccessingSecurityScopedResource()) {
            onCompletion(self);
        }
        else {
            var urlToOpen : URL?;
            var error : NSError?
            let coordinator = NSFileCoordinator.init(filePresenter: nil);
            coordinator.coordinate(readingItemAt: self,
                                   options: .withoutChanges,
                                   error: &error)
            { (readingURL) in
                let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(self.lastPathComponent);
                try? FileManager().removeItem(at: tempURL);
                do {
                    try FileManager().copyItem(at: readingURL, to: tempURL);
                    urlToOpen = tempURL;
                }
                catch {
                    urlToOpen = nil;
                    FTCLSLog("failed to read");
                }
                self.stopAccessingSecurityScopedResource()
                onCompletion(urlToOpen);
            }
            if(nil != error) {
                self.stopAccessingSecurityScopedResource()
                onCompletion(nil);
            }
        }
    }
}
extension SceneDelegate {
    func alertForPen() {
        self.showAlertForIntentWith(title: "Pen", message: "Initiates pen stuff")
    }
    func alertForAudio() {
        self.showAlertForIntentWith(title: "Audio", message: "Initiates audio stuff")
    }
    func alertForAI() {
        self.showAlertForIntentWith(title: "AI", message: "Initiates AI stuff")
    }
    func alertForText() {
        self.showAlertForIntentWith(title: "Text", message: "Initiates text stuff")
    }
    func showAlertForIntentWith(title: String, message: String) {
        if let handlingController = window?.rootViewController as? FTIntentHandlingProtocol {
            let handler = FTAppIntentHandler(with: handlingController)
            handler.showAlertForIntentWith(title: title, message: message)
        }
    }
}
