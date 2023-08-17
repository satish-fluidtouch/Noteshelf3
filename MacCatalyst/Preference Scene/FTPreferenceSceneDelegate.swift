//
//  FTPreferenceSceneDelegate.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 07/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)

class FTPreferenceSceneDelegate: FTSceneDelegate {
    static let activityIdentifier = "FTPreferenceScene";
    
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        super.scene(scene, willConnectTo: session, options: connectionOptions);
        if let windowScene = scene as? UIWindowScene {
            let windowSize = CGSize(width: 540, height: 620);
            windowScene.sizeRestrictions?.minimumSize = windowSize
            windowScene.sizeRestrictions?.maximumSize = windowSize;
            windowScene.sizeRestrictions?.allowsFullScreen = false;
            windowScene.windowingBehaviors?.isMiniaturizable = false;
            windowScene.titlebar?.toolbarStyle = .unifiedCompact;
            windowScene.title = NSLocalizedString("Settings", comment: "Settings");
        }
        scene.activationConditions.canActivateForTargetContentIdentifierPredicate = NSPredicate(value: false);
    }
    
    override func sceneDidDisconnect(_ scene: UIScene) {
        super.sceneDidDisconnect(scene);
        scene.userActivity?.invalidate();
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        debugLog("\(Self.className()) sceneDidBecomeActive");
    }

    func sceneWillResignActive(_ scene: UIScene) {
        debugLog("\(Self.className()) sceneWillResignActive");
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        debugLog("\(Self.className()) sceneWillEnterForeground");
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        debugLog("\(Self.className()) sceneDidEnterBackground");
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        debugLog("\(Self.className()) userActivity: \(userActivity)");
    }
}
#endif
