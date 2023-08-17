//
//  FTMediaFilterViewController.swift
//  Noteshelf3
//
//  Created by Sameer on 02/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

protocol FTMediaFilterViewDelegate: NSObjectProtocol {
    func didDismissMediaFilterView(_ type: FTMediaProtocol)
}

class FTMediaFilterViewController: UIViewController, FTCustomPresentable, FTPopOver {
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: true)
    
    @IBOutlet weak var tableView: UITableView?
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    var contentSize: CGSize {
        get {
            return CGSize(width: 200, height: 120)
        }
    }
    
    var arrowDirection: UIPopoverArrowDirection {
        return .any
    }
    
    var showArrowDirection: Bool? {
        if self.isRegularClass() {
            return true
        }
        return false
    }
    
    private var moreOptionsArray = [[String: Any]]()
    weak var delegate: FTMediaFilterViewDelegate?
    var selectedMediaType: FTMediaType {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "mediaType")
            UserDefaults.standard.synchronize()
        }
        
        get {
            let value = UserDefaults.standard.object(forKey: "mediaType") as? String
            return FTMediaType(rawValue: value ?? "") ?? .allMedia
        }
    }
    private var mediaOptions = [FTMediaProtocol]()
    var previousSelectedCell: FTMediaFilterCell?
  
    var splitVC: UISplitViewController? {
        if let splitVC = self.noteBookSplitViewController() {
            return splitVC
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.tableView?.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        self.tableView?.tableFooterView = UIView()
        mediaOptions = [FTAllMedia(), FTImageMedia(), FTAudioMedia()]
        self.tableView?.reloadData()
        self.tableView?.layoutIfNeeded()
//        self.preferredContentSize = CGSize(width: 250, height: (self.tableView?.contentSize.height)!+10)
        if let splitView = self.splitVC {
            if splitView.isRegularClass() {
                blurView?.isHidden = true
            } else {
                blurView?.isHidden = false
            }
        } else {
            blurView?.isHidden = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }

    static func showPopOver(sourceView: UIView, sourceRect: CGRect? = nil, controller: UIViewController, shouldDismissOnTap: Bool = true, completion: ShowPopoverCompletion? = nil ) {
        let journalMediaFilterVC = FTMediaFilterViewController.instantiate(fromStoryboard: .finder)
        journalMediaFilterVC.delegate = controller as? FTMediaFilterViewDelegate
        journalMediaFilterVC.customTransitioningDelegate.sourceView = sourceView
//        controller.ftPresentModally(journalMediaFilterVC, contentSize: CGSize(width: 200, height: 120), animated: true, completion: nil)
        journalMediaFilterVC.showPopover(sourceView: sourceView)
    }
}

// MARK: TableView Delegate & DataSource
extension FTMediaFilterViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FTMediaFilterCell", for: indexPath)
        if let cell = cell as? FTMediaFilterCell {
            let rowDic = mediaOptions[indexPath.row]
            cell.configureCell(with: rowDic)
            if rowDic.type == self.selectedMediaType {
                previousSelectedCell = cell
                cell.isSelected = true
            }
        }
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? FTMediaFilterCell {
           // Add Accessory View
           if let previousSelectedCell = previousSelectedCell, previousSelectedCell != cell {
               previousSelectedCell.isSelected = false
           }
           previousSelectedCell = cell
            cell.isSelected = true
           let rowDic = mediaOptions[indexPath.row]
           self.selectedMediaType = rowDic.type
           self.dismiss(animated: true) {
                self.delegate?.didDismissMediaFilterView(rowDic)
            }
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
          tableView.cellForRow(at: indexPath)?.accessoryView = nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 40
    }
}
