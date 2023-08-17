//
//  FTRecentItemsEditMenuViewController.swift
//  Noteshelf
//
//  Created by Akshay on 11/10/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Intents
import FTCommon

protocol FTRecentItemsEditMenuProtocol: AnyObject {
    func recentItemEditMenuSelected(for item:FTShelfItemProtocol, menu:FTRecentEditMenuItem)
}

enum FTRecentEditMenuItem {
    //TODO: Localized Stirngs to be added
    case pin
    case unpin
    case createSiriShortcut
    case editSiriShortcut(voiceShortcut: INVoiceShortcut)
    case removeFromRecents
    
    var localizedTitle: String {
        var key = ""
        switch self {
        case .pin:
            key = "PinNotebook"
        case .unpin:
            key = "UnpinNotebook"
        case .createSiriShortcut:
            key = "CreateSiriShortcut"
        case .editSiriShortcut:
            key = "EditSiriShortcut"
        case .removeFromRecents:
            key = "RemoveFromRecents"
        }
        return NSLocalizedString(key, comment: "Recent Item Edit Menu")
    }
}

class FTRecentItemsEditMenuViewController: UIViewController, FTCustomPresentable {

    let customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: false)

    var supportsFullScreen: Bool {
        return false;
    }
    @IBOutlet var tableView: UITableView!
    
    weak var delegate: FTRecentItemsEditMenuProtocol?
    var itemAndMode: ShelItemAndMode?
    
    var editMenuItems = [FTRecentEditMenuItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if !self.isRegularClass() {
            self.tableView.tableHeaderView = nil
        }
        
        
        if let item = itemAndMode?.item, let mode = itemAndMode?.sectionMode {
            switch mode {
            case .recent:
                editMenuItems.append(contentsOf:[.pin,.createSiriShortcut,.removeFromRecents])
            case .favorites:
                editMenuItems.append(contentsOf:[.createSiriShortcut,.unpin])
            }
            isSiriShortcutAvailable(for: item) { [weak self] (voiceShortcut) in
                if let shortcut = voiceShortcut {
                        let replaceItem : FTRecentEditMenuItem = .editSiriShortcut(voiceShortcut: shortcut)
                        switch mode {
                        case.recent:
                            self?.editMenuItems.remove(at: 1)
                            self?.editMenuItems.insert(replaceItem, at: 1)
                        case .favorites:
                            self?.editMenuItems.removeFirst()
                            self?.editMenuItems.insert(replaceItem, at: 0)
                        }
                }
                self?.tableView.reloadData()
                self?.view.setNeedsLayout()
                UIView.animate(withDuration:0.05, animations: {
                    self?.view.layoutIfNeeded()
                })
            }
        }
    }

    private func isSiriShortcutAvailable(for item: FTShelfItemProtocol ,completion:@escaping (_ voiceShortcut: INVoiceShortcut?)->Void) {
        FTSiriShortcutManager.isSiriShortcutAvailable(for: item) { (voiceShortcut) in
            runInMainThread({
                completion(voiceShortcut)
            })
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let height : Int
        if isRegularClass() {
            let margin = 10
            let cellHeight = 52
            height = 2*margin + editMenuItems.count*cellHeight            
        } else {
            height = 250
        }
        self.navigationController?.preferredContentSize = CGSize(width: 320, height: height)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection);
//        if previousTraitCollection != nil {
//            self.dismiss(animated: false, completion: nil)
//        }
    }
    
    class func showAsPopover(fromSourceView sourceView:UIView,
                             overViewController viewController:UIViewController,
                             itemAndMode:ShelItemAndMode,
                             withDelegate delegate:FTRecentItemsEditMenuProtocol) {
        
        let storyboard = UIStoryboard(name: "FTShelfItems", bundle: nil);
        
        let recentEditMenuViewController = storyboard.instantiateViewController(withIdentifier: "FTRecentItemsEditMenuViewController") as! FTRecentItemsEditMenuViewController;
        recentEditMenuViewController.delegate = delegate;
        recentEditMenuViewController.itemAndMode = itemAndMode
        recentEditMenuViewController.customTransitioningDelegate.sourceView = sourceView
        recentEditMenuViewController.customTransitioningDelegate.permittedArrowDirections = .left
        viewController.ftPresentModally(recentEditMenuViewController, contentSize:CGSize(width:320, height:250),animated: true, completion: nil);
    }
}

//MARK:- UITableView DataSource
extension FTRecentItemsEditMenuViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return editMenuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FTRecentItemEditMenuCell", for: indexPath)
        let menuItem = editMenuItems[indexPath.row]
        if let menuCell = cell as? FTRecentItemEditMenuCell {
            menuCell.configure(with: menuItem)
        }
        return cell
    }
}

//MARK:- UITableView Delegate
extension FTRecentItemsEditMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let itemAndMode = itemAndMode else { return }
        let menuItem = editMenuItems[indexPath.row]
        self.dismiss(animated: true) { [weak self] in
            self?.delegate?.recentItemEditMenuSelected(for: itemAndMode.item, menu: menuItem)
        }
    }
}
