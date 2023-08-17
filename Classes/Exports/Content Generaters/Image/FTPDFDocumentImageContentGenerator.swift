//
//  FTPDFDocumentImageContentGenerator.swift
//  Noteshelf
//
//  Created by Siva on 23/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import ZipArchive
import FTCommon

class FTPDFDocumentImageContentGenerator: FTPDFDocumentContentGenerator {
    fileprivate var itemsToUpload = [FTExportItem]();
    fileprivate var exportItem : FTExportItem?;
    
    private var exportAsZip = false;

    //MARK:- Init
    override init() {
        super.init();
    }
    
    override func generateContent(forItem item: FTItemToExport,
                                  onCompletion completion: @escaping InternalCompletionHandler)
    {
        self.currentItem = item;
        if let exportPages = self.target.pages,exportPages.count > 1 {
            self.exportAsZip = (self.target.pagesaveType == .share ? true : false);
        }
        if self.target.itemsToExport.count > 1 {
            self.exportAsZip = (self.target.pagesaveType == .share ? true : false);
        }
        #if targetEnvironment(macCatalyst)
            self.exportAsZip = (self.target.pagesaveType == .share ? true : false);
        #endif
        self.internalCompletionHandler = completion;
        
        self.preprocessGeneration { (error) in
            if(nil != error) {
                self.finalizeProcess();
                completion(nil,error,false);
                return;
            }
            if(nil == self.exportItem) {
                self.exportItem = FTExportItem.init();
                self.exportItem!.fileName = self.preferedFileName;
                let path = self.localFolderPath();
                try? FileManager.default.removeItem(atPath: path);
                try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil);
                self.exportItem!.exportFileName = (path as NSString).lastPathComponent;
                self.exportItem!.representedObject = path;
            }
            
            var start = 0;
            if self.exportPaused {
                start = Int(self.progress.completedUnitCount);
            }
            
            let totalPages = self.pagesToExport.count;
            self.progress.totalUnitCount = Int64(totalPages);
            if(self.exportAsZip) {
                self.progress.totalUnitCount = self.progress.totalUnitCount + 1;
            }
            
            for index in start..<totalPages
            {
                if self.progress.isCancelled
                {
                    self.finalizeProcess();
                    completion(nil,NSError.exportCancelError(),true);
                    return;
                }
                self.isProcessInProgress = true;
                
                if self.progress.isPaused {
                    self.exportPaused = true;
                    self.isProcessInProgress = false;
                    return;
                }
                
                autoreleasepool {
                    let page = self.pagesToExport[index] ;
                    
                    var pdfScale: CGFloat = 1.0;
                    let pageRect = self.pageRectForPDFPage(page, scale: &pdfScale);
                    
                    let screenScale = CGFloat(2)
                    var imageSize = pageRect.size;
                    imageSize = CGSize.aspectFittedSize(imageSize, min: CGSize.init(width: minImageExportSize,
                                                                                    height: minImageExportSize));
                    var image = FTPDFExportView.snapshot(forPage: page,
                                                         size: imageSize,
                                                         screenScale:screenScale,
                                                         shouldRenderBackground:!self.target.properties.hidePageTemplate);
                    if self.target.pagesaveType == .savetoCameraRoll{
                        let photoSaver = FTPhotoSaver()
                        photoSaver.writeToPhotoAlbum(image: image ?? UIImage(), completion: completion)
                    }else{
                        if let _image = image, self.target.properties.includesPageFooter {
                                var textColor = UIColor.black
                                if let _page = page as? FTPageBackgroundColorProtocol,
                                    page.templateInfo.isTemplate,
                                   let bgcolor = _page.pageBackgroundColor
                                {
                                    textColor = bgcolor.blackOrWhiteContrastingColor() ?? UIColor.black
                                }
                                image = FTPDFExportView.renderFooterInfo(image: _image, screenScale:screenScale, title: self.preferedFileName, currentPage: index+1, totalPages: totalPages, textColor: textColor)
                        }
                        let destPath = self.localFilePathWithExtension();
                        if let image = image, let imageData = image.pngData(), ((try? imageData.write(to: URL(fileURLWithPath: destPath), options: [.atomic])) != nil) {
                            let item = FTExportItem();
                            item.fileName = self.preferedFileName;
                            let url = URL(fileURLWithPath: destPath);
                            item.exportFileName = url.lastPathComponent;
                            item.representedObject = destPath;
                            if let tags = (page as? FTPageTagsProtocol)?.tags() {
                                item.tags = NSMutableSet.init(array: tags);
                            }
                            self.itemsToUpload.append(item);
                        }
                        page.unloadContents();
                        self.isProcessInProgress = false;
                    }
                }
                self.progress.completedUnitCount += 1;
            }
            if self.target.pagesaveType == .share{
                self.exportPaused = false;

                self.pagesToExport.forEach { (eachPage) in
                    (eachPage as? FTNoteshelfPage)?.unloadPDFContentsIfNeeded();
                }

                var isSuccess = true;
                if(self.exportAsZip) {

                    let currentPath = self.exportItem!.representedObject as! String;
                    let newPath = (currentPath as NSString).appendingPathExtension("zip");
                    let success = SSZipArchive.createZipFile(atPath: newPath!,
                                                             withContentsOfDirectory: currentPath,
                                                             keepParentDirectory: true);
                    self.progress.completedUnitCount += 1;

                    if(!success) {
                        isSuccess = false;
                    }
                    else {
                        self.exportItem?.representedObject = newPath;
                    }
                }

                runInMainThread {
                    if(isSuccess) {
                        self.finalizeProcess();
                        self.exportItem?.childItems = self.itemsToUpload;
                        completion(self.exportItem,nil,false);
                    }
                    else {
                        completion(nil,NSError.init(domain: "NSExport", code: 103, userInfo: nil),false);
                    }
                };
            }
        }
    }
}
