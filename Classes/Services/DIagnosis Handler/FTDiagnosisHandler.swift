//
//  FTDiagnosisHandler.swift
//  Noteshelf
//
//  Created by Amar on 2/2/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import ZipArchive
import MessageUI

@objcMembers class FTDiagnosisHandler : NSObject,MFMailComposeViewControllerDelegate
{
    private static var __once: () = {
            Static.instance = FTDiagnosisHandler()
        }()
    struct Static
    {
        static var onceToken : Int = 0;
        static var instance : FTDiagnosisHandler? = nil;
    }

    class func sharedDiagnosisHandler() ->FTDiagnosisHandler
    {
        _ = FTDiagnosisHandler.__once
        return Static.instance!
    }
    
    func sendSystemLog(onViewController : UIViewController?)
    {
        if (!MFMailComposeViewController.canSendMail()) {
            let controller = UIAlertController.init(title: "", message: "EmailNotSetup".localized, preferredStyle: UIAlertController.Style.alert);
            let cancelAction = UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.default, handler: nil);
            controller.addAction(cancelAction);
            
            onViewController?.present(controller, animated: true, completion: nil);
            return;
        }

        let tempSyncFolderPath = NSTemporaryDirectory() + "/System";
        let fileManager = FileManager.init();
        _ = try? fileManager.removeItem(atPath: tempSyncFolderPath);
        _ = try? fileManager.createDirectory(atPath: tempSyncFolderPath, withIntermediateDirectories: true, attributes: nil);
        
         //Generate Contents
       #if !targetEnvironment(macCatalyst)
        self.generateEvernoteSynLog(tempSyncFolderPath);
        self.generateWatchSyncDefaults(tempSyncFolderPath);
        self.generateAdditionalCustomFields(tempSyncFolderPath);
        // Masking it for now, needs to change iteration logic and enable it
        // self.generateDocumentsDirectoryLog(tempSyncFolderPath)
        #endif
        self.generateCloudBackLog(tempSyncFolderPath);
        self.generateAppInfoLog(tempSyncFolderPath);
        self.generateUserDefaults(tempSyncFolderPath);
        self.generateUserFlowLog(tempSyncFolderPath);
        self.generateRecentEntries(tempSyncFolderPath);
        self.generateThemeMigrationLog(tempSyncFolderPath);
        self.generateDocErrorListLog(tempSyncFolderPath);
        //Do Zipping
        let zipPath = tempSyncFolderPath + ".log";
        let success = SSZipArchive.createZipFile(atPath: zipPath, withContentsOfDirectory: tempSyncFolderPath);

        //Attach to mail and send
        let mailComposerViewController = MFMailComposeController()
        mailComposerViewController.mailComposeDelegate = self;
        mailComposerViewController.setSubject("Noteshelf3 Log");

        let stringMessage = NSString.init(format: "<html><body><br><br><br><br><br><br> %@</body></html>", FTZenDeskManager.customFieldsString())
        mailComposerViewController.setMessageBody(stringMessage as String, isHTML: true)

        mailComposerViewController.addSupportMailID();
        if(success) {
            let sysData = try? Data.init(contentsOf: URL(fileURLWithPath: zipPath));
            if(sysData != nil) {
                mailComposerViewController.addAttachmentData(sysData!, mimeType: "application/com.ramki.logs", fileName: "noteshelf3.log")
            }
            _ = try? fileManager.removeItem(atPath: zipPath);
        }
        onViewController?.ftPresentModally(mailComposerViewController, hideNavBar: false, animated: true, completion: nil)
    }

    fileprivate func generateEvernoteSynLog(_ toPath : String)
    {
        FTENPublishManager.shared.generateSyncLog();
        let syncLogPath = FTENPublishManager.shared.nsENLogPath();
        let pathExt = (syncLogPath! as NSString).pathExtension;
        
        let ENSynLog = toPath + "/enSyncLog.\(pathExt)";
        _ = try? FileManager.init().moveItem(atPath: syncLogPath!, toPath: ENSynLog);
    }
    
    fileprivate func generateCloudBackLog(_ toPath : String)
    {
        if let filePath = FTCloudBackUpManager.shared.activeCloudBackUpManager?.backUpFilePath {
            let backupLogPath = toPath + "/backupLog.plist";
            _ = try? FileManager.init().copyItem(atPath: filePath, toPath: backupLogPath);
        }
    }
        
    fileprivate func generateAppInfoLog(_ toPath : String)
    {
        let filePath = toPath + "/appConfig.plist";
        let dict = FTAppConfigHelper.sharedAppConfig().logFileInfo() as NSDictionary;
        dict.write(toFile: filePath, atomically: true);
    }
    
    fileprivate func generateAdditionalCustomFields(_ toPath : String)
    {
        let filePath = toPath + "/customFields.plist";
        let dict = FTZenDeskManager.customFields() as NSDictionary;
        dict.write(toFile: filePath, atomically: true);
    }
    
    fileprivate func generateUserFlowLog(_ toPath : String)
    {
        let logger = FTLogger.init(fileName: "UserFlow.log", createIfNeeded: false);
        let path = logger.logPath();
        let fileManager = FileManager.init();
        if(fileManager.fileExists(atPath: path.path)) {
            let filePath = toPath.appending("/").appending(path.lastPathComponent);
            _ = try? fileManager.copyItem(atPath: path.path, toPath: filePath);
        }
    }
    
    fileprivate func generateDocumentsDirectoryLog(_ toPath : String)
    {
        let filePath = toPath + "/DocumentsDirectory.log";
        let directory = FTNoteshelfDocumentProvider.shared.generateDocumentsDirectoryLog()
        let combinedString = directory.joined(separator: "\n")
        do {
            try combinedString.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {}
    }
    
    fileprivate func generateUserDefaults(_ toPath : String)
    {
        let filePath = toPath + "/userDefaults.plist";
        let dict = UserDefaults.standard.dictionaryRepresentation() as NSDictionary;
        dict.write(toFile: filePath, atomically: true);
    }

    fileprivate func generateWatchSyncDefaults(_ toPath : String)
    {
        let fileName = "iOS-watchsynclog.txt";
        let logger = FTLogger.init(fileName: fileName, createIfNeeded: false);
        
        let path = logger.logPath();
        let fileManager = FileManager.init();
        if(fileManager.fileExists(atPath: path.path)) {
            let filePath = toPath.appending("/").appending(path.lastPathComponent);
            _ = try? fileManager.copyItem(atPath: path.path, toPath: filePath);
        }
        
        let watchFileName = "WatchOS-watchsynclog.txt";
        let logger1 = FTLogger.init(fileName: watchFileName, createIfNeeded: false);
        
        let path1 = logger1.logPath();
        if(fileManager.fileExists(atPath: path1.path)) {
            let filePath = toPath.appending("/").appending(path1.lastPathComponent);
            _ = try? fileManager.copyItem(atPath: path1.path, toPath: filePath);
        }
    }

    fileprivate func generateRecentEntries(_ toPath : String)
    {
        let filePath = toPath + "/sharedDefaults.plist";
        let dict = FTRecentEntries.defaults().dictionaryRepresentation() as NSDictionary;
        dict.write(toFile: filePath, atomically: true);
    }
    
    fileprivate func generateThemeMigrationLog(_ toPath : String)
    {
        let fileName = "migrationLog.txt";
        let logger = FTLogger.init(fileName: fileName, createIfNeeded: false);

        let path = logger.logPath();
        let fileManager = FileManager.init();
        if(fileManager.fileExists(atPath: path.path)) {
            let filePath = toPath.appending("/").appending(path.lastPathComponent);
            _ = try? fileManager.copyItem(atPath: path.path, toPath: filePath);
        }
    }

    fileprivate func generateDocErrorListLog(_ toPath : String)
    {
        guard let path = URL.documentErrorFileURL else {
            return;
        }
        let errorfilePth = path.path(percentEncoded: false);
        let fileManager = FileManager.init();
        if fileManager.fileExists(atPath: errorfilePth) {
            let filePath = toPath.appending("/").appending(path.lastPathComponent);
            _ = try? fileManager.copyItem(atPath: errorfilePth, toPath: filePath);
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}


class MFMailComposeController: MFMailComposeViewController, FTCustomPresentable {
    let customTransitioningDelegate = FTCustomTransitionDelegate(with: .presentation)
}
