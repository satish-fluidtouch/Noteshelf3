//
//  FTNoteBookSplitViewController.swift
//  Noteshelf3
//
//  Created by Sameer on 21/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import FTCommon

class FTNoteBookSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    let contentTransitionDelegate = FTModalScaleTransitionDelegate();
    private(set) weak var documentViewController: FTDocumentRenderViewController?;

    var curentPrefrredDisplayMode = UISplitViewController.DisplayMode.secondaryOnly
    class func viewController(_ docInfo : FTDocumentOpenInfo
                              , bounds: CGRect
                              , delegate: FTOpenCloseDocumentProtocol?) -> FTNoteBookSplitViewController
    {
        let controller = FTDocumentRenderViewController.viewController(info: docInfo, delegate: delegate);
        controller.view.backgroundColor = UIColor.clear;
        controller.configureDocumentView(docInfo);
        
        // Supplimentary controller
        let finderHostController = FTFinderTabHostingController()
        let tabBar = FTFinderTabBarController.viewController(delegate: nil,
                                                             with: docInfo.document,
                                                             searchOptions: controller.documentViewController.finderSearchOptions)
        tabBar.finderDelegate = controller.documentViewController
        controller.documentViewController.finderNotifier = tabBar
        finderHostController._addChild(tabBar)
        
#if targetEnvironment(macCatalyst)
        let splitView = FTNoteBookSplitViewController.init(style: .doubleColumn)
        splitView.setViewController(finderHostController, for: .primary)
        splitView.preferredPrimaryColumnWidth = supplimentaryFinderVcWidth
        splitView.preferredSplitBehavior = .tile
        splitView.primaryBackgroundStyle = .sidebar
#else
        // Primary viewcontroller
        var primaryVc: FTShelfCategoryViewController_iOS13?
        let stroyBoard = UIStoryboard(name: "FTShelf_iOS13", bundle: nil)
        if let categoryVC = stroyBoard.instantiateViewController(withIdentifier: "FTShelfCategoryViewController_iOS13") as? FTShelfCategoryViewController_iOS13 {
            primaryVc = categoryVC
            categoryVC.shelfItemCollection = docInfo.shelfItem.shelfCollection;
            categoryVC.delegate = controller.documentViewController
            categoryVC.displayMode = .notebook
        }
        
        let splitView = FTNoteBookSplitViewController.init(style: .tripleColumn)
        splitView.setViewController(primaryVc, for: .primary)
        splitView.setViewController(finderHostController, for: .supplementary)
        splitView.preferredSupplementaryColumnWidth = supplimentaryFinderVcWidth
        splitView.preferredPrimaryColumnWidth = primaryCategoriesWidth
        splitView.preferredSplitBehavior = .automatic
#endif
        
        splitView.setViewController(controller, for: .secondary)
        
        splitView.preferredDisplayMode = .secondaryOnly
        
        splitView.documentViewController = controller;
        
        return splitView;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshStatusBarAppearnce();
    }
    
    // TODO: (Narayana) Temporarily added, to be removed once NSToolbar is updated
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
#if targetEnvironment(macCatalyst)
        self.configureMacToolbar();
#endif
    }

    func addSupplimentaryController(_ controller: FTFinderTabBarController) {
        if let finderHostingVc = self.viewController(for: .supplementary) as? FTFinderTabHostingController, finderHostingVc.children.isEmpty {
            finderHostingVc._addChild(controller)
        }
        NotificationCenter.default.post(name: .validationFinderButtonNotification, object: self.view.window)
    }
    
    func isFinderVisible() -> Bool {
        var isFinderShown = false
        if self.isRegularClass() {
            if self.preferredDisplayMode == .oneBesideSecondary {
                isFinderShown = true
            }
        } else {
            if let finderHostingVc = self.viewController(for: .supplementary) as? FTFinderTabHostingController {
                isFinderShown = finderHostingVc.children.isEmpty
            }
        }
        return isFinderShown
    }
 
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if !UIDevice.isLandscapeOrientation  && self.displayMode == .oneBesideSecondary {
            self.preferredSplitBehavior = .displace
        }
        self.preferredDisplayMode = self.curentPrefrredDisplayMode
        coordinator.animate(alongsideTransition: { [weak self](_) in
            guard let self = self else {
                return
            }
            NotificationCenter.default.post(name: .validationFinderButtonNotification, object: self.view.window)
            self.handleTraitCollectionChange();
        }, completion: nil);
    }
    
    func handleTraitCollectionChange() {
#if targetEnvironment(macCatalyst)
        self.preferredPrimaryColumnWidth = supplimentaryFinderVcWidth
#else
        self.preferredSupplementaryColumnWidth = supplimentaryFinderVcWidth
#endif
    }
    
    override var prefersStatusBarHidden: Bool {
        if UIDevice.current.isIphone(){
            return super.prefersStatusBarHidden;
        }
        return true;
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return self.prefersStatusBarHidden;
    }
}

struct FTNotebookEventTracker {
    static let toolbar_back_tap = "toolbar_back_tap"
    static let toolbar_undo_tap = "toolbar_undo_tap"
    static let toolbar_redo_tap = "toolbar_redo_tap"
    static let toolbar_focusmode_toggle = "toolbar_focusmode_toggle"
    static let focusmode_gesture_toggle = "focusmode_gesture_toggle"
    static let toolbar_addmenu_tap = "toolbar_addmenu_tap"
    static let toolbar_more_tap = "toolbar_more_tap"
    static let toolbar_right_arrow_tap = "toolbar_right_arrow_tap"
    static let toolbar_left_arrow_tap = "toolbar_left_arrow_tap"
    static let toolbar_tools_swipe = "toolbar_tools_swipe"
    static let nbk_more_share_tap = "nbk_more_share_tap"
    static let nbk_more_share_currentpage_tap = "nbk_more_share_currentpage_tap"
    static let nbk_more_share_allpages_tap = "nbk_more_share_allpages_tap"
    static let nbk_more_share_selectpages_tap = "nbk_more_share_selectpages_tap"
    static let nbk_more_present_tap = "nbk_more_present_tap"
    static let nbk_more_gotopage_tap = "nbk_more_gotopage_tap"
    static let nbk_more_zoombox_tap = "nbk_more_zoombox_tap"
    static let nbk_more_rotatepage_tap = "nbk_more_rotatepage_tap"
    static let nbk_more_rotate_clockwise_tap = "nbk_more_rotate_clockwise_tap"
    static let nbk_more_rotate_180_tap = "nbk_more_rotate_180_tap"
    static let nbk_more_rotate_anticlockwise_tap = "nbk_more_rotate_anticlockwise_tap"
    static let nbk_more_changetemplate_tap = "nbk_more_changetemplate_tap"
    static let nbk_more_saveastemplate_tap = "nbk_more_saveastemplate_tap"
    static let nbk_more_getinfo_tap = "nbk_more_getinfo_tap"
    static let nbk_more_getinfo_title_tap = "nbk_more_getinfo_title_tap"
    static let nbk_more_getinfo_gotopage_tap = "nbk_more_getinfo_gotopage_tap"
    static let nbk_more_gestures_tap = "nbk_more_gestures_tap"
    static let nbk_more_help_tap = "nbk_more_help_tap"
    static let nbk_more_moresettings_tap = "nbk_more_moresettings_tap"
    static let nbk_moresettings_password_tap = "nbk_moresettings_password_tap"
    static let nbk_moresettings_addtisiri_tap = "nbk_moresettings_addtisiri_tap"
    static let nbk_moresettings_synctoevernote_tap = "nbk_moresettings_synctoevernote_tap"
    static let nbk_moresettings_scrolling_tap = "nbk_moresettings_scrolling_tap"
    static let nbk_moresettings_hideappUI_toggle = "nbk_moresettings_hideappUI_toggle"
    static let nbk_moresettings_hyperlinks_toggle = "nbk_moresettings_hyperlinks_toggle"
    static let nbk_moresettings_autolock_toggle = "nbk_moresettings_autolock_toggle"
    static let nbk_moresettings_stylus_tap = "nbk_moresettings_stylus_tap"
    static let applepencil_useapplepencil_toggle = "applepencil_useapplepencil_toggle"
    static let applepencil_pressuresensitivity_toggle = "applepencil_pressuresensitivity_toggle"
    static let applepencil_doubletapaction_tap = "applepencil_doubletapaction_tap"
    static let applepencil_doubletapaction_selected = "applepencil_doubletapaction_selected"

    static func trackNotebookEvent(with value: String, params: [String: Any]? = nil) {
        track(value, params: params,screenName: FTScreenNames.notebook)
    }
}
