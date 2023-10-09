//
//  FTSettingsAboutViewmodel.swift
//  Noteshelf3
//
//  Created by Rakesh on 22/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum SocialMediaTypes: CaseIterable{
    case instagram
    case twitter
    case facebook
    case medium
    case youtube

    var icon: String{
        switch self{
        case .facebook:
            return "followfb"
        case .instagram:
            return "followinstagram"
        case .twitter:
            return "followtwitter"
        case .medium:
            return "followMedium"
        case .youtube:
            return "followYoutube"
        }
    }
    var url: String{
        switch self{
        case .facebook:
            return "https://www.facebook.com/noteshelf"
        case .instagram:
            return "https://www.instagram.com/noteshelfapp/"
        case .twitter:
            return "https://twitter.com/noteshelf"
        case .medium:
            return "https://medium.com/noteshelf"
        case .youtube:
            return "https://www.youtube.com/fluidtouchapps"
        }
    }
}

enum FTAboutNoteshelfOptions: CaseIterable{
    case visitWebsite
    case privacyPolicy

    var title: String{
        let title: String
        switch self{
        case .visitWebsite:
            title = "AboutVisitNoteshelfWebsite"
        case .privacyPolicy:
            title = "iap.privacy"
        }
        return title.localized
    }
    var webUrl: String{
        switch self{
        case .visitWebsite:
            return "http://www.noteshelf.net"
        case .privacyPolicy:
            return "https://www.noteshelf.net/privacy.html"
        }
    }
}

class FTSettingsAboutViewModel: ObservableObject {
    var headerTopTitle: String {
        return "Noteshelf 3"
    }
    var headerdescription: String {
        return "settings.about.description".localized
    }
    var versionnumber: String {
        let buildVersion = "(\(appBuildVersion()))"
        return String(format: NSLocalizedString("settings.about.version", comment: "Version %@ %@ "), appVersion(),buildVersion)
    }
    var userid: String{
        guard let userid:String = UserDefaults.standard.object(forKey: "USER_ID_FOR_CRASH") as? String else {
            fatalError("No user id found")
        }
        return String(format: NSLocalizedString("settings.about.userID", comment: "User ID %@"), userid)
    }
    var copyrightMessage: String{
        return "settings.about.copyrightmessage".localized
    }
    var welcomeTourText: String{
        return "Welcome Tour".localized
    }
}
