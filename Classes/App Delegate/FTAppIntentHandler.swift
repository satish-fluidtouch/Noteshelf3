//
//  FTAppIntentHandler.swift
//  Noteshelf
//
//  Created by Akshay on 06/08/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Intents
import FTCommon
import CoreSpotlight
import SwiftyDropbox
#if !targetEnvironment(macCatalyst)
import GoogleSignIn
#endif

struct FTURLOptions {
    let sourceApplication: String?
    let annotation: Any?
    var openInPlace : Bool = false;
}

struct FTImportItemInfo {
    let collection: String
    let group: String
}

@objcMembers class FTImportItem : NSObject
{
    var importItem : AnyObject;
    private(set) var completionHandler : ((FTShelfItemProtocol?,Bool) -> ())?;
    var openOnImport = true;
    var imporItemInfo: FTImportItemInfo?
    required init(item : AnyObject,
                  onCompletion: ((FTShelfItemProtocol?,Bool) -> ())?)
    {
        importItem = item;
        completionHandler = onCompletion;
        super.init();
    }
   
    required init(item : AnyObject) {
        importItem = item;
        super.init();
    }
    
    required init(image: UIImage) {
        importItem = image;
        super.init();
    }
    
    func removeFileItems() {
        if let url = importItem as? URL {
            try? FileManager().removeItem(at: url);
        }
        else if let _item = self.importItem as? FTImportItemZip {
            _item.removeFileItems();
        }
    }
    
    func shouldSwitchToRoot() -> Bool {
        var shouldSwitchToShelf = false;
        if let url = self.importItem as? URL,
           url.pathExtension == nsBookExtension {
            shouldSwitchToShelf = true;
        }
        else if self.importItem is FTImportItemZip {
            shouldSwitchToShelf = true;
        }
        return shouldSwitchToShelf;
    }
}

protocol FTIntentHandlingProtocol: UIUserActivityRestoring {
    func importItem(_ item: FTImportItem)
    func createAndOpenNewNotebook(_ url: URL)
    func openDocumentForSelectedNotebook(_ path: URL, isSiriCreateIntent: Bool)
    func openShelfItem(spotLightHash: String)
    func openNotebook(using schemeUrl: URL)
    func openTemplatesScreen(url: URL)
    //From Quick Action
    func createNotebookWithAudio()
    func createNotebookWithCameraPhoto()
    func createNotebookWithScannedPhoto()
    func startNS2ToNS3Migration()
    func showPremiumUpgradeScreen()
}


final class FTAppIntentHandler {
    // This should be in sync with NS2
    enum NS3LaunchIntent: String {
       case migration = "NS2Migration"
       case premiumUpgrade = "purchasePremium"
    }

    private let supportedPathExts = [nsBookExtension
                                     ,nsThemePackExtension
                                     ,"zip"];
    private var intentHandler: FTIntentHandlingProtocol?

    init(with handler: FTIntentHandlingProtocol) {
        self.intentHandler = handler
    }

    @discardableResult
    func open(_ url: URL, options: FTURLOptions? = nil) -> Bool {
        FTCLSLog("Deeplink \(url.path)")

        var suportedDoc = false
        if let mimeType = MIMETypeFileAtPath(url.path), supportedMimeTypesForDownload().contains(mimeType) {
            suportedDoc = true
        }
        let pathExt = url.pathExtension.lowercased();
        if suportedDoc
            || self.supportedPathExts.contains(pathExt)
            || isAudioFile(url.path) {
            if options?.openInPlace ?? false {
                url.copyInPlaceURLToTemp { [weak self] (_readURL) in
                    if let readURL = _readURL {
                        let item = FTImportItem(item: readURL as AnyObject, onCompletion: nil);
                        self?.intentHandler?.importItem(item)
                    }
                }
            }
            else {
                let item = FTImportItem(item: url as AnyObject, onCompletion: nil);
                intentHandler?.importItem(item)
            }
            return true
        } else if let googleURLScheme = FTAppIntentHandler.googleURLScheme, url.scheme == googleURLScheme {
            #if !targetEnvironment(macCatalyst)
            GIDSignIn.sharedInstance.handle(url);
            #endif
        } else if (url.scheme == "db-25u7ct2k9iro3ka") {
            #if targetEnvironment(macCatalyst) // Workaround for mac catalyst app as immediately returning with cancelled status without any user action in browser
                if url.absoluteString.hasSuffix("/cancel") {
                   return true
                }
            #endif
            DropboxClientsManager.handleRedirectURL(url, completion: { (result) in
                switch result {
                case .success:
                    NotificationCenter.default.post(name: .didCompleteDropBoxAuthetication, object: nil)
                case .cancel:
                    NotificationCenter.default.post(name: .didCancelDropBoxAuthetication, object: nil)
                case .none:
                    print("error, message")
                case .some(.error(_, _)):
                    print("error, message")
                    break
                }
            })
            //Confirm this whether we can always return true
            return true
        }
        else if url.scheme == "noteshelf" {
            return true
        }
        else if (url.scheme == FTUtils.todayWidgetNewNotebookScheme()) {
            track("today_widget", params: ["type": "Create Notebook"])
            intentHandler?.createAndOpenNewNotebook(url)
            return true
        } else if (url.scheme == FTUtils.todayWidgetOpenNotebookScheme()) {
            track("today_widget", params: ["type": "Open Notebook"])
            intentHandler?.openDocumentForSelectedNotebook(url, isSiriCreateIntent: false)
            return true
        } else if (url.scheme == FTSharedGroupID.getAppBundleID()) {
            let reqHyperlinkStr = FTSharedGroupID.getAppBundleID() + ":" +  FTAppIntentHandler.hyperlinkPath
            if url.absoluteString.hasPrefix(reqHyperlinkStr) {
                intentHandler?.openNotebook(using: url)
            } else if url.path().contains(FTAppIntentHandler.templatesPath) {
                intentHandler?.openTemplatesScreen(url: url)
            } else {
                startMigration(url: url)
            }
        }
        return false
    }
    
    func startMigration(url: URL) {
        if let urlcomponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
            , let queryitem = urlcomponents.queryItems?.first
            , queryitem.name == "intent"
        {
            if queryitem.value == NS3LaunchIntent.migration.rawValue {
                intentHandler?.startNS2ToNS3Migration()
            } else {
                intentHandler?.showPremiumUpgradeScreen()
            }
        }
    }

    @discardableResult
    func continueUserActivity(_ userActivity: NSUserActivity, restorationHandler: (([UIUserActivityRestoring]?) -> Void)? = nil) -> Bool {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return false
        }
        let intentTypes = ["\(bundleId).createNotebook",
                           "\(bundleId).openNotebook",
                           "\(bundleId).createAudioNote"]
        var status = false
        if intentTypes.contains(userActivity.activityType) {
            track("siri_shortcut", params: ["type": userActivity.activityType])
            //For iOS 12 continueUserActivity method expects a completion block which restores the activity, where as in iOS 13 there are no such completion blocks required. Once this App is targeted for iOS 13 and above, we can refactor this by removing the completion blocks.
            if let restoration = restorationHandler, let intentHandler = self.intentHandler {
                restoration([intentHandler])
            } else {
                intentHandler?.restoreUserActivityState(userActivity)
            }
            status = true
        } else if (userActivity.activityType == CSSearchableItemActionType) {
            if let shelfItemUUID = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                intentHandler?.openShelfItem(spotLightHash:shelfItemUUID)
                status = true
            }
        } else if (userActivity.activityType == "INCreateNoteIntent") {
            FTUserDefaults.siriRequested(true)
            track("Siri", params: ["type": "Create Notebook"])
            if let url = userActivity.referrerURL {
                intentHandler?.openDocumentForSelectedNotebook(url, isSiriCreateIntent: true)
                status = true
            }
        } else if (userActivity.activityType == "INSearchForNotebookItemsIntent") {
            if let itemIdentifier = (userActivity.interaction?.intent as? INSearchForNotebookItemsIntent)?.notebookItemIdentifier {
                let url = URL(fileURLWithPath: itemIdentifier)
                track("Siri", params: ["type": "Search Notebook"])
                intentHandler?.openDocumentForSelectedNotebook(url, isSiriCreateIntent: false)
                status = true
            }
        }
        return status
    }

    func handleShortcutItem(item: UIApplicationShortcutItem) {
        guard let action = UIApplicationShortcutItem.QuickAction(rawValue: item.type) else {
            preconditionFailure("Wrong identifier in quick action \(item.type)")
        }
        switch action {
        case .newNotebook:
            intentHandler?.createAndOpenNewNotebook(URL(string: "https://www.google.com")!)
        case .newPhoto:
            intentHandler?.createNotebookWithCameraPhoto()
        case .newAudio:
            intentHandler?.createNotebookWithAudio()
        case .scanDocument:
            intentHandler?.createNotebookWithScannedPhoto()
        }
    }
}

private extension FTAppIntentHandler {
    static var googleURLScheme : String? {
        
        var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
        if let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let xmlData = FileManager.default.contents(atPath: plistPath) {
            do {
                let plistData = try PropertyListSerialization.propertyList(from: xmlData,
                                                           options: .mutableContainersAndLeaves,
                                                           format: &propertyListFormat) as? [AnyHashable:AnyObject];
                return plistData?["REVERSED_CLIENT_ID"] as? String
            } catch {
                debugPrint("google file loading failed");
            }
        }
        return nil;
    }
}

extension FTAppIntentHandler {
    static var hyperlinkPath: String {
        return "/hyperlink/"
    }
    static var templatesPath: String {
        return "/templates/root"
    }
    static var templatesPlannersPath: String {
        return FTAppIntentHandler.templatesPath + "/Planners"
    }
}

private extension UIApplicationShortcutItem {
    enum QuickAction: String {
        case newNotebook = "com.fluidtouch.noteshelf.quick.notebook"
        case newPhoto = "com.fluidtouch.noteshelf.quick.photo"
        case newAudio = "com.fluidtouch.noteshelf.quick.audio"
        case scanDocument = "com.fluidtouch.noteshelf.quick.scan"
    }
}
