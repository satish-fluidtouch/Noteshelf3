//
//  FTContentGenerator.swift
//  Noteshelf
//
//  Created by Siva on 23/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import ZipArchive

protocol FTContentGeneratorProtocol {
    func generateContent(forItem item: FTItemToExport,
                         onCompletion completion: @escaping InternalCompletionHandler);
    var preferedFileName: String {get}
    var internalCompletionHandler : InternalCompletionHandler? { get set};
    func resumeProcess();
    func pauseProcess();
}

enum FTExportErrorCode : Int {
    case Cancelled = 102
    case Paused = 103
}

extension NSError  {
    class func exportCancelError() -> NSError {
        return NSError.init(domain: "NSExport", code: FTExportErrorCode.Cancelled.rawValue, userInfo: nil);
    }
    
    class func exportPausedError() -> NSError {
        return NSError.init(domain: "NSExport", code: FTExportErrorCode.Paused.rawValue, userInfo: nil);
    }
}

typealias InternalCompletionHandler = (FTExportItem?,NSError?,Bool) -> Void;
typealias CompletionHandlerType = (_ cancelled: Bool,_ error : NSError?,_ contents: [FTExportItem]?) -> Void;
typealias ProgressHandlerType = (_ message: String?, _ progress: Float) -> Void;

class FTExportContentGenerator: NSObject, FTContentGeneratorProtocol {
    var bgTask = UIBackgroundTaskIdentifier.invalid;
    
    internal var isProcessInProgress = false;
    internal var exportPaused = false;

    internal var rootViewController : UIViewController?;
    internal var target: FTExportTarget!
    internal var currentItem : FTItemToExport?;
    
    fileprivate var itemsToProcess = [FTItemToExport]();
    fileprivate var completionHandler: CompletionHandlerType?;
    fileprivate var currentContentGen : FTExportContentGenerator?;
    fileprivate var contentsGenerated = [FTExportItem]();
    
    internal var internalCompletionHandler : InternalCompletionHandler?;
    internal weak var presentingController : UIViewController?;

    var progress = Progress();

    deinit {
        #if DEBUG
        debugPrint("deinit:%@",self.classForCoder);
        #endif
    }

    func clearCache()
    {
        do {
            let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last;
            let tempFileLoc = (cacheDirectory)! + "/TEMP_CACHE_DIR"
            try FileManager.default.removeItem(atPath: tempFileLoc);
        }
        catch {

        }
    }
    
    required convenience init(target: FTExportTarget,onViewController : UIViewController?) {
        self.init();
        self.target = target;
        self.progress.isCancellable = true;
        self.progress.isPausable = true;
        self.presentingController = onViewController;
        
        self.progress.pausingHandler = { [weak self] in
            self?.pauseExportOperations()
        }

        self.progress.resumingHandler = { [weak self] in
            if(self?.currentContentGen?.exportPaused ?? false) {
                self?.resumeExportOperations()
            }
        }
    }
    
    //MARK:- FactoryMethods
    private func contentGenerator(forFormat format: RKExportFormat,
                                  onViewController : UIViewController?) -> FTExportContentGenerator {
        let contentGeneratorType : FTExportContentGenerator.Type;
        switch format {
        case kExportFormatNBK:
            contentGeneratorType = FTNBKContentGenerator.self;
        case kExportFormatPDF:
            contentGeneratorType = FTPDFDocumentPDFContentGenerator.self;
        case kExportFormatImage:
            contentGeneratorType = FTPDFDocumentImageContentGenerator.self;
        case kExportFormatTemplate:
            contentGeneratorType = FTNSTemplateContentGenerator.self;
        default:
            contentGeneratorType = FTExportContentGenerator.self
        }
        let contentGenerator = contentGeneratorType.init(target: self.target,
                                                         onViewController: onViewController)
        return contentGenerator;
    }
    
    //MARK:- Methods
    func generateContents(onCompletion completionHandler: @escaping CompletionHandlerType)
    {
        self.completionHandler = completionHandler;
        self.itemsToProcess = self.target.itemsToExport;
       
        self.progress.totalUnitCount = Int64(self.itemsToProcess.count);
        self.progress.completedUnitCount = 0;

        self.updateProgress();

        self.generate();
    }
    
    fileprivate func generate() {
        self.startProcessingFor(items: self.itemsToProcess, { (error) in
            // Removed below main thread, to avoid deadlock in macOS Ventura while trying to drag and drop.
//            DispatchQueue.main.async {
                var isPaused = false;
                if nil == error {
                    self.completionHandler?(false, nil,self.contentsGenerated);
                }
                else {
                    var processCancelled = false;
                    if(error!.domain == "NSExport") {
                        if(error!.code == FTExportErrorCode.Paused.rawValue) {
                            isPaused = true;
                        }
                        else if(error!.code == FTExportErrorCode.Cancelled.rawValue) {
                            processCancelled = true;
                        }
                    }
                    if(!isPaused) {
                        self.completionHandler?(processCancelled,error,nil);
                    }
                }
                if(!isPaused) {
                    self.destoryHandlers();
                }
//            }
        })
    }
    
    fileprivate func startProcessingFor(items : [FTItemToExport], _ completion : @escaping (NSError?) -> (Void))
    {
        if self.progress.isCancelled {
            completion(NSError.exportCancelError());
            return;
        }
        
        isProcessInProgress = true;
        if self.progress.isPaused {
            self.exportPaused = true;
            self.isProcessInProgress = false;
            completion(NSError.exportPausedError());
            return;
        }
        self.exportPaused = false;
        var itemsToProcess = items
        DispatchQueue.global().async {
                func generateContent(){
                    let item = itemsToProcess.first;
                    if item != nil {
                        self.updateProgress();
                        if let groupItem = item?.shelfItem as? FTGroupItemProtocol{
                            var itemsToExport = [FTItemToExport]();
                            for childItem in groupItem.childrens{
                                let exportItem = FTItemToExport.init(shelfItem: childItem);
                                itemsToExport.append(exportItem);
                            }
                            let target = FTExportTarget.init()
                            target.itemsToExport = itemsToExport;
                            target.properties = self.target.properties;
                            let exportContentGenerator = FTExportContentGenerator(target: target, onViewController: self.presentingController)
                            exportContentGenerator.generateContents { (_, error, exportItems) in
                                itemsToProcess.removeFirst()
                                if error == nil, let generatedExportItems = exportItems, !generatedExportItems.isEmpty {
                                    var exportName = groupItem.displayTitle
                                    if self.contentsGenerated.isEmpty {
                                        exportName = self.itemsToProcess.first?.filename ?? groupItem.displayTitle
                                    }
                                    if let exportItem = self.createGroupExportItemFor(items: generatedExportItems, withGroupName: exportName){
                                        self.contentsGenerated.append(exportItem)
                                    }
                                }
                                if nil != error {
                                    completion(error)
                                }else{
                                    generateContent()
                                }
                            }
                        }else{
                            self.createExportItemFor(item: item!) { (exportItem, error) in
                                if self.target.pagesaveType == .share {
                                    itemsToProcess.removeFirst()
                                    if nil != exportItem{
                                        self.contentsGenerated.append(exportItem!);
                                    }
                                    if nil != error {
                                        completion(error)
                                    }else{
                                        generateContent()
                                    }
                                }else{
                                    completion(nil)
                                }
                            }
                        }
                    }else{
                        self.isProcessInProgress = false;
                        completion (nil);
                    }
                }
            generateContent()
        }
    }
    private func localFolderPathForGroup(_ name : String) -> String
    {
        let cacheDirectory = self.temporaryCacheLocation();
        let fileName = name;
        let groupURL = URL(fileURLWithPath: cacheDirectory).appendingPathComponent(fileName);
        try? FileManager.default.removeItem(at: groupURL)
        do {
            try FileManager.default.createDirectory(atPath: groupURL.path, withIntermediateDirectories: true, attributes:nil);
        }
        catch {
            
        }
        return groupURL.path;
    }
    
    private func temporaryCacheLocation() -> String
    {
        var tempFileLoc = "";
        if let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last {
            let url = URL(fileURLWithPath: cacheDirectory).appendingPathComponent("TEMP_CACHE_DIR");
            tempFileLoc = url.path;
            var isDir : ObjCBool = false;
            if FileManager.default.fileExists(atPath: tempFileLoc, isDirectory: &isDir) == false || !isDir.boolValue
            {
                do {
                    try FileManager.default.createDirectory(atPath: tempFileLoc, withIntermediateDirectories: true, attributes:nil);
                }
                catch {
                    
                }
            }
        }
        return tempFileLoc;
    }
    private func createGroupExportItemFor(items : [FTExportItem], withGroupName name: String) -> FTExportItem?{
        var itemURLS = [URL]();
        itemURLS = items.map({ (exportItem) -> URL in
            if let url = exportItem.representedObject as? URL {
                return url;
            }
            return URL(fileURLWithPath: exportItem.representedObject as! String);
        });
        
        let groupPath = self.localFolderPathForGroup(name);
        let groupURL = URL(fileURLWithPath: groupPath, isDirectory: true)
        for item in itemURLS{
            let fileName = item.lastPathComponent
            try? FileManager().moveItem(at: item, to: groupURL.appendingPathComponent(fileName))
        }
        let currentPath = groupPath
        if let newPath = (currentPath as NSString).appendingPathExtension("zip")
        {
            let newPathURL = URL(fileURLWithPath: newPath, isDirectory: true)
            let success = SSZipArchive.createZipFile(atPath: newPath,
                                                                   withContentsOfDirectory: currentPath,
                                                                   keepParentDirectory: true);
            if success{
                let exportItem = FTExportItem();
                exportItem.fileName = name
                let url = URL(fileURLWithPath: newPath);
                exportItem.exportFileName = url.lastPathComponent;
                exportItem.representedObject = newPathURL.path;
                exportItem.isGroupItem = true;
                return exportItem
            }
            return nil
        }
        return nil
    }
    private func createExportItemFor(item : FTItemToExport,completion : @escaping (FTExportItem?,NSError?) -> Void){
        let contentGen = self.contentGenerator(forFormat: target.properties.exportFormat,
                                               onViewController: self.presentingController);
        self.currentContentGen = contentGen;
        if let progressToAdd = self.currentContentGen?.progress {
            self.progress.addChild(progressToAdd, withPendingUnitCount: 1)
        }
        contentGen.generateContent(forItem: item,
                                   onCompletion:
            { (exportItem, error,_) in
                self.isProcessInProgress = false;
                self.currentContentGen = nil;
                completion((error == nil) ? exportItem : nil,error);
        });
    }
    fileprivate func destoryHandlers()
    {
        self.completionHandler = nil;
    }
    
    fileprivate func updateProgress()
    {
        let totalCount = self.progress.totalUnitCount;
        let completedCount = self.progress.completedUnitCount + 1;

        var progressInfo = NSLocalizedString("Generating", comment: "Generating...");
        if(totalCount > 1) {
            let str = String.init(format: NSLocalizedString("NofNAlt", comment: "%d of %d"), completedCount,totalCount);
            progressInfo = progressInfo.appending("\n").appending(str);
        }
        
        self.progress.localizedDescription = progressInfo;
    }

    //MARK:- FTContentGeneratorProtocol
    func generateContent(forItem item: FTItemToExport,
                                  onCompletion completion: @escaping InternalCompletionHandler) {
        //subclass should override
    }
    
    var preferedFileName: String
    {
        var preferedName = NSLocalizedString("Untitled", comment: "Untitled");
        if let filename = self.currentItem?.preferedFileName
        {
            preferedName = filename;
        }
        return preferedName;
    }

    func resumeProcess() {
         if(self.exportPaused) {
             self.generate();
         }
     }

     func pauseProcess() {
         while (self.isProcessInProgress) {
             sleep(UInt32(0.05));
         }
     }
}
//MARK:- Private Pause / Resume
private extension FTExportContentGenerator
{
    func pauseExportOperations()
    {
        if let currentGenerator = self.currentContentGen {
            currentGenerator.pauseProcess();
        } else {
            self.pauseProcess();
        }
        endBackgroundTask(self.bgTask);
    }
    
    func resumeExportOperations()
    {
        self.bgTask = startBackgroundTask();
        if(nil != self.currentContentGen) {
            self.currentContentGen!.resumeProcess();
        } else {
            self.resumeProcess();
        }
    }
}
