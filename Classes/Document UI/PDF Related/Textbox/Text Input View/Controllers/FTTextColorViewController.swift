//
//  FTTextColorViewController.swift
//  Noteshelf
//
//  Created by Mahesh on 20/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTTextColorDelegate: NSObjectProtocol {
    func didSelectColor(_ colorStr: String)
}

class FTTextColorViewController: UIViewController, FTCustomPresentable, FTPopOver {
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: true)
    
    var contentSize: CGSize {
        get {
            return CGSize(width: 288, height: 116)
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

    @IBOutlet private weak var colorView: UIView!
    var collectionView: FTTextColorCollectionView?
    weak var delegate: FTTextColorDelegate?
    var textFontStyle: FTTextStyleItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadColorCollectionView()
    }
    
    class func showAsPopover(fromSourceView sourceView: UIView,
                             textStyle: FTTextStyleItem,
                             delegate: FTTextColorDelegate) {
        let storyboard = UIStoryboard.init(name: "FTTextInputUI", bundle: nil)
        guard let textColorVC = storyboard.instantiateViewController(withIdentifier: "FTTextColorViewController") as? FTTextColorViewController else {
            fatalError("FTTextColorViewController not found")
        }
        textColorVC.customTransitioningDelegate.sourceView = sourceView
        textColorVC.delegate = delegate
        textColorVC.textFontStyle = textStyle
        (delegate as? FTTextStyleCompactViewController)?.textColorDelegate = textColorVC
        textColorVC.showPopover(sourceView: sourceView)
    }
    
    private func loadColorCollectionView() {
        let layout = FTTextColorsFlowLayout()
        collectionView = FTTextColorCollectionView.init(frame: .zero, collectionViewLayout: layout)
        collectionView?.textColorDelegate = self
        collectionView?.selectedColor = self.textFontStyle?.textColor
        collectionView?.addFullConstraints(self.colorView)
        collectionView?.layoutSubviews()
    }

    func reloadColorsCollectionIfRequired() {
        if let item = textFontStyle {
            if self.collectionView?.selectedColor?.replacingOccurrences(of: "#", with: "") != item.textColor.replacingOccurrences(of: "#", with: "") {
                self.collectionView?.selectedColor = item.textColor
                self.collectionView?.updateSelectedColor()
            } else {
                self.collectionView?.updateSelectedColor()
            }
        }
    }
}

extension FTTextColorViewController: FTTextColorCollectionViewDelegate {
    func didSelectTextColor(_ colorStr: String) {
        self.delegate?.didSelectColor(colorStr)
    }
}

extension FTTextColorViewController: FTTextColorUpdateDelegate {
    func didUpdateTextColor() {
        self.reloadColorsCollectionIfRequired()
    }
}
