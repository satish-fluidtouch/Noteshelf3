//
//  FTBookOpenSceneDelegate.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 28/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
class FTBookOpenSceneDelegate: FTSceneDelegate {
    private let shouldRestoreScene = true;
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity else {
            UIApplication.shared.requestSceneSessionDestruction(session, options: nil);
            return;
        }

        guard let windowScene = (scene as? UIWindowScene) else { return }
        let _window = UIWindow(windowScene: windowScene)
        self.window = _window;
        super.scene(scene, willConnectTo: session, options: connectionOptions);

        if let windowScene = scene as? UIWindowScene {
            windowScene.sizeRestrictions?.minimumSize = CGSize.init(width: 720, height: 640)
            let restrictedSize = CGSizeScale(UIScreen.main.nativeBounds.size,2);
            windowScene.sizeRestrictions?.maximumSize = restrictedSize;
        }
        if !shouldRestoreScene {
            scene.activationConditions.canActivateForTargetContentIdentifierPredicate = NSPredicate(value: false);
        }

        let rootController = FTBookSessionRootViewController();
        _window.rootViewController = rootController;
        
        rootController.userActivity = userActivity;
        window?.userActivity = userActivity
        scene.userActivity = userActivity
        windowScene.titlebar?.toolbar = FTNotebookToolbar(windowScene: windowScene);
        _window.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else { return }
        let url = context.url
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let documentId = queryItems.first(where: { $0.name == "documentId" })?.value,
              let pageId = queryItems.first(where: { $0.name == "pageId" })?.value else {
            self.openUrl(with: context)
            return
        }

        if let rootVc = self.window?.rootViewController as? FTBookSessionRootViewController {
            rootVc.openNotebook(using: documentId, pageId: pageId)
        }
    }
    
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        if shouldRestoreScene {
            return scene.userActivity;
        }
        return nil;
    }

    override func sceneDidDisconnect(_ scene: UIScene) {
        super.sceneDidDisconnect(scene);
        if !shouldRestoreScene {
            scene.userActivity?.invalidate();
        }
        debugLog("sceneDidDisconnect");
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        debugLog("sceneDidBecomeActive");
    }

    func sceneWillResignActive(_ scene: UIScene) {
        debugLog("sceneWillResignActive");
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        debugLog("sceneWillEnterForeground");
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        debugLog("sceneDidEnterBackground");
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        debugLog("userActivity: \(userActivity)");
    }
}

#endif
