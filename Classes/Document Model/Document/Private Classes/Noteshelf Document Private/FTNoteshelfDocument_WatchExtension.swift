//
//  FTNoteshelfDocument_WatchExtension.swift
//  Noteshelf
//
//  Created by Amar on 13/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTNewNotebook

@objc class FTAudioFileToImport : NSObject
{
    var url : URL;
    var fileName : String?
    var date : Date!
    
    public init(withURL url: URL,date : Date,fileName : String?) {
        self.url = url;
        self.fileName = fileName;
        self.date = date;
        super.init();
    }
    
    public init(withURL url: URL) {
        self.url = url;
        var creationDate : AnyObject?;
        _ = try? (url as NSURL).getPromisedItemResourceValue(&creationDate, forKey: URLResourceKey.creationDateKey);
        self.date = (creationDate as? Date) != nil ? creationDate as! Date : Date()
        self.fileName = url.deletingPathExtension().lastPathComponent
        super.init()
    }
}

@objc protocol FTDocumentCreateWatchExtension : NSObjectProtocol {
    func createWatchRecordingDocument(_ info : FTDocumentInputInfo,
                                      audioURLS : [FTAudioFileToImport]?,
                                      onCompletion : @escaping  ((NSError?,Bool)->Void));
    func insertNewPageForWatchAudio(_ urls : [FTAudioFileToImport],
                                    atIndex index : Int,
                                    onCompletion :@escaping ((FTPageProtocol?,Error?)->Void));
    func addAudioAnnotations(urls : [FTAudioFileToImport],
                             toPage : FTPageProtocol,
                             onCompletion : @escaping ([FTAnnotation])->Void);
}

extension FTNoteshelfDocument : FTDocumentCreateWatchExtension {
    
    //add coverTemplateImage
    func createWatchRecordingDocument(_ info : FTDocumentInputInfo,
                                      audioURLS : [FTAudioFileToImport]?,
                                      onCompletion : @escaping  ((NSError?,Bool)->Void))
    {
        
        guard let paperTheme = self.deviceSpecificWatchPaperTemplate(pageRect: CGRect.null) as? FTPaperThemeable else {
            return
        }
        if nil == paperTheme.customvariants{
            paperTheme.setPaperVariants(FTBasicTemplatesDataSource.shared.getDefaultVariants())
        }
        if let theme = paperTheme as? FTTheme {
            Task {
                let generator = FTAutoTemplateGenerator.autoTemplateGenerator(theme: theme, generationType: .template)
                do {
                    let documentInfo = try await generator.generate()
                    documentInfo.footerOption = theme.footerOption
                    documentInfo.isNewBook = true
                    documentInfo.coverTemplateImage = info.coverTemplateImage
                    documentInfo.insertAt = 0
                    self.createDocument(documentInfo) { (error, success) in
                        if(nil != error) {
                            DispatchQueue.main.async {
                                onCompletion(error,success);
                            }
                        }
                        else {
                            self.openDocument(purpose: .write,completionHandler: { (openSuccess,_) in
                                if(!openSuccess) {
                                    DispatchQueue.main.async {
                                        onCompletion(FTDocumentCreateErrorCode.error(.openFailed),openSuccess);
                                    }
                                }
                                else {
                                    if audioURLS == nil {
                                        onCompletion(nil,true);
                                        return
                                    }
                                    let page = self.pages().first;
                                    if(nil != page) {
                                        let annotations = [FTAnnotation]();
                                        self.addAudioAnnotations(urls: audioURLS!,
                                                                 info: documentInfo,
                                                                 index : Int(0),
                                                                 toPage: page!,
                                                                 annotations: annotations,
                                                                 onCompletion:
                                                                    { (annotations) in
                                            self.saveDocument(completionHandler: { (saveSuccess) in
                                                self.closeDocument(completionHandler: { (success) in
                                                    DispatchQueue.main.async {
                                                        onCompletion(nil,saveSuccess);
                                                    }
                                                })
                                            })

                                        })
                                    }
                                }
                            })
                        }
                    }
                }
                catch {
                    onCompletion(nil,false)
                }
            }
        }
    }
    
    func insertNewPageForWatchAudio(_ urls : [FTAudioFileToImport],
                                    atIndex index : Int,
                                    onCompletion :@escaping ((FTPageProtocol?,Error?)->Void))
    {
        var pageCopy : FTPageProtocol!;
        if(index >= self.pages().count) {
            pageCopy = self.pages().last;
        }
        else {
            pageCopy = self.pages()[max(0, index-1)];
        }
        let pageRect = pageCopy.pdfPageRect;
        guard let paperTheme = self.deviceSpecificWatchPaperTemplate(pageRect: pageRect) as? FTPaperThemeable else
        {
            return
        }
        if nil == paperTheme.customvariants{
            paperTheme.setPaperVariants(FTBasicTemplatesDataSource.shared.getDefaultVariants())
        }
        if let theme = paperTheme as? FTTheme{
            Task {
                let generator = FTAutoTemplateGenerator.autoTemplateGenerator(theme: theme, generationType: .template)
                do {
                    let documentInfo = try await generator.generate()
                    documentInfo.footerOption = theme.footerOption
                    documentInfo.annotationInfo = theme.annotationInfo
                    documentInfo.isNewBook = true
                    documentInfo.insertAt = index
                    self.insertFile(documentInfo) { (error, success) in
                        if(nil != error) {
                            onCompletion(nil,error);
                        }
                        else {
                            let copiedPage = self.pages()[index];
                            let annotations = [FTAnnotation]();
                            self.addAudioAnnotations(urls: urls,
                                                     info: documentInfo,
                                                     index : Int(0),
                                                     toPage: copiedPage,
                                                     annotations: annotations,
                                                     onCompletion: { (annotations) in
                                onCompletion(copiedPage,nil);
                            });
                        }
                    };
                }
                catch {
                    fatalError("Error in generation")
                }
            }
        }
    }

    private func quickCreateDefaultCoverTheme() -> FTThemeable {
        let coverThemeLibrary = FTThemesLibrary(libraryType: FTNThemeLibraryType.covers)
        let isRandomCoverEnabled = FTUserDefaults.isRandomKeyEnabled()
        let defaultCover: FTThemeable!;
        if isRandomCoverEnabled {
            defaultCover = coverThemeLibrary.getRandomCoverTheme();
        }
        else {
            defaultCover = coverThemeLibrary.getDefaultTheme(defaultMode: .quickCreate);
        }
        return defaultCover;
    }
    func addAudioAnnotations(urls : [FTAudioFileToImport],
                             toPage : FTPageProtocol,
                             onCompletion : @escaping ([FTAnnotation])->Void) {
        self.addAudioAnnotations(urls: urls,
                                 info:nil,
                                 index : Int(0),
                                 toPage: toPage,
                                 annotations: [FTAnnotation](),
                                 onCompletion: onCompletion);
    }

    private func addAudioAnnotations(urls : [FTAudioFileToImport],
                                     info : FTDocumentInputInfo?,
                                     index : Int,
                                     toPage : FTPageProtocol,
                                     annotations : [FTAnnotation],
                                     onCompletion : @escaping ([FTAnnotation])->Void)
    {
        var localAnnotations = annotations;
        if(index >= urls.count) {
            if let annInfo = info?.annotationInfo {
                if let titleAnnotation = annInfo["titleAnnotation"] as? [String : Any] {
                    var title = urls.first?.fileName;
                    if(nil == title) {
                        title = NSLocalizedString("AppleWatchRecording", comment: "Apple Watch Recording");
                    }
                    title = title?.appending("\n");
                    
                    let date = urls.first!.date;
                    let subtitle = date?.shelfShortStyleFormat();
                    
                    let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle;
                    paragraph.paragraphSpacing = 5;
                    
                    var titleFontSize = CGFloat(24);
                    var subtitleFontSize = CGFloat(16);
                    if(UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone) {
                        titleFontSize = CGFloat(16);
                        subtitleFontSize = CGFloat(13);
                    }
                    
                    let titleAttributes = [NSAttributedString.Key.font : UIFont.appFont(for: .bold, with: titleFontSize),
                                           NSAttributedString.Key.foregroundColor : UIColor.init(hexString: "383838"),
                                           NSAttributedString.Key.paragraphStyle : paragraph];
                    let subTitleAttributes = [NSAttributedString.Key.font : UIFont.appFont(for: .regular, with: subtitleFontSize),
                                              NSAttributedString.Key.foregroundColor : UIColor.init(hexString: "383838"),
                                              NSAttributedString.Key.paragraphStyle : NSParagraphStyle.default] ;
                    let titleAttribute = NSMutableAttributedString.init(string: title!, attributes: titleAttributes as [NSAttributedString.Key : Any]);
                    let subtitleAttribute = NSAttributedString.init(string: subtitle!, attributes: subTitleAttributes as [NSAttributedString.Key : Any]);
                    let annotation = FTTextAnnotation.init(withPage : toPage);
                    annotation.boundingRect = NSCoder.cgRect(for: titleAnnotation["boundingRect"] as! String);
                    titleAttribute.append(subtitleAttribute);
                    annotation.attributedString = titleAttribute;
                    localAnnotations.append(annotation);
                }
            }
            
            (toPage as? FTPageUndoManagement)?.addAnnotations(localAnnotations, indices: nil);
            onCompletion(localAnnotations);
            return;
        }
        let item = urls[index];
        FTAudioAnnotation.annotationWithFilePath(item.url.path,
                                                   page: toPage) { (annotation) in
                                                    if(nil != annotation) {
                                                        var rect = annotation!.boundingRect;
//                                                        if let annInfo = info?.annotationInfo {
//                                                            if  let audioInfo = annInfo["audioAnnotation"] as? [String : Any] {
//                                                                let frame = NSCoder.cgRect(for: audioInfo["boundingRect"] as! String)
//                                                                rect.origin = frame.origin;
//                                                            }
//                                                        }
                                                        rect = (toPage as! FTPageAnnotationFindBounds).findDefaultAudioRect(current: rect);
                                                        annotation?.boundingRect = rect;
                                                        localAnnotations.append(annotation!)
                                                    }
                                                    self.addAudioAnnotations(urls: urls,
                                                                             info : info,
                                                                             index : index + 1,
                                                                             toPage : toPage,
                                                                             annotations: localAnnotations,
                                                                             onCompletion: onCompletion);
        }
    }
    
    //CGRect.Null for new document
    private func deviceSpecificWatchPaperTemplate(pageRect : CGRect) -> FTTheme
    {
        var templateName = "WatchTemplate";
        var rectToConsider = pageRect;
        if(rectToConsider.isNull) {
            rectToConsider = UIScreen.main.bounds;
        }
        
        if(rectToConsider.width > rectToConsider.height) {
            templateName = templateName.appending("_Landscape");
        }
        
        if(UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone) {
            templateName = templateName.appending("_iPhone");
        }
        let defaultTemplate = templateName;
        templateName = templateName.appending("_\(FTUtils.currentLanguage())");
        
        var url = Bundle.main.url(forResource: templateName, withExtension: "nsp", subdirectory: "StockPapers_Watch.bundle");
        if(nil == url) {
            url = Bundle.main.url(forResource: defaultTemplate, withExtension: "nsp", subdirectory: "StockPapers_Watch.bundle");
        }
        let theme = FTTheme.theme(url: url!, themeType: FTSelectedThemeType.papers);
        return theme!;
    }
}
