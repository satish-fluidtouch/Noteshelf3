//
//  FTDBBackupManager.swift
//  Noteshelf
//
//  Created by Akshay on 28/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import ZipArchive

public enum FTBackupError: Error {
    case cancelled
    case paused
    case error(failedItems: [String]?)
    case zippingFailed
}

public struct FTBackupSuccess {
    let url: URL
    let failedItems: [String]?
}

public typealias FTBackupResult = Result<FTBackupSuccess,FTBackupError>
public typealias FTBackupCompletion = (_ result: FTBackupResult) -> Void

public final class FTDBBackupManager {
    private var backupDirectory = URL(fileURLWithPath:NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("ExportData")

    private let nbkContentGenerator = FTNBKContentGenerator()
    private var progress : Progress
    private var smartProgress : FTSmartProgressView

    private var currentContentGen : FTNBKContentGenerator?
    private var exportContent : FTExportDataContent?
    private var bgTask = UIBackgroundTaskIdentifier.invalid;
    private var exportPaused = false;
    private var isProcessInProgress = false;
    private var completionHandler: FTBackupCompletion?

    init() {
        progress = Progress()
        progress.isCancellable = true;
        progress.isPausable = true;

        smartProgress = FTSmartProgressView(progress: progress);

        progress.cancellationHandler = { [weak self] in
            self?.smartProgress.hideProgressIndicator()
            self?.cleanUpData()
        }
        self.progress.pausingHandler = { [weak self] in
            self?.pauseExportOperations()
        }

        self.progress.resumingHandler = { [weak self] in
            if(self?.exportPaused ?? false) {
                self?.resumeExportOperations()
            }
        }
    }

    func startBackup(from viewController: UIViewController, completion: @escaping FTBackupCompletion) {

        createBackupDirectory()

        let message = NSLocalizedString("Preparing", comment: "Preparing")
        self.smartProgress.showProgressIndicator(message, onViewController: viewController);
        startExporting(completion:{ [weak self] result in
            if let task = self?.bgTask {
                endBackgroundTask(task)
            }
            DispatchQueue.main.async {
                self?.smartProgress.hideProgressIndicator()
                completion(result)
            }
        })
    }

    func pause() {
        //As of now we're pausing the process, while looping and the remaining time is less than 10 seconds.
        //self.progress.pause()
    }

    func resume() {
        self.progress.resume()
    }

    func cleanUpData() {
        try? FileManager.default.removeItem(at: backupDirectory)
        try? FileManager.default.removeItem(at: backupDirectory.appendingPathExtension("zip"))
    }
}

//MARK:- Export
private extension FTDBBackupManager {
    func startExporting(completion: @escaping FTBackupCompletion) {
        let options = FTFetchShelfItemOptions()
        options.sortOrder = .none
        FTNoteshelfDocumentProvider.shared.fetchAllShelfItems(option: options) { [weak self] shelfItems in
            guard let strongSelf = self else { return }
            let itemsToExport = shelfItems.map({ item -> FTItemToExport in
                let containingURL = strongSelf.backupLocation(for: item)
                //Create Shelf and Group directories if required
                strongSelf.createDirectory(at: containingURL)

                let exportItem = FTItemToExport(shelfItem: item)
                //Exports .noteshelf to Custom Location
                exportItem.destinationURL = containingURL
                return exportItem
            })

            //Adding another 1 for Zipping the contents
            let content = FTExportDataContent(items: itemsToExport)
            strongSelf.exportContent = content
            strongSelf.progress.totalUnitCount = Int64(itemsToExport.count) + content.approximateZipProgress
            strongSelf.completionHandler = completion
            strongSelf.bgTask = startBackgroundTask();
            strongSelf.export()
        }
    }

    func export() {
        self.startProcessing { [weak self] result in
            let failedItems = self?.exportContent?.failedItemTitles()
            switch result {
            case .success:
                if let zipURL = self?.zipBackupDirectory() {
                    let success = FTBackupSuccess(url: zipURL, failedItems: failedItems)
                    self?.completionHandler?(.success(success))
                } else {
                    self?.completionHandler?(.failure(.zippingFailed))
                }
            case .failure(let error):
                switch error {
                case .cancelled:
                    self?.completionHandler?(.failure(.cancelled))
                case .paused:
                    FTCLSLog("DB Export Paused")
                default:
                    self?.completionHandler?(.failure(.error(failedItems: failedItems)))
                }
            }
            self?.completionHandler = nil
        }
    }

    func startProcessing(completion: @escaping (_ result: Result<Bool,FTBackupError>) -> Void) {

        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .background {
                if UIApplication.shared.backgroundTimeRemaining < 10 {
                    self.progress.pause()
                }
            }
        }

        if self.progress.isCancelled == true {
            self.isProcessInProgress = false;
            completion(.failure(.cancelled));
            return;
        }

        isProcessInProgress = true;
        if self.progress.isPaused {
            self.exportPaused = true;
            self.isProcessInProgress = false;
            completion(.failure(.paused));
            return;
        }

        DispatchQueue.global().async {
            guard let itemToProcess = self.exportContent?.nextItemToExport() else {
                completion(.success(true))
                return
            }
            self.progress.localizedDescription = self.exportContent?.messageForProgress()
            self.currentContentGen = nil
            self.currentContentGen = FTNBKContentGenerator()
            if let progressToAdd = self.currentContentGen?.progress {
                self.progress.addChild(progressToAdd, withPendingUnitCount: 1)
            }

            self.currentContentGen?.generateContent(forItem: itemToProcess, onCompletion:
                                        { [weak self] (item, error,_) in
                                            self?.currentContentGen = nil;
                                            self?.isProcessInProgress = false
                                            if error != nil {
                                                self?.exportContent?.exportFailed()
                                            } else if item != nil {
                                                self?.exportContent?.exportSucceeded()
                                            }
                                            self?.startProcessing(completion:completion);
                                        });
        }
    }
}

//MARK:- Private
private extension FTDBBackupManager {
    func createBackupDirectory() {
        
        #if !DEBUG && !BETA && !TARGET_OS_SIMULATOR
        /*
         make sure:
         File: SSZipArchive.m
         method: _zipOpenEntry(zipFile entry, NSString *name, const zip_fileinfo *zipfi, int level, NSString *password, BOOL aes)
         at the end in return call return zipOpenNewFileInZip5 passing 1 as argument for zip64
         */
            //callingANonExistingFunctionForBreakingTheCompilation()
        #endif

        try? FileManager.default.removeItem(at: backupDirectory)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let date = dateFormatter.string(from: Date())
        let backUpFolderName = "Noteshelf_Backup_\(date)"

        backupDirectory.appendPathComponent(backUpFolderName, isDirectory: true)

        createDirectory(at: backupDirectory)
        #if DEBUG
        print("Backup Location",backupDirectory.path)
        #endif
    }

    func zipBackupDirectory() -> URL? {
        let zipProgress = Progress()
        let progressCount = exportContent?.approximateZipProgress ?? 1
        self.progress.addChild(zipProgress, withPendingUnitCount: progressCount)
        self.progress.localizedDescription = NSLocalizedString("finalizing", comment: "finalizing")

        let zipURL = URL(fileURLWithPath:backupDirectory.path).appendingPathExtension("zip")
        let isSuccess = SSZipArchive.createZipFile(atPath: zipURL.path, withContentsOfDirectory: backupDirectory.path, keepParentDirectory: true, withPassword: nil, andProgressHandler: { (completed, total) in
            zipProgress.totalUnitCount = Int64(total)
            zipProgress.completedUnitCount = Int64(completed)
        })
        //delete source directory
        try? FileManager.default.removeItem(at: backupDirectory)
        return isSuccess ? URL(fileURLWithPath: zipURL.path) : nil
    }

    func backupLocation(for item: FTShelfItemProtocol) -> URL {
        let realtivePath = item.URL.deletingLastPathComponent().displayRelativePathWRTCollection()
        let containingDirectoryPath = backupDirectory.appendingPathComponent(realtivePath, isDirectory: true)
        return containingDirectoryPath
    }

    func createDirectory(at location: URL) {
        var isDir = ObjCBool.init(true);
        if FileManager.default.fileExists(atPath: location.path, isDirectory: &isDir) == false {
            do {
                try FileManager.default.createDirectory(at: location, withIntermediateDirectories: true, attributes: nil)
            } catch {
                #if DEBUG
                print("Unable to Create directory",location.lastPathComponent)
                #endif
            }
        }
    }

    func pauseExportOperations() {
        if let currentGenerator = self.currentContentGen {
            currentGenerator.pauseProcess();
        } else {
            while (self.isProcessInProgress) {
                sleep(UInt32(0.05));
            }
        }
        endBackgroundTask(self.bgTask);
    }

    func resumeExportOperations() {
        self.bgTask = startBackgroundTask();
        if(nil != self.currentContentGen) {
            self.currentContentGen?.resumeProcess();
        } else {
            if(self.exportPaused) {
                self.export();
            }
        }
    }
}
