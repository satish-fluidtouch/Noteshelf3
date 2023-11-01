//
//  FTThumbnailableCollectionDelegate.swift
//  Noteshelf
//
//  Created by Siva on 28/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTFinderThumbnailsActionDelegate: FTCurrentShelfItemDelegate  {
    func currentPage(in finderViewController: FTFinderViewController) -> FTThumbnailable?;
    //Editing
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectInsertAboveForPage page: FTPageProtocol?);
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectInsertBelowForPage page: FTPageProtocol?);
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectRemovePagesWithIndices indices: IndexSet);
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectPages pages: NSSet, toMoveTo shelfItem: FTShelfItemProtocol);
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectShareWithPages pages: NSSet, exportTarget: FTExportTarget?)
    func shouldShowMoveOperation(in finderViewController: FTFinderViewController) -> Bool;
    func finderViewController(_ finderViewController: FTFinderViewController, didMovePageAtIndex fromIndex: Int, toIndex: Int);
    
    func finderViewController(_ contorller : FTFinderViewController,
                                 searchForKeyword searchKey : String,
                                 onFinding : (() -> ())?,
                                 onCompletion : (()->())?);
    
    //Share
    func finderViewController(didSelectPageAtIndex  index: Int);

    //Rotate
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectRotatePages  pages: NSSet);
    
    //Paste
    func finderViewController(_ finderViewController: FTFinderViewController, pastePagesAtIndex index: Int?);

    func finderViewController(bookMark page: FTThumbnailable)
    func finderViewController(didSelectDuplicate pages: [FTThumbnailable], onCompletion: (()->())?)
    func finderViewController(_ finderVc: FTFinderViewController, didSelectTag pages: NSSet, from source: UIView)
    func didBeginSaveFinderPagesToCameraRoll(_ properties: FTExportProperties, option: FTShareOption)
    func didInsertPageFromFinder(_ item: FTPageType)
    func cancelFinderSearchOperation()
}


extension  FTFinderThumbnailsActionDelegate {
    func didBeginSaveFinderPagesToCameraRoll(_ properties: FTExportProperties, option: FTShareOption)
    {
        //Implement if needed
    }
    
    func didInsertPageFromFinder(_ item: FTPageType) {
        //Implement if needed
    }
}
