//
//  FTDynamicOptionsViewController.swift
//  Noteshelf
//
//  Created by Siva on 07/06/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTExportSettingsDelegate:AnyObject {
    func didShareWith(exportTarget: FTExportTarget, and shareButton: UIView?)
}

struct FTDynamicOption {
    var name: String!
}

extension UIViewController
{
    var exportControllerSafeAreaInset: UIEdgeInsets {
        var offset = UIEdgeInsets.zero;
        if let presentController = self.presentingViewController,
            !presentController.isRegularClass() {
            offset = presentController.view.safeAreaInsets;
        }
        return offset;
    }
}

class FTDynamicOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPopoverPresentationControllerDelegate, FTCustomPresentable {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    var presentedForToolbarMode : FTDeskToolbarMode = .normal
    
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction)
    var supportsFullScreen: Bool {
        return false
    }
    var exportInfo : FTExportTarget!
    weak var currentPage : FTPageProtocol?
    var targetView : UIView?
    weak var delegate : FTExportSettingsDelegate?

    let options = [
        FTDynamicOption(name: NSLocalizedString("CurrentPage", comment: "CurrentPage")),
        FTDynamicOption(name: NSLocalizedString("SelectPages", comment: "Select Pages")),
        FTDynamicOption(name: NSLocalizedString("AllPages", comment: "All Pages"))
    ];

    //MARK:- UIViewController
    override func viewDidLoad() {
        super.viewDidLoad();
        self.preferredContentSize = CGSize(width: 320, height: 240)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(canbePopped()){
            backButton?.isHidden = false
        } else {
            backButton?.isHidden = true
        }
        self.preferredContentSize = CGSize(width: 320, height: 220)
    }
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    
    //MARK:- Presentation
    class func show(fromViewController viewController: UIViewController,
                    withSourceView sourceView: UIView? = nil,
                    andSourceRect sourceRect: CGRect? = nil,
                    andExportInfo exportData: FTExportTarget,
                    andDelegate delegate1:FTExportSettingsDelegate?,
                    forToolBarMode : FTDeskToolbarMode,
                    withCurrentPage page: FTPageProtocol) {
        let storyboard = UIStoryboard.init(name: "FTShelf", bundle: nil);
        let optionsViewController  = storyboard.instantiateViewController(withIdentifier: "FTDynamicOptionsViewController") as! FTDynamicOptionsViewController;
        optionsViewController.exportInfo = exportData
        optionsViewController.currentPage = page
        optionsViewController.targetView = sourceView
        optionsViewController.delegate = delegate1
        optionsViewController.presentedForToolbarMode = forToolBarMode
        var height: CGFloat = 240;
        if(!viewController.isRegularClass()) {
            height = 300 + viewController.view.safeAreaInsets.bottom;
        }
        #if targetEnvironment(macCatalyst)
            let navController: UINavigationController = UINavigationController(rootViewController: optionsViewController)
            navController.isNavigationBarHidden = true
            navController.modalPresentationStyle = .popover;
            navController.popoverPresentationController?.sourceView = sourceView
            navController.preferredContentSize = CGSize(width: 320, height: height)
            viewController.present(navController, animated: true, completion: nil)
        #else
            optionsViewController.customTransitioningDelegate.sourceView = sourceView
            viewController.ftPresentModally(optionsViewController, contentSize: CGSize(width: 320, height: height), animated: true, completion: nil);
        #endif

    }
    
    //MARK:- UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.options.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = self.options[indexPath.row];
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellDynamicOption", for: indexPath) as! FTDynamicOptionTableViewCell;
        
        cell.titleLabel.text = option.name;
        cell.titleLabel.addCharacterSpacing(kernValue: -0.32)
        cell.accessoryType = .disclosureIndicator
        return cell;
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeight = section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
        let sectionHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: sectionHeight))
        sectionHeaderView.backgroundColor = .clear
        return sectionHeaderView
    }
    //MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        
        if indexPath.row == 0 {
            exportInfo.shouldHideNBK = true
        } else {
            exportInfo.shouldHideNBK = false
        }
        
        if let pages = getPages() {
            exportInfo.pages = pages
        }
        
        if indexPath.row == 1 {
            showFinder(exportInfo)
        } else {
            showFormatOptions(exportInfo)
        }
        trackEvents(indexPath.row)
    }
    
    func trackEvents(_ index: Int) {
        var eventName = ""
        switch index {
        case 0:
            eventName = "Share_CurrentPage"
        case 1:
            eventName = "Share_AllPages"
        case 2:
            eventName = "Share_SelectPages"
        default:
            eventName = ""
        }
        if eventName != "" {
            track(eventName, params: [:],screenName: FTScreenNames.share)
        }
    }
    
    func getPages() -> [FTPageProtocol]? {
        if let pages = exportInfo.notebook?.pages() {
            if exportInfo.shouldHideNBK {
                if let page = self.currentPage {
                    return [page]
                }
                return [pages[0]]
            }
            return pages
        }
        return nil
    }
    
    func showFormatOptions(_ info : FTExportTarget) {
    }
    
    func showFinder(_ info : FTExportTarget) {
        if let notebook = info.notebook as? FTThumbnailableCollection {
            #if targetEnvironment(macCatalyst)
                if let presentingController = self.delegate as? FTPDFRenderViewController {
                    let toolBarMode = self.presentedForToolbarMode
                    self.dismiss(animated: true) {[weak self] in
                        let finderController = FTFinderViewController.showFinder(forDocument: notebook, purpose: .share, exportInfo: info, viewController: presentingController, delegate: presentingController, searchOptions: FTFinderSearchOptions(),
                                                                                 forToolBarMode: toolBarMode, animated:true);
                        finderController?.shareTargetView = self?.targetView
                    }
                }
            #else
//            FTFinderViewController.showFinder(forDocument: notebook, purpose: .share, exportInfo: info, viewController: self, delegate: self, searchOptions: FTFinderSearchOptions(), forToolBarMode: presentedForToolbarMode, animated:true);
            #endif
        }
    }
}

extension FTDynamicOptionsViewController : FTFinderThumbnailsActionDelegate {
    func finderViewController(_ finderVc: FTFinderViewController, didSelectTag pages: NSSet, from source: UIView) {
        
    }

    func finderViewController(didSelectDuplicate pages: [FTThumbnailable], onCompletion: (() -> ())?) {
        
    }

    func currentPage(in finderViewController: FTFinderViewController) -> FTThumbnailable? {
        return self.currentPage as? FTThumbnailable;
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectInsertAboveForPage page: FTPageProtocol?) {
        
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectInsertBelowForPage page: FTPageProtocol?) {
        
    }

    func finderViewController(bookMark page: FTThumbnailable) {
        
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectRemovePagesWithIndices indices: IndexSet) {
        
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectPages pages: NSSet, toMoveTo shelfItem: FTShelfItemProtocol) {
        
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectShareWithPages pages: NSSet, exportTarget: FTExportTarget?) {
        finderViewController.dismiss(animated: true) { [weak self] in
            let pages = pages.allObjects as! [FTPageProtocol]
            exportTarget?.pages = pages.sorted(by: { (p1, p2) -> Bool in
                return (p1.pageIndex() < p2.pageIndex())
            });
            if let target = exportTarget {
                self?.showFormatOptions(target)
            }
        }
    }
    
    func shouldShowMoveOperation(in finderViewController: FTFinderViewController) -> Bool {
        return false
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didMovePageAtIndex fromIndex: Int, toIndex: Int) {
        
    }
    
    func finderViewController(_ contorller: FTFinderViewController, searchForKeyword searchKey: String, onFinding: (() -> ())?, onCompletion: (() -> ())?) {
        
    }
    
    func finderViewController(didSelectPageAtIndex index: Int) {
        
    }

    func finderViewController(_ finderViewController: FTFinderViewController, didSelectRotatePages pages: NSSet) {
        
    }

    func finderViewController(_ finderViewController: FTFinderViewController, pastePagesAtIndex index: Int?) {
        
    }
}
