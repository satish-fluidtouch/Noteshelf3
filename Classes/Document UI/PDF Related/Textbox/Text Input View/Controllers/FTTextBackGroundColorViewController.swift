//
//  FTTextBackGroundColorViewController.swift
//  Noteshelf
//
//  Created by Mahesh on 27/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTTextBackGroundColorDelegate: NSObjectProtocol {
    func didSelectColor(_ color: UIColor)
}

class FTTextBackGroundColorViewController: UIViewController, FTCustomPresentable, FTPopOver {
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: true)
    
    var contentSize: CGSize {
        get {
            return CGSize(width: 248, height: 308)
        }
    }
    
    var arrowDirection: UIPopoverArrowDirection {
        return .any
    }
    
    var showArrowDirection: Bool? {
        if self.isRegularClass() {
            return false
        }
        return false
    }
    
    @IBOutlet private weak var colorTableView: UITableView?
    let colors = FTTextBackgroundColorManager.fetchTextModeBackgroundColors()
    
    weak var delegate: FTTextBackGroundColorDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectDefaultItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.preferredContentSize = CGSize(width: 248, height: 308)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.preferredContentSize = CGSize(width: 248, height: 308)
    }
    
    class func showAsPopover(fromSourceView sourceView: UIView,
                             overViewController viewController: UIViewController,
                             delegate: FTTextBackGroundColorDelegate) {
        let storyboard = UIStoryboard.init(name: "FTTextInputUI", bundle: nil)
        guard let textBackGroundVC = storyboard.instantiateViewController(withIdentifier: "FTTextBackGroundColorViewController") as? FTTextBackGroundColorViewController else {
            fatalError("FTTextBackGroundColorViewController not found")
        }
        
        textBackGroundVC.customTransitioningDelegate.sourceView = sourceView
        textBackGroundVC.delegate = delegate
        if viewController.isRegularClass() {
            let navigationVC = UINavigationController(rootViewController: textBackGroundVC)
            viewController.ftPresentModally(navigationVC, contentSize: CGSize(width: 248, height: 308), animated: true, completion: nil)
        } else {
            textBackGroundVC.showPopover(sourceView: sourceView)
        }
    }
    
    private func getSelectedColorIndex() -> Int {
        if var color = UserDefaults.standard.value(forKey: "text_background_color") as? String {
            var index = colors.firstIndex(where: {$0.color.replacingOccurrences(of: "#", with: "") == color })
            if index == nil || index == NSNotFound {
                index = colors.count - 1
            }
            return index ?? 0
        }
        return 0
    }
    
    private func selectDefaultItem() {
        let index = getSelectedColorIndex()
        self.colorTableView?.reloadSections(IndexSet(integer: 0), with: .automatic)
        self.colorTableView?.selectRow(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: .none)
    }
    
    private func navigateToColorPicker(_ sender: UIView) {
        let colorPicker: FTColorPickerView = FTColorPickerView()
        colorPicker.delegate = self
        colorPicker.customTransitioningDelegate.sourceView = sender
        self.ftPresentModally(colorPicker,contentSize: CGSize(width: 320, height: 496), animated: true, completion: nil)
    }
}

extension FTTextBackGroundColorViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FTTextAnnotationBackgroundCell", for: indexPath)
        if let colorCell = cell as? FTTextAnnotationBackgroundCell {
            colorCell.updateCell(colors[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedColor = colors[indexPath.row]
        if !selectedColor.isCustom {
            var color = UIColor.clear
            if !selectedColor.color.isEmpty {
                color = UIColor(hexString: selectedColor.color)
            }
            self.delegate?.didSelectColor(color)
        } else {
            if let cell = tableView.cellForRow(at: indexPath) {
                navigateToColorPicker(cell.contentView)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
}

class FTColorPickerView: UIColorPickerViewController, FTCustomPresentable {
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: true)
}

extension FTTextBackGroundColorViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        self.delegate?.didSelectColor(viewController.selectedColor)
    }
    
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        self.delegate?.didSelectColor(color)
    }
}
