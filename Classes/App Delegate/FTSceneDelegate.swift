//
//  FTSceneDelegate.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 07/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSceneDelegate: UIResponder,UIWindowSceneDelegate {
    var window: UIWindow?
    private weak var observer: NSObjectProtocol?;

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        self.configureTheme();
        self.navigationbarAppearance()
        debugLog("\(#file) : \(#function) : \(#line)");
#if targetEnvironment(macCatalyst)
        self.window?.windowScene?.titlebar?.separatorStyle = .none;
#endif
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        removeThemeObserver();
        debugLog("\(#file) : \(#function) : \(#line)");
    }
    
    func openUrl(with context: UIOpenURLContext) {
        #if targetEnvironment(macCatalyst)
        let session = UIApplication.shared.shelfSceen();
        if let userActivity = session?.scene?.userActivity {
            var userInfo = userActivity.userInfo ?? [AnyHashable : Any]();
            userInfo["url"] = context.url
            userInfo["annotation"] = context.options.annotation
            userInfo["sourceApplication"] = context.options.sourceApplication
            userInfo["openInPlace"] = context.options.openInPlace
            userActivity.userInfo = userInfo
            UIApplication.shared.requestSceneSessionActivation(session, userActivity: userActivity, options: nil);
        }
        #endif
    }
}

private extension FTSceneDelegate {
    func configureTheme() {
        applyTheme();
        addThemeObserver();
    }
    
    func addThemeObserver() {
        observer = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "ThemeChange"), object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.applyTheme();
        }
    }
    
    func removeThemeObserver() {
        if let ob = observer {
            NotificationCenter.default.removeObserver(ob, name: Notification.Name(rawValue: "ThemeChange"), object: nil)
        }
    }

    func applyTheme() {
        let option = UserDefaults.standard.shelfTheme;
        if option == .Light {
            self.window?.overrideUserInterfaceStyle = .light;
        }
        else if option == .Dark {
            self.window?.overrideUserInterfaceStyle = .dark;
        }
        else {
            self.window?.overrideUserInterfaceStyle = .unspecified;
        }
    }
}

extension FTSceneDelegate {
    private func navigationbarAppearance() {
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20)]
        UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 32), .foregroundColor: UIColor.appColor(.black1)]
        UINavigationBar.appearance().tintColor = UIColor.appColor(.accent)
    }
}
