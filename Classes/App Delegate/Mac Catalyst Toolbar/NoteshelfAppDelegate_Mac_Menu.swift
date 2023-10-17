//
//  NoteshelfAppDelegate_Mac_Menu.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 07/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
extension NoteshelfAppDelegate
{
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        var canPerform = super.canPerformAction(action, withSender: sender)
        if(action == #selector(showHelp(_:))) {
            canPerform = true;
        }
        else if(action == #selector(orderFrontPreferencesPanel(_:))) {
            canPerform = true;
        }
        else if(action == #selector(FTMenuActionResponder.showShelfScreen(_:))) {
            canPerform = true;
            #if DEBUG
            debugPrint("App del \(action) canPerform:\(canPerform)");
            #endif
        }
        return canPerform;
    }
    
    @objc func showHelp(_ sender : Any?)
    {
        FTHelpMenuAction.showHelp(sender);
    }
    
    @objc func orderFrontPreferencesPanel(_ sender : Any?)
    {
        debugLog("show preference panel");
        let session = UIApplication.shared.preferenceScene();
        var activity = NSUserActivity(activityType: FTPreferenceSceneDelegate.activityIdentifier);
        if let _sessionActivity = session?.scene?.userActivity {
            activity = _sessionActivity;
        }        
        UIApplication.shared.requestSceneSessionActivation(session, userActivity: activity, options: nil);
        //Do nothing
        //Just to override default behavior of showing mac app preferences window
    }
    
    @objc func showShelfScreen(_ sender: Any?) {
        let session = UIApplication.shared.shelfSceen();
        UIApplication.shared.requestSceneSessionActivation(session, userActivity: session?.scene?.userActivity, options: nil);
    }
}

class FTHelpMenuAction : NSObject
{
    class func showHelp(_ sender : Any?)
    {
        if let helpURL = URL(string: "http://support.noteshelf.net/article-categories/noteshelf-on-mac/") {
            UIApplication.shared.open(helpURL,
                                      options: [:],
                                      completionHandler: nil);
        }
    }
}

extension NoteshelfAppDelegate {
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder);
        if builder.system == .main {
            FTMenuController.buildAppMenu(builder: builder);
        }
    }
    // You are requested to update the state of a given command from a menu; Here you adjust the Styles menu.
    // Note: Only command groups that you add will be called to validate.
    override func validate(_ command: UICommand) {
        // Obtain the plist of the incoming command.
        command.state = .off
    }
    
    @objc func newWindow(_ sender: Any) {
        UIApplication.shared.requestSceneSessionActivation(nil,
                                                           userActivity: nil,
                                                           options: nil,
                                                           errorHandler: nil)
    }
}

extension UIApplication {
    func shelfSceen() -> UISceneSession? {
        let session = self.opEvernoteSessions.first(where: { eachScene in
            if eachScene.configuration.delegateClass == SceneDelegate.classForCoder() {
                return true;
            }
            return false;
        })
        return session;
    }
    
    func preferenceScene() -> UISceneSession? {
        let session = self.opEvernoteSessions.first(where: { eachScene in
            if eachScene.configuration.delegateClass == FTPreferenceSceneDelegate.classForCoder() {
                return true;
            }
            return false;
        })
        return session;
    }
    func sessionForDocument(_ relativePath: String) -> UISceneSession? {
        let session = self.opEvernoteSessions.first(where: { eachScene in
            if eachScene.configuration.delegateClass == FTBookOpenSceneDelegate.classForCoder(),
               eachScene.scene?.userActivity?.lastOpenedDocument == relativePath {
                return true;
            }
            return false;
        })
        return session;
    }
}
#endif
