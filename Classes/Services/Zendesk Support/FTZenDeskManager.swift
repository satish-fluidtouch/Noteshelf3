//
//  FTZenDeskManager.swift
//  Noteshelf
//
//  Created by Sameer on 12/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon
#if !targetEnvironment(macCatalyst)
import ZendeskCoreSDK
import SupportSDK
#else
import MessageUI
#endif

class FTBarButtonItem : UIBarButtonItem {
    var presentingController:UIViewController!
}

typealias FTZenDeskCompletionBlock = (Bool) -> Void

 @objc class FTZenDeskManager : NSObject, UINavigationControllerDelegate {
    private var presentingController:UIViewController!
    @objc static let shared = FTZenDeskManager()

   #if !targetEnvironment(macCatalyst)
    func initialize(block:ZDKAPIError) {
        #if !targetEnvironment(macCatalyst)
        Zendesk.initialize(appId: "f706b78f0d5e372e7ec35673b14114c92dd9437a8bdebb2f", clientId: "mobile_sdk_client_43e1908b98264345f83e", zendeskUrl: "https://noteshelf.zendesk.com")
        Support.initialize(withZendesk: Zendesk.instance)
        let userIdentity:ZDKObjCIdentity! = ZDKObjCAnonymous(withName:nil, email:nil)
        Zendesk.instance?.setIdentity(userIdentity)
        #endif
        block(nil)
    }
   #endif

   func showInternetConnectionError(_ controller: UIViewController?) {
       let alertController = UIAlertController(title: NSLocalizedString("ErrorConnecting", comment: "Error Connecting"), message: NSLocalizedString("CouldNotConnectToServer", comment: "Could not connect..."), preferredStyle: .alert)

       let action = UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Dismiss"), style: .cancel, handler: nil)
       alertController.addAction(action)
       controller?.present(alertController, animated: true)
    }

    func showArticleNotFoundError(_ controller: UIViewController?) {
        let alertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: NSLocalizedString("FailedToOpenDocumentUnexpectedError", comment: "Failed to open the document..."), preferredStyle: .alert)

        let action = UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Dismiss"), style: .cancel, handler: nil)
        alertController.addAction(action)
        controller?.present(alertController, animated: true)
    }


    @objc func showArticle(_ articleId: String?, in controller: UIViewController?, completion block: FTZenDeskCompletionBlock?) {

      #if !targetEnvironment(macCatalyst)
            self.presentingController = controller
        let loadingIndicatorViewController  =
            FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from:controller!, withText:"", andDelay:0)
            initialize(block: { [self] error in
                if error == nil {
                    let provider = ZDKHelpCenterProvider()
                    provider.getArticleWithId(articleId, withCallback:{ (items, error) in
                        loadingIndicatorViewController.hide({
                            guard let items = items else {
                                return
                            }
                            if (error == nil) && !items.isEmpty {
                                let article = items[0] as? ZDKHelpCenterArticle
                                let articleViewController =
                                    ZDKHelpCenterUi.buildHelpCenterArticleUi(withArticleId: (article?.identifier.stringValue) ?? "" , andConfigs:[])
                                let navController = UINavigationController(rootViewController:articleViewController)
                                if ZDKUIUtil.isPad() {
                                    navController.modalPresentationStyle = .formSheet
                                }

                                let doneButton = UIBarButtonItem(title:NSLocalizedString("Done", comment: ""), style:.done, target:self, action:#selector(self.doneButtonPressed))
                                articleViewController.navigationItem.leftBarButtonItem = doneButton

                                let contactUsButton = UIBarButtonItem(title:NSLocalizedString("Support", comment: ""),  style:.done,target:self, action:#selector(self.articleContactUsScreen))
                                articleViewController.navigationItem.rightBarButtonItem = contactUsButton

                                controller?.present(navController, animated:true, completion:{
                                    block?(true)
                                })
                            }
                            else {
                                //Show alert
                                self.showArticleNotFoundError(controller)
                                block?(false)
                            }
                        })
                    })
                }
                else{
                    self.showInternetConnectionError(controller)
                    loadingIndicatorViewController.hide(afterDelay: 0)
                }
            })
    #endif
        }

    @objc func doneButtonPressed() {
      self.presentingController.dismiss(animated: true, completion:nil)
    }

    @objc func showContactScreen(item:FTBarButtonItem!) {
        weak var weakSelf:FTZenDeskManager! = self
        track("Shelf_Settings_Support_Contact", params: nil, screenName: FTScreenNames.shelfSettings)
        let options = UIAlertController(title: nil, message:nil, preferredStyle:.actionSheet)
        
        let emailOption = UIAlertAction(title: NSLocalizedString("SendEmail", comment: ""), style:.default, handler:{ (_ :UIAlertAction) in
            #if DEBUG
            let subject = "Test - ignore"
            #elseif RELEASE
            let subject = ""
            #else
            let subject = "Test - ignore"
            #endif
            track("Shelf_Settings_Support_Contact_Email", params: nil, screenName: FTScreenNames.shelfSettings)
            weakSelf.showSupportContactUsScreen(controller: item.presentingController, defaultSubject:subject)
        })
        options.addAction(emailOption)
        
        let sendLogsOption = UIAlertAction(title: NSLocalizedString("SendLogs", comment: ""), style:.default, handler:{ (_ :UIAlertAction) in
            FTDiagnosisHandler.sharedDiagnosisHandler().sendSystemLog(onViewController: item.presentingController)
            track("Shelf_Settings_Support_Contact_Logs", params: nil, screenName: FTScreenNames.shelfSettings)
        })
        options.addAction(sendLogsOption)
        
        let cancelOption = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style:.cancel, handler:nil)
        options.addAction(cancelOption)
        
        options.popoverPresentationController?.barButtonItem = item
        item.presentingController.present(options, animated:true, completion:nil)
    }

    func showSupportContactUsScreen(controller:UIViewController!) {
        #if DEBUG
            let subject = "Test - ignore"
        #elseif RELEASE
            let subject = ""
        #else
            let subject = "Noteshelf3 Beta Feedback"
        #endif
        self.showSupportContactUsScreen(controller: controller, defaultSubject:subject)
    }

    func showSupportHelpCenterScreen(controller:UIViewController!) {
     #if  !targetEnvironment(macCatalyst)
         initialize(block: { [self] error in
            if (error == nil) {
                let hcConfig = HelpCenterUiConfiguration()
                hcConfig.groupType = .category
                hcConfig.groupIds = [22023798601881]
                hcConfig.showContactOptions = false
                hcConfig.showContactOptionsOnEmptySearch = false;
                
                let helpCenter = ZDKHelpCenterUi.buildHelpCenterOverviewUi(withConfigs: [hcConfig])
                var navController = controller.navigationController
                if nil != navController {
                    controller.navigationController?.pushViewController(helpCenter, animated:true)
                    controller.navigationController?.delegate = self
                }
                else {
                    navController = UINavigationController(rootViewController:helpCenter)
                    navController?.delegate = self
                    navController?.isModalInPresentation = true
                    if let navController = navController {
                        controller.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
                    }
                }
            }
            else{
                self.showInternetConnectionError(controller)
            }
        })
#endif
    }
     
   func presentSupportHelpCenterScreen(controller:UIViewController!) {
    #if  !targetEnvironment(macCatalyst)
       initialize(block: { [self] error in
           if (error == nil) {
               let hcConfig = HelpCenterUiConfiguration()
               hcConfig.groupType = .category
               hcConfig.groupIds = [22023798601881]
               hcConfig.showContactOptions = false
               hcConfig.showContactOptionsOnEmptySearch = false;
               
               let helpCenter = ZDKHelpCenterUi.buildHelpCenterOverviewUi(withConfigs: [hcConfig])
               let navController = UINavigationController(rootViewController:helpCenter)
               navController.delegate = self
               navController.isModalInPresentation = true
               controller.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
           }
           else{
               self.showInternetConnectionError(controller)
           }
       })
    #endif
     }

    func showFeedbackSupportScreen(controller:UIViewController!) {
        #if DEBUG
            let subject = "Test - ignore"
        #elseif RELEASE
            let subject = "Feedback"
        #else
            let subject = "NS2 Beta Feedback"
        #endif
        self.showSupportContactUsScreen(controller: controller, defaultSubject:subject)
    }

     func showSupportContactUsScreen(controller:UIViewController
                                     , defaultSubject subject: String
                                     , extraTags: [String] = []) {
#if targetEnvironment(macCatalyst)
         if MFMailComposeViewController.canSendMail() {
             let mailComposerViewController = MFMailComposeViewController()
             mailComposerViewController.mailComposeDelegate = self;
             mailComposerViewController.isModalInPresentation = true
             mailComposerViewController.setSubject(subject);
             mailComposerViewController.addSupportMailID();
             controller.present(mailComposerViewController, animated: true);
         }
         else {
             UIAlertController.showAlert(withTitle: "", message: "EmailNotSetup".localized, from: controller, withCompletionHandler: nil);
         }
#else
         initialize(block: { [self] error in
            if error == nil {
                let requestConfig = RequestUiConfiguration()
                var tags = extraTags;
                tags.append(self.appTag);
                
                let customField = CustomField(fieldId:360015598614, value:FTZenDeskManager.customFieldsString())
                requestConfig.customFields = [customField]
                requestConfig.tags = tags
                requestConfig.subject = subject

                let helpCenter = RequestUi.buildRequestUi(with: [requestConfig])
                let navController = UINavigationController(rootViewController:helpCenter)
                navController.isModalInPresentation = true
                controller.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
            }
            else{
                self.showInternetConnectionError(controller)
            }
        })
#endif
    }

    @objc func articleContactUsScreen() {
        self.showSupportContactUsScreen(controller: self.presentingController.presentedViewController)
    }
    
    // MARK: - Custom Fields

    class func freeDiskSpace() -> String {
        let diskSpace = UIDevice.current.freeDiskSpaceInGB;
        return diskSpace
    }

    class func cloudUsed() -> String {
        let cloudUsed:NSMutableArray! = NSMutableArray()

        let dropboxLinked:Bool = FTDropboxManager.sharedDropboxManager.isLoggedIn()
        if dropboxLinked
        {cloudUsed.add("Dropbox")}

        let oneDriveLinked:Bool = FTOneDriveClient.shared.isLoggeedIn()
        if oneDriveLinked
        {cloudUsed.add("OneDrive")}

        #if !targetEnvironment(macCatalyst)
        let evernoteLinked:Bool = EvernoteSession.shared().isAuthenticated
        if evernoteLinked
        {
            cloudUsed.add("Evernote")
        }
        #endif
        return cloudUsed.componentsJoined(by: ", ")
    }
    class func customFields() -> [String : Any] {
        let isPaired = NSUbiquitousKeyValueStore.default.isWatchPaired()
        let isWatchAppInstalled = NSUbiquitousKeyValueStore.default.isWatchAppInstalled()
        var watchStatus = isPaired ? "N/I" : "N/A"
        if isWatchAppInstalled {
            watchStatus = "Installed"
        }
        let deviceName = UIDevice().isMac() ? "Mac" : FTUtils.deviceModelFriendlyName()
        var customFields = [String : Any]()
        customFields = [
            "User ID": UserDefaults.standard.string(forKey: "USER_ID_FOR_CRASH") ?? "",
            "App Version": "\(appVersion()) (\(appBuildVersion()))",
            "Sizes": "Free: \(self.freeDiskSpace())",
            "Clouds Used": self.cloudUsed(),
            "Device": deviceName,
            "OS": "\(UIDevice.current.systemName) \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "iCloud": FTNSiCloudManager.shared().iCloudOn() ? "YES" : "NO",
            "Autobackup": FTCloudBackUpManager.shared.activeCloudBackUpManager?.cloudBackUpName() ?? "none",
            "ENPublish": UserDefaults.standard.bool(forKey: "EvernotePubUsed") ? "YES" : "NO",
            "Apple Pencil": UserDefaults.standard.bool(forKey: "isUsingApplePencil") ? "YES" : "NO",
            "Lang": FTUtils.currentLanguage(),
            "Locale": NSLocale.current.identifier,
            "AppleWatch": watchStatus,
            "Recognition": FTNotebookRecognitionHelper.shouldProceedRecognition ? "YES" : "NO",
            "Recog_Act": FTNotebookRecognitionHelper.myScriptActivated ? "YES" : "NO",
            "LayoutType": (UserDefaults.standard.pageLayoutType == .vertical) ? "Vertical" : "Horizontal",
            "Battery": UIDevice.current.batteryStateString,
            "Screens": UIScreen.screensDescription,
            "Premium" : FTIAPManager.shared.premiumUser.isPremiumUser ? "YES" : "NO",
            "NS2": FTDocumentMigration.isNS2AppInstalled() ? "YES" : "NO",
            "SafeMode": FTUserDefaults.isInSafeMode() ? "YES" : "NO"
        ]
        return customFields
    }

    class func customFieldsString() -> String {
        let customFields = self.customFields()
        var string: String?
        if let userId = customFields["User ID"],
           let version = customFields["App Version"],
           let operatingSystem = customFields["OS"],
           let Device = customFields["Device"],
           let sizes = customFields["Sizes"],
           let cloudUsed = customFields["Clouds Used"],
           let pencil = customFields["Apple Pencil"],
           let iCloud = customFields["iCloud"],
           let autobackup = customFields["Autobackup"],
           let ENPublish = customFields["ENPublish"],
           let lang = customFields["Lang"],
           let locale = customFields["Locale"],
           let appleWatch = customFields["AppleWatch"],
           let recognition = customFields["Recognition"],
           let recog_Act = customFields["Recog_Act"],
           let layoutType = customFields["LayoutType"],
           let battery = customFields["Battery"],
           let premium = customFields["Premium"],
           let ns2 = customFields["NS2"],
           let safemode = customFields["SafeMode"]{
            string = "User ID: \(userId) | Version: \(version) | Premium: \(premium) | OS: \(operatingSystem) | Device: \(Device) | \(sizes) | Cloud: \(cloudUsed) | Apple Pencil: \(pencil) | iCloud: \(iCloud) | Autobackup: \(autobackup) | Publish: \(ENPublish) | Lang: \(lang) | Locale: \(locale) | AppleWatch : \(appleWatch) | Recognition : \(recognition) | Recog_Act: \(recog_Act) | Layout: \(layoutType) | Battery: \(battery) | Screens : \(UIScreen.screensDescription) | NS2: \(ns2) | SafeMode: \(safemode)"
        }
        return string ?? ""
    }
    //ENBusinessSupport
    class func incrementENSyncEnabledForBusinessStore() {
        let key:String! = "ENBusinessStoreSyncEnabledBooksCount"
        var numberOfCounts:Int = UserDefaults.standard.integer(forKey: key)
        numberOfCounts += 1
        UserDefaults.standard.set(numberOfCounts, forKey:key)
        UserDefaults.standard.synchronize()
    }
     

    // MARK: - UINavigationControllerDelegate -
    func navigationController(_ navigationController:UINavigationController, willShow viewController:UIViewController, animated:Bool) {
        if (viewController is FTGlobalSettingsController) {
            navigationController.delegate = nil
        }
        else {
            let item:FTBarButtonItem! = FTBarButtonItem(image:UIImage(systemName: "square.and.pencil"),
                                                        style:.done,
                                                                    target:self,
                                                                    action:#selector(showContactScreen(item:)))
            item.presentingController = navigationController
            viewController.navigationItem.rightBarButtonItem = item
        }
    }
}

private extension UIDevice {
    var batteryStateString: String {
        self.isBatteryMonitoringEnabled = true
        let state = self.batteryState
        switch state {
        case .unknown:
            return "unknown"
        case .unplugged:
            return "unplugged"
        case .charging:
            return "charging"
        case .full:
            return "full"
        default:
            return ""
        }
    }
}

private extension UIScreen {
    static var screensDescription: String {
        var info : String = ""
        for screen in screens {
            let dimensions = "\(screen.bounds.width)x\(screen.bounds.height)"
            info.append(dimensions)
        }
        return info
    }
}

extension UIDevice {
    func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }
    
    //MARK: Get String Value
    var totalDiskSpaceInGB:String {
       return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var freeDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var usedDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var totalDiskSpaceInMB:String {
        return MBFormatter(totalDiskSpaceInBytes)
    }
    
    var freeDiskSpaceInMB:String {
        return MBFormatter(freeDiskSpaceInBytes)
    }
    
    var usedDiskSpaceInMB:String {
        return MBFormatter(usedDiskSpaceInBytes)
    }
    
    //MARK: Get raw value
    var totalDiskSpaceInBytes:Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return 0 }
        return space
    }
    
    /*
     Total available capacity in bytes for "Important" resources, including space expected to be cleared by purging non-essential and cached resources. "Important" means something that the user or application clearly expects to be present on the local system, but is ultimately replaceable. This would include items that the user has explicitly requested via the UI, and resources that an application requires in order to provide functionality.
     Examples: A video that the user has explicitly requested to watch but has not yet finished watching or an audio file that the user has requested to download.
     This value should not be used in determining if there is room for an irreplaceable resource. In the case of irreplaceable resources, always attempt to save the resource regardless of available capacity and handle failure as gracefully as possible.
     */
    var freeDiskSpaceInBytes:Int64 {
        if #available(iOS 11.0, *) {
            if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                return space
            } else {
                return 0
            }
        } else {
            if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                return freeSpace
            } else {
                return 0
            }
        }
    }
    
    var usedDiskSpaceInBytes:Int64 {
       return totalDiskSpaceInBytes - freeDiskSpaceInBytes
    }
}

#if targetEnvironment(macCatalyst)
extension FTZenDeskManager: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true);
    }
}
#endif

private extension FTZenDeskManager {
#if ENTERPRISE_EDITION
    var appTag: String {
#if DEBUG
        let tag = "NS3-EE-Dev"
#else
        let tag = "Noteshelf-3-EE"
#endif
        return tag;
    }
#else
    var appTag: String {
#if DEBUG
        let tag = "NS3-Dev"
#elseif RELEASE
        let tag = "Noteshelf-3"
#else
        let tag = "NS3-Beta"
#endif
        return tag;
    }
#endif
}
