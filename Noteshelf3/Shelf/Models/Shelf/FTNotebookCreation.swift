//
//  FTNotebookCreation.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 10/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import FTNewNotebook
import FTCommon

struct FTNewNotebookDetails {
    var coverTheme: FTThemeable?
    var paperTheme: FTThemeable?
    var documentPin: FTDocumentPin?
    var title: String
}
class FTNotebookCreation: NSObject {

    private var isBackupEnabled: Bool = FTCloudBackUpManager.shared.activeCloudBackUpManager?.isLoggedIn() ?? false
    private var isEvernoteSyncEnabled = FTENPublishManager.shared.isLoggedin()
    private var isENBusiness : Bool = false;

    func createNewNotebookInside(collection: FTShelfItemCollection,
                                 group: FTGroupItemProtocol?,
                                 notebookDetails: FTNewNotebookDetails,
                                 mode:ThemeDefaultMode = .basic,
                                 completion: @escaping (NSError?, _ shelfItem:FTShelfItemProtocol?) -> ()){
        if let theme = notebookDetails.paperTheme as? FTTheme, let cover = notebookDetails.coverTheme {
            //Create a file named FTAuoTemplateGenerator.
            //on FTAuoTemplateGenerator have a factory method to retun particular operation class.
            //on the object call generate(onCompletion : (FTDocumentInfo?,Error?) -> ()) -> Progress
            Task {
                var title = notebookDetails.title
                title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                if title.isEmpty {
                    title = NSLocalizedString("Untitled", comment: "Untitled")
                }
                let generator = FTAutoTemplateGenerator.autoTemplateGenerator(theme: theme , generationType: .template)
                do {
                    let docInfo = try await generator.generate()
                    var shelfItemImage: UIImage!
                    if let image = UIImage(contentsOfFile: cover.themeTemplateURL().path){
                        shelfItemImage = image
                    }
                    else {
                        shelfItemImage = cover.themeThumbnail()
                    }

                    //docInfo.rootViewController = self.presentingViewController
                    docInfo.overlayStyle = .clearWhite
                    docInfo.coverTemplateImage = shelfItemImage
                    docInfo.pinModel = notebookDetails.documentPin
                    docInfo.isCover = cover.hasCover
                    docInfo.isNewBook = true
                    docInfo.isTemplate = true
                    docInfo.coverTemplateUrl = cover.themeFileURL.appendingPathComponent("template.pdf")
                    let tempDocURL = FTDocumentFactory.tempDocumentPath(FTUtils.getUUID())
                    let ftdocument = FTDocumentFactory.documentForItemAtURL(tempDocURL)
                    ftdocument.createDocument(docInfo){ (error, success) in
                        if(error == nil) {
                            let shelfImageURL = ftdocument.URL.appending(path:"cover-shelf-image.png");
                            let shelfImage = UIImage(contentsOfFile: shelfImageURL.path(percentEncoded:false));
                            
                            let createBlock: ()->() = {
                                collection.addShelfItemForDocument(ftdocument.URL, toTitle: title, toGroup: group, onCompletion: { (error, item) in
                                    if(nil != error) {
                                        completion(error,item)
                                        return
                                    }

                                    FTCLSLog("Import: document created:\(item!.URL.lastPathComponent)")
                                    if let documentPin = notebookDetails.documentPin {
                                        FTBiometricManager.keychainSetIsTouchIDEnabled(documentPin.isTouchIDEnabled, withPin: documentPin.pin, forKey: ftdocument.documentUUID)
                                    }

                                    item?.documentUUID = ftdocument.documentUUID
                                    FTURLReadThumbnailManager.sharedInstance.addImageToCache(image: shelfImage, url: item!.URL)
                                    if let coverTheme = cover as? FTCoverTheme,mode == .basic {
                                        let coverLibrary =  FTThemesLibrary(libraryType: FTNThemeLibraryType.covers)
                                        coverLibrary.setDefaultTheme(coverTheme,defaultMode: .basic, withVariants: nil)
                                    }

                                    let paperLibrary = FTThemesLibrary(libraryType: FTNThemeLibraryType.papers)
                                    if let paperTheme = theme as? FTPaperTheme,mode == .basic {
                                        if let variants = paperTheme.customvariants {
                                            paperLibrary.setDefaultTheme(paperTheme,defaultMode: .basic, withVariants:variants)
                                        } else {
                                            paperLibrary.setDefaultTheme(paperTheme,defaultMode: .basic, withVariants: nil)
                                        }
                                    }

                                    if nil == error && self.isEvernoteSyncEnabled {
                                        runInMainThread {
                                            FTENPublishManager.recordSyncLog("User enabled Sync on notebook: \(item!.title)")

                                            let evernotePublishManager = FTENPublishManager.shared
                                            evernotePublishManager.enableSync(for: item!)
                                            evernotePublishManager.updateSyncRecord(forShelfItem: item!, withDocumentUUID: ftdocument.documentUUID)
                                            evernotePublishManager.updateSyncRecord(forShelfItemAtURL: item!.URL, withDeleteOption: true, andAccountType: (self.isENBusiness ? EvernoteAccountType.evernoteAccountBusiness : EvernoteAccountType.evernoteAccountPersonal))
                                        }
                                    }
                                    completion(error,item)
                                })
                            }
                            createBlock()
                        }
                        else {
                            completion(error,nil)
                        }
                    }
                } catch {
                    completion(NSError(domain: "Noteshelf.notebokCreation", code: 800), nil)
                    fatalError("Error in generating")
                }
            }
        }
    }
    func quickCreateNotebook(collection: FTShelfItemCollection,
                             group: FTGroupItemProtocol?,
                             completion: @escaping (NSError?, _ shelfItem:FTShelfItemProtocol?) -> ()) {
        let paperThemeLibrary = FTThemesLibrary(libraryType:FTNThemeLibraryType.papers)
        if let defaultPaper = paperThemeLibrary.getDefaultTheme(defaultMode: .quickCreate) as? FTPaperThemeable {
            if nil == defaultPaper.customvariants{
                defaultPaper.setPaperVariants(FTBasicTemplatesDataSource.shared.fetchSelectedVaraintsForMode(.quickCreate))
            }
            if let theme = defaultPaper as? FTTheme {
                let generator = FTAutoTemplateGenerator.autoTemplateGenerator(theme: theme, generationType: .template)
                Task {
                    do {
                        let documentInfo = try await generator.generate()
                        let tempDocURL = FTDocumentFactory.tempDocumentPath(FTUtils.getUUID());
                        let ftdocument = FTDocumentFactory.documentForItemAtURL(tempDocURL);

                        let defaultCover = FTThemesLibrary(libraryType: .covers).getDefaultTheme(defaultMode: .quickCreate)
                        //documentInfo.rootViewController = self;
                        documentInfo.footerOption = theme.footerOption
                        documentInfo.annotationInfo = theme.annotationInfo
                        documentInfo.coverTemplateUrl = defaultCover.themeFileURL.appendingPathComponent("template.pdf")
                        documentInfo.isCover = defaultCover.hasCover
                        let templatePath = defaultCover.themeTemplateURL().path
                        documentInfo.coverTemplateImage = UIImage.init(contentsOfFile: templatePath)
                        ftdocument.createDocument(documentInfo) { (error, _) in
                            if(error == nil) {
                                let shelfImageURL = ftdocument.URL.appending(path:"cover-shelf-image.png");
                                let shelfImage = UIImage(contentsOfFile: shelfImageURL.path(percentEncoded:false));

                                let createBlock: () -> () = {
                                    collection.addShelfItemForDocument(ftdocument.URL, toTitle: NSLocalizedString("quickNotesSave.quickNote", comment: "Quick Note"), toGroup: group, onCompletion: { (error, item) in
                                        if(nil != error) {
                                            completion(error,item)
                                        }
                                        else {
                                            FTURLReadThumbnailManager.sharedInstance.addImageToCache(image: shelfImage, url: item!.URL)
                                            if let pinToSet = documentInfo.pinModel?.pin {
                                                FTBiometricManager.keychainSetIsTouchIDEnabled(documentInfo.pinModel!.isTouchIDEnabled,
                                                                                             withPin: pinToSet,
                                                                                             forKey: ftdocument.documentUUID);
                                            }

                                            //****************************** AutoBackup & AutoPublish
                                            //Amar: Commented below code to avoid ununcessary adding the quick note to EN list without knowing if it is going to be deleted of not
//                                            FTENPublishManager.applyDefaultBackupPreferences(forItem: item, documentUUID: ftdocument.documentUUID)
                                            //******************************
                                            completion(error,item)
                                        }
                                    });
                                }
                                createBlock()
                            }
                            else {
                                completion(error,nil)
                            }
                        }
                    } catch {
                        completion(NSError(domain: "Noteshelf.notebokCreation", code: 800), nil)
                    }
                }
            }
        }
    }
}
