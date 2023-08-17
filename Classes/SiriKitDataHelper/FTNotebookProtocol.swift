//
//  FTNotebookProtocol.swift
//  Noteshelf
//
//  Created by Matra on 11/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon
import FTNewNotebook

enum SiriResult : Int{
    case success
    case failure
}

protocol FTNotebookProtocol {
    var title : String {get set}
    var groupName : String? {get set}
    var content : AnyObject? {get set}
    var identifier : String {get set}
}


class FTNotebookClass: NSObject, FTNotebookProtocol {
    
    var title: String = ""
    
    var groupName: String?
    
    var content: AnyObject?
    
    var identifier: String = ""
        
    var numberOfCollection = -1
    
    var allShelfItems = [FTShelfItemProtocol]()
    
      
    func createNewNotebook(titleString : String, groupName:String? , completion: @escaping (_ result : SiriResult, _ url : String?) -> Void) {

        let paperThemeLibrary = FTThemesLibrary(libraryType: FTNThemeLibraryType.papers)
        guard let defaultPaper = paperThemeLibrary.getDefaultTheme(defaultMode: .quickCreate) as? FTPaperThemeable else {
            fatalError(" Did not receive paper theme when requested")
        }
        if nil == defaultPaper.customvariants{
            defaultPaper.setPaperVariants(FTBasicTemplatesDataSource.shared.getDefaultVariants())
        }
        if let theme = defaultPaper as? FTTheme {
            Task {
                let generator = FTAutoTemplateGenerator.autoTemplateGenerator(theme: theme, generationType: .template)
                do {
                    let documentInfo = try await generator.generate()
                    let tempDocURL = FTDocumentFactory.tempDocumentPath(FTUtils.getUUID());
                    let ftdocument = FTDocumentFactory.documentForItemAtURL(tempDocURL);

                    let defaultCover = self.quickCreateDefaultCoverTheme();
                    documentInfo.footerOption = theme.footerOption
                    documentInfo.annotationInfo = theme.annotationInfo
                    documentInfo.isNewBook = true
                    documentInfo.coverTemplateImage = UIImage.init(contentsOfFile: defaultCover.themeTemplateURL().path);
                    ftdocument.createDocument(documentInfo) { (error, success) in
                        if(error == nil) {
                            self.shelfCollections(completion: { (shelfCollections) in
                                self.lastSelectedCollection(collections: shelfCollections, onCompeltion: { (shelfCollection) in
                                    guard let shelfCol = shelfCollection else {
                                        completion(.failure, nil)
                                        return;
                                    }

                                    func adddocument(group : FTGroupItemProtocol?)
                                    {
                                        shelfCol.addShelfItemForDocument(ftdocument.URL,
                                                                         toTitle: titleString,
                                                                         toGroup: group,
                                                                         onCompletion: { (error, item) in
                                            if(nil != error) {
                                                completion(.failure, nil)
                                            }
                                            else{
                                                completion(.success, item?.URL.relativePath)
                                            }
                                        });
                                    }
                                    shelfCol.shelfItems(.byName,
                                                        parent: nil,
                                                        searchKey: nil,
                                                        onCompletion:
                                                            { (items) in
                                        if let groupTitle = groupName {
                                            let groupItem = shelfCollection?.groupItemWithName(title: groupTitle);
                                            if(nil == groupItem) {
                                                shelfCol.createGroupItem(groupTitle,
                                                                         inGroup: nil,
                                                                         shelfItemsToGroup: nil,
                                                                         onCompletion: { (error, groupItem) in
                                                    adddocument(group: groupItem);
                                                });
                                            }
                                            else {
                                                adddocument(group: groupItem);
                                            }
                                        }
                                        else {
                                            adddocument(group: nil);
                                        }
                                    });
                                })
                            })
                        }
                        else {
                            completion(.failure, nil)
                        }
                    }
                }
                catch {
                    completion(.failure, nil)
                }

            }
        }
    }
    
    //MARK:- Cover
    internal func quickCreateDefaultCoverTheme() -> FTThemeable {
        let coverThemeLibrary =  FTThemesLibrary(libraryType: FTNThemeLibraryType.covers) //FTNThemesLibrary(libraryType: FTNThemeLibraryType.covers);
        let isRandomCoverEnabled = FTUserDefaults.isRandomKeyEnabled()
        var defaultCover: FTThemeable;
        if isRandomCoverEnabled {
            defaultCover = coverThemeLibrary.getRandomCoverTheme();
        }
        else {
            defaultCover = coverThemeLibrary.getDefaultTheme(defaultMode: .quickCreate);
            //if defaultCover.overlayType == 1 {
                defaultCover = coverThemeLibrary.getRandomCoverTheme();
            //}
        }
        return defaultCover;
    }
    
    //AMRK: - Search notebooks
    func searchNotebooksFor(titleString : String, completion : @escaping ([FTNotebookProtocol]) -> Void) {
        self.shelfCollections { (shelfsCollections) in
            if shelfsCollections.count > 0 {
                var shelfItemCollections = [FTShelfItemCollection]();
                
                for collection in shelfsCollections {
                    shelfItemCollections.append(contentsOf: collection.categories);
                }
                self.getAllShelfItems(shelfItemCollections, searchKey: titleString, completion: { (allItems) in
                    self.notebookObjects(shelfItems: allItems, completion: { (notebooks) in
                        completion(notebooks)
                    })
                })
            } else {
                completion([FTNotebookProtocol]())
            }
        }
        
    }
    
    func getAllShelfItems(_ shelfItemCollections : [FTShelfItemCollection] , searchKey: String , completion : @escaping ([FTShelfItemProtocol]) -> Void) {
        if numberOfCollection < shelfItemCollections.count - 1 {
            numberOfCollection += 1
        }else{
            completion(allShelfItems)
            return
        }
        let category = shelfItemCollections[numberOfCollection]
        category.shelfItems(.byName, parent: nil, searchKey: searchKey) { (items) in
            self.allShelfItems.append(contentsOf: items)
            self.getAllShelfItems(shelfItemCollections, searchKey: searchKey, completion: completion)
            
        }
    }
    
    fileprivate func lastSelectedCollection(collections : [FTShelfCategoryCollection], onCompeltion : @escaping (FTShelfItemCollection?) -> ()) {
        var collectionToShow : FTShelfItemCollection?;
        var collectionName = FTUserDefaults.lastSelectedCollection()
        if collectionName != nil {
            collectionName = collectionName!.deletingPathExtension
            for categoryCollection in collections {
                for category in categoryCollection.categories {
                    if(category.displayTitle == collectionName) {
                        if category.collectionType == .default || category.collectionType == .migrated{
                            collectionToShow = category;
                        }else{
                            collectionToShow = collections.first?.categories.first
                        }
                        break;
                    }
                }
            }
        }else {
            collectionToShow = collections.first?.categories.first
        }
        if collectionToShow == nil { collectionToShow = collections.first!.categories.first! }
        onCompeltion(collectionToShow)
    }
    func shelfCollections(completion : @escaping ([FTShelfCategoryCollection]) -> Void) {
        FTNoteshelfDocumentProvider.shared.updateProviderForSiri { _ in
            FTNoteshelfDocumentProvider.shared.shelfs({ (shelfCollections) in
                completion(shelfCollections)
            })
        }
    }
    func notebookObjects(shelfItems : [FTShelfItemProtocol], completion : @escaping ([FTNotebookProtocol]) -> Void) {
        var notebooks = [FTNotebookProtocol]()
        for shelfItem in shelfItems {
            if(shelfItem.type != RKShelfItemType.group) {
                let notebook = FTNotebookClass()
                notebook.title = shelfItem.title
                notebook.identifier = shelfItem.URL.path
                if let parent = shelfItem.parent {
                    notebook.groupName = parent.displayTitle
                }
                notebooks.append(notebook)
            }
        }
        completion(notebooks)
    }
}
