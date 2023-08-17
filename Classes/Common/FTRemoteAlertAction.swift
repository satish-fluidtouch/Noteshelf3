//
//  FTRemoteAlertAction.swift
//  Noteshelf
//
//  Created by Amar on 9/2/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTRemoteAlertAction : UIAlertAction
{
    var messageUUID : String?;
    
    convenience init(messageUUID : String?)
    {
        #if swift(>=3.2) //ios11 or not
        #else
            self.init();
        #endif
        self.init(title: NSLocalizedString("OK",comment:"OK"), style: UIAlertAction.Style.default, handler: nil);
        self.messageUUID = messageUUID;
    }
}

class FTRemoteRemindLaterAlertAction : FTRemoteAlertAction
{
    convenience init(messageUUID : String?)
    {
        #if swift(>=3.2)
        #else
            self.init();
        #endif
        self.init(title: NSLocalizedString("RemindMeLater", comment: "Remind Me Later"), style: UIAlertAction.Style.default, handler: nil);
        self.messageUUID = messageUUID;
    }
}

class FTRemoteLearnMoreAlertAction : FTRemoteAlertAction
{
    var articleId : String!;
    
    convenience init(messageUUID : String?)
    {
        //subclass should override
        #if swift(>=3.2)
        #else
            self.init();
        #endif
        self.init(title: NSLocalizedString("LearnMore", comment: "Learn More"), style: UIAlertAction.Style.default, handler: {(action) in
            guard let controller = Application.keyWindow?.visibleViewController, let selfAction = action as? FTRemoteLearnMoreAlertAction else { fatalError("VisibleController is Nil")}
            
            FTZenDeskManager.shared.showArticle(selfAction.articleId, in: controller, completion: nil);
        });
        self.messageUUID = messageUUID;
    }
}

class FTRemoteDontShowAlertAction : FTRemoteAlertAction
{
    convenience init(messageUUID : String?)
    {
        //subclass should override
        #if swift(>=3.2)
        #else
            self.init();
        #endif
        self.init(title: NSLocalizedString("DontShowHintAgain", comment: "Don't Show"), style: UIAlertAction.Style.default, handler: {(action) in
            let selfAction = action as! FTRemoteDontShowAlertAction;
            let messageID = selfAction.messageUUID!;
            let dontShowMessageID = "Do_not_show_\(messageID)";
            UserDefaults.standard.set(true, forKey: dontShowMessageID);
            UserDefaults.standard.synchronize();
        });
        self.messageUUID = messageUUID;
    }
}

class FTRemoteUpgradeNowAlertAction : FTRemoteAlertAction
{
    convenience init(messageUUID : String?)
    {
        //subclass should override
        #if swift(>=3.2)
        #else
            self.init();
        #endif
        self.init(title: NSLocalizedString("UpgradeNowKey", comment: "Upgrade Now"), style: UIAlertAction.Style.default, handler: {(action) in
            let url = URL.init(string: "itms-apps://itunes.apple.com/app/id1271086060");
            UIApplication.shared.open(url!, options: [:], completionHandler: nil);
        });
        self.messageUUID = messageUUID;
    }
}
