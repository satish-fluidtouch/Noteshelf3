//
//  FTSidePanelItemsViewController.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 24/03/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

protocol FTShelfCategoryDelegate : NSObjectProtocol{
    func shelfCategory(_ viewController : UIViewController, didSelectCollection: FTShelfItemCollection);
    func shelfCategory(_ viewController : UIViewController, didRenameCollection: FTShelfItemCollection);
    func shelfCategory(_ viewController : UIViewController, didAddedCollection: FTShelfItemCollection);
    func shelfCategory(_ viewController : UIViewController, willDeleteCollection : FTShelfItemCollection);
    func shelfCategory(_ viewController : UIViewController, didDeleteCollection : FTShelfItemCollection);

    func shelfCategory(_ viewController: UIViewController, didSelectShelfItem : FTShelfItemProtocol, inCollection: FTShelfItemCollection?);
    func shelfCategory(_ viewController : UIViewController,move items:[FTShelfItemProtocol], toCollection : FTShelfItemCollection);
    func performToolbarAction(_ viewController : UIViewController, actionType: FTCategoryToolbarActionType, actionView : UIView)
    func didTapOnCategoriesOverlay()
    //For iPhone
    func hideCategoriesPanel()
    func currentShelfItemInSidePanelController() -> FTShelfItemProtocol?
}

extension FTShelfCategoryDelegate {
    func hideCategoriesPanel() {
        
    }
    
    func didTapOnCategoriesOverlay() {
        
    }
}


protocol FTSidePanelShelfItemPickerDelegate: FTShelfCategoryDelegate {
    func currentGroupShelfItemInSidePanelController() -> FTGroupItemProtocol?
}

extension FTSidePanelShelfItemPickerDelegate {
    func shelfCategory(_ viewController: UIViewController, didSelectCollection: FTShelfItemCollection) {
    }
    
    func shelfCategory(_ viewController: UIViewController, didRenameCollection: FTShelfItemCollection) {
    }
    
    func shelfCategory(_ viewController: UIViewController, didAddedCollection: FTShelfItemCollection) {
    }
    
    func shelfCategory(_ viewController: UIViewController, willDeleteCollection: FTShelfItemCollection) {
    }
    
    func shelfCategory(_ viewController: UIViewController, didDeleteCollection: FTShelfItemCollection) {
    }
    
    func shelfCategory(_ viewController: UIViewController, move items: [FTShelfItemProtocol], toCollection: FTShelfItemCollection) {
    }
    
    func performToolbarAction(_ viewController: UIViewController, actionType: FTCategoryToolbarActionType, actionView: UIView) {
    }
}

@objc class FTSidePanelItemsViewController: FTShelfItemsViewController {

    weak var sidePanelDelegate: FTSidePanelShelfItemPickerDelegate?
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigation(title: collection?.displayTitle ?? "")
    }
    
    func configureNavigation(title: String) {
        self.navigationItem.hidesBackButton = true
        let leftItem = UIBarButtonItem(image: UIImage.image(for: "chevron.backward", font: UIFont.appFont(for: .medium, with: 18)), style: .plain, target: self, action: #selector(buttonTapped(_ :)))
        self.navigationItem.leftBarButtonItems = [leftItem]
        self.navigationItem.title = title
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationItem.largeTitleDisplayMode = .always
    }
    
    @objc func buttonTapped(_ sender : UIButton) {
        FTFinderEventTracker.trackFinderEvent(with: "quickaccess_back_tap")
        if self == self.navigationController?.viewControllers[0] {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.headerLabelTitle?.font = UIFont.appFont(for: .semibold, with: 17)
        self.tableView.dragInteractionEnabled = true
        self.tableView.dragDelegate = self
        self.view.backgroundColor = .appColor(.finderBgColor)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CellShelfItem") as? FTShelfItemTableViewCell else {
            fatalError("Couldnot find FTShelfItemTableViewCell with id CellShelfItem")
        }
        cell.mode = self.mode;
        cell.tableView = tableView;
        cell.indexPath = indexPath;
        
        cell.labelSubTitle.textColor = UIColor.appColor(.black50);
        cell.labelTitle.textColor = UIColor.label;

        cell.cellAccessoryType = .none;
        cell.accessoryView = nil;
        cell.imageViewIcon.image = nil;
        cell.imageViewIcon2.image = nil;
        cell.imageViewIcon3.image = nil;

        cell.shadowImageView.isHidden = false;
        cell.shadowImageView2.isHidden = true;
        cell.shadowImageView3.isHidden = true;
        cell.passcodeLockStatusView.isHidden = true;
        
        var displayTitle = "";
        var isCurrent = false;

        //Checking if we are inside a collection
        cellDatabinding: if (nil != self.collection) {
            
            var shelfItem : FTShelfItemProtocol!
            shelfItem = itemForCollection(indexPath: indexPath)
            
            guard shelfItem != nil else { break cellDatabinding }
            
            displayTitle = shelfItem.displayTitle;

            cell.labelSubTitle.isHidden = false;

            cell.imageViewIcon.contentMode = .scaleAspectFill;

            cell.configureView(item: shelfItem);
            
            if let groupShelfItem = shelfItem as? FTGroupItemProtocol {
                cell.cellAccessoryType = .disclosureIndicator;
                
                cell.labelSubTitle.text = groupShelfItem.itemsCountString
                
                if let currentGroupShelfItem = self.sidePanelDelegate?.currentGroupShelfItemInSidePanelController(), currentGroupShelfItem.uuid == groupShelfItem.uuid {
                    isCurrent = true;
                }
            }
            else {
                cell.updateUI(forShelfItem: shelfItem);
                
                if let currentShelfItem = self.sidePanelDelegate?.currentShelfItemInSidePanelController(), ((currentShelfItem.uuid == shelfItem.uuid) || (currentShelfItem.URL == shelfItem.URL)) {
                    isCurrent = true;
                }
            }
        }
        else {
            cell.shadowImageView.isHidden = true;
            
            let relativeSectionIndex: Int;
            if self.mode == .picker {
                relativeSectionIndex = indexPath.section - 1;
            }
            else {
                relativeSectionIndex = indexPath.section;
            }
            
            //Handling list of collections
            let categories = self.collections[relativeSectionIndex].items;
            let category = categories[indexPath.row];
            displayTitle = category.displayTitle;
            
            cell.cellAccessoryType = .disclosureIndicator;
            #if !targetEnvironment(macCatalyst)
            cell.imageViewIcon.contentMode = .left;
            cell.imageViewIcon.tintColor = UIColor.init(hexString: "#383838")
            cell.imageIconLeadingConstraint?.constant = 14
            cell.imageViewIcon.image = UIImage(named: "category_single");
            #else
            cell.imageViewIcon.contentMode = .center;
            cell.imageViewIcon.image = UIImage(named: "popoverCategory");
            #endif
            
            cell.labelSubTitle.isHidden = true;
            
            
            if let currentShelfCollection = self.sidePanelDelegate?.currentShelfItemInSidePanelController(), currentShelfCollection.uuid == category.uuid {
                isCurrent = true;
            }
        }
        
        //Current item Styling
//        cell.labelTitle.style = 24
//        cell.labelSubTitle.style = 5
        cell.labelTitle.text = displayTitle;
        cell.isCurrentSelected(isCurrent)
        cell.contentView.isAccessibilityElement = true;
        cell.contentView.accessibilityTraits = UIAccessibilityTraits.none;
        if !cell.labelSubTitle.isHidden , let subTitle = cell.labelSubTitle.text , subTitle.count > 0 {
            cell.contentView.accessibilityLabel = displayTitle.appending(subTitle);
        }
        else {
            cell.contentView.accessibilityLabel = displayTitle;
        }
        
        return cell;
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);

        self.indexPathSelected = indexPath;
        if let _ = self.collection {
            let shelfItem = self.items[indexPath.row];
            if shelfItem.type != RKShelfItemType.group {
                self.sidePanelDelegate?.shelfCategory(self, didSelectShelfItem: shelfItem, inCollection: shelfItem.shelfCollection)
                FTFinderEventTracker.trackFinderEvent(with: "quickaccess_book_tap")
                return;
            }
        }
        self.performSegue(withIdentifier: "SelfPush", sender: nil);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let shelfItemsViewController = segue.destination as? FTSidePanelItemsViewController {
            shelfItemsViewController.mode = self.mode;
            shelfItemsViewController.sidePanelDelegate = self.sidePanelDelegate;

            if let collection = self.collection {
                shelfItemsViewController.collection = collection;
                shelfItemsViewController.group = self.items[self.indexPathSelected.row] as? FTGroupItemProtocol;
            }
        }
    }
}

extension FTSidePanelItemsViewController {
     func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let identifier = indexPath as NSIndexPath
        var contextMenu: UIContextMenuConfiguration?
        let shelfItem = self.items[indexPath.row]

        let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
            var actions = [UIMenuElement]()
            let openInWindowAction = UIAction(title: NSLocalizedString("OpenInNewWindow", comment: "Open in New Window")) {[weak self] _ in
                self?.openItemInNewWindow(shelfItem,pageIndex: nil)
            }
            if !(UIDevice.current.isIphone()) {
                actions.append(openInWindowAction)
            }
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
        }
         contextMenu = UIContextMenuConfiguration(identifier: identifier, previewProvider: { () -> UIViewController? in
             let storyboard = UIStoryboard(name: "FTShelfItems", bundle: nil)
             let previewVC = storyboard.instantiateViewController(identifier: "FTShelfItemPreviewViewController") as? FTShelfItemPreviewViewController
             previewVC?.shelfItem = shelfItem
             return previewVC
         }, actionProvider: actionProvider)

        return contextMenu
    }
}

extension FTSidePanelItemsViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return self.selectedItems(at: indexPath, for: session)
    }

    func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return []
    }

    private func selectedItems(at indexPath: IndexPath, for session: UIDragSession) -> [UIDragItem] {
//        let sourceShelfItem = self.items[indexPath.row]
//        let sourceURL = sourceShelfItem.URL
//        let itemProvider = NSItemProvider()
//
//        let title = sourceURL.deletingPathExtension().lastPathComponent
//        var userActivityID = "com.fluidtouch.noteshelf.openNotebook.newSession"
//        if let bundleID = Bundle.main.bundleIdentifier {
//            userActivityID = bundleID.appending(".openNotebook.newSession")
//        }
//        let userActivity = NSUserActivity(activityType: userActivityID)
//        userActivity.title = title
//        var userInfo = userActivity.userInfo ?? [AnyHashable : Any]();
//        let docPath = sourceURL.relativePathWRTCollection();
//        if !(sourceShelfItem is FTGroupItemProtocol) {
//            userInfo[LastOpenedDocumentKey] = docPath
//            if docPath.deletingLastPathComponent.pathExtension == groupExtension {
//                userInfo[LastOpenedGroupKey] = docPath.deletingLastPathComponent
//            }
//        } else if sourceShelfItem is FTGroupItemProtocol {
//            userInfo[LastOpenedGroupKey] = docPath
//        }
//
//        if let collectionName = docPath.collectionName() {
//            userInfo[LastSelectedCollectionKey] = collectionName;
//        }
//        userActivity.userInfo = userInfo
//        itemProvider.registerObject(userActivity, visibility: .all)
//        itemProvider.suggestedName = sourceShelfItem.URL.deletingPathExtension().lastPathComponent
//        //************************************
//        let itemToExport = FTItemToExport.init(shelfItem: sourceShelfItem)
//
//        if sourceShelfItem is FTGroupItemProtocol {
//            itemProvider.registerFileRepresentation(forTypeIdentifier: "public.zip-archive", fileOptions: NSItemProviderFileOptions.openInPlace, visibility: .all) { completionHandler in
//                let dataProgress:Progress = Progress()
//
//                let target = FTExportTarget.init()
//                target.itemsToExport = [itemToExport]
//                let exportContentGenerator = FTExportContentGenerator(target: target, onViewController: self)
//                exportContentGenerator.generateContents { (_, error, exportItems) in
//                    if error == nil, let filePath = exportItems?.first?.representedObject as? String {
//                        let fileURL = URL.init(fileURLWithPath: filePath)
//                        completionHandler(fileURL, true, nil)
//                    }
//                    else
//                    {
//                        completionHandler(nil, false, error)
//                    }
//                }
//                return dataProgress
//            }
//        }
//        else {
//            itemProvider.registerFileRepresentation(forTypeIdentifier: UTI_TYPE_NOTESHELF_BOOK, fileOptions: [.openInPlace], visibility: .all) { completionHandler in
//                let dataProgress:Progress = Progress()
//                let contentgenerator = FTNBKContentGenerator()
//                contentgenerator.generateSupportContent(forItem: itemToExport, andCompletionHandler: { (item, error, _) -> (Void) in
//                    if error == nil, let filePath = item?.representedObject as? String {
//                        let fileURL = URL.init(fileURLWithPath: filePath)
//                        completionHandler(fileURL, true, nil)
//                    }
//                    else
//                    {
//                        completionHandler(nil, false, error)
//                    }
//                });
//                return dataProgress
//            }
//        }
//        //************************************
//
//            let dragContext = FTDragAssociatedInfo.init(with: sourceShelfItem)
//            dragContext.focusedIndexPath = indexPath
//            dragContext.allowMove = false
//            session.localContext = dragContext
//
//            if((session.localContext) != nil) {
//                let dragItem = UIDragItem(itemProvider: itemProvider)
//                dragItem.localObject = sourceShelfItem
//
//                dragItem.previewProvider  = { () -> UIDragPreview? in
//                    self.getPreview(indexPath: indexPath, shelfItem: sourceShelfItem)
//                }
//
//                return [dragItem]
//            }
//
        return []
    }

    private func getPreview(indexPath: IndexPath, shelfItem: FTShelfItemProtocol) -> UIDragPreview? {
        if let cell = self.tableView?.cellForRow(at: indexPath) as? FTShelfItemTableViewCell {
            if let groupPreview = Bundle.main.loadNibNamed("FTShelfItemDragPreview", owner: self, options: nil)?[0] as? FTShelfItemDragPreview {
                if shelfItem is FTGroupItem {
                    if let firstCoverImgView = cell.imageViewIcon {
                        groupPreview.imageViewIcon.image = firstCoverImgView.image
                    }
                    if let secondCoverImgView = cell.imageViewIcon2 {
                        groupPreview.imageViewIcon2.image = secondCoverImgView.image
                    }
                    if let thirdCoverImgView = cell.imageViewIcon3 {
                        groupPreview.imageViewIcon3.image = thirdCoverImgView.image
                    }

                    var bezierPath: UIBezierPath?

                    var rect1 = groupPreview.imageViewIcon.convert(groupPreview.imageViewIcon.bounds, to: groupPreview)
                    rect1.origin.x += 2
                    rect1.size.width -= 4
                    var rect2 = groupPreview.imageViewIcon2.convert(groupPreview.imageViewIcon2.bounds, to: groupPreview)
                    rect2.origin.x += 2
                    rect2.size.width -= 4
                    var rect3 = groupPreview.imageViewIcon3.convert(groupPreview.imageViewIcon3.bounds, to: groupPreview)
                    rect3.origin.x += 2
                    rect3.size.width -= 4

                    bezierPath = UIBezierPath.init()
                    bezierPath?.append(UIBezierPath.init(roundedRect: rect1, cornerRadius: 3.0))
                    bezierPath?.append(UIBezierPath.init(roundedRect: rect2, cornerRadius: 3.0))
                    if self.view.isRegularClass() {
                        bezierPath?.append(UIBezierPath.init(roundedRect: rect3, cornerRadius: 3.0))
                    }
                    groupPreview.backgroundColor = .clear
                    let dragPreview = UIDragPreview(view: groupPreview)
                    dragPreview.parameters.visiblePath = bezierPath
                    dragPreview.parameters.backgroundColor = .clear
                    return dragPreview
                } else {
                    if let firstCoverImgView = cell.imageViewIcon {
                        groupPreview.imageViewIcon.image = firstCoverImgView.image
                        let dragPreview = UIDragPreview(view: groupPreview.imageViewIcon)
                        dragPreview.parameters.backgroundColor = .clear
                        return dragPreview
                    }
                }
            }
            return UIDragPreview(view: cell)
        }
        return nil
    }
}
