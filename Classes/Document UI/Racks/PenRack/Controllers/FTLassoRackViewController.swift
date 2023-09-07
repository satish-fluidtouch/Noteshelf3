//
//  FTLassoViewController.swift
//  Noteshelf
//
//  Created by srinivas on 28/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc protocol FTLassoRackDelegate: NSObjectProtocol {
    @objc optional func pasteFromClipBoard()
}

@objcMembers public class FTLassoRackViewController: FTBasePenRackViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var lassoBackgroundView: UIButton!
    @IBOutlet private weak var squareBackgroundView: UIButton!
    @IBOutlet private weak var lassoImageView: UIImageView!
    @IBOutlet private weak var squareImageView: UIImageView!
    @IBOutlet private weak var handwritingSwitch: UISwitch!
    @IBOutlet private weak var textBoxesSwitch: UISwitch!
    @IBOutlet private weak var photosSwitch: UISwitch!
    @IBOutlet private weak var shapesSwitch: UISwitch!
    @IBOutlet private weak var pasteFromClipboardView: UIView?

    weak var delegate: FTLassoRackDelegate?

    override class var identifier: String {
        return "FTLassoRackViewController"
    }

    override class var contentSize: CGSize {
        return CGSize(width: 375, height: 431)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text =  "notebook.lassoRack.NavTitle".localized
        self.initPreferences()
        self.updateSelectionType()
        self.configurePasteOptionIfNeeded()
    }

    private func initPreferences() {
        handwritingSwitch.setOn(FTRackPreferenceState.handWriting, animated: true)
        textBoxesSwitch.setOn(FTRackPreferenceState.textBoxes, animated: true)
        photosSwitch.setOn(FTRackPreferenceState.photos, animated: true)
        shapesSwitch.setOn(FTRackPreferenceState.shapes, animated: true)
    }
    
    private func updateSelectionType() {
        switch FTRackPreferenceState.lassoSelectionType {
        case 0:
            self.lassoTapped(lassoBackgroundView)
        case 1:
            self.squareTapped(squareBackgroundView)
        default:
            break
        }
    }

    private func configurePasteOptionIfNeeded() {
        self.pasteFromClipboardView?.isHidden = true
        if UIPasteboard.canPasteContent() {
            self.pasteFromClipboardView?.isHidden = false
            let pasteViewHeight = self.pasteFromClipboardView?.frame.height ?? 0.0
            if let navVc = self.navigationController {
                navVc.preferredContentSize.height += (pasteViewHeight + 8.0)
            } else {
                self.preferredContentSize.height += (pasteViewHeight + 8.0)
            }
            let gesture = UITapGestureRecognizer(target: self, action: #selector(pasteFromClipBoard))
            self.pasteFromClipboardView?.addGestureRecognizer(gesture)
        }
    }

    @objc func pasteFromClipBoard() {
        self.dismiss(animated: true, completion: {
            self.delegate?.pasteFromClipBoard?()
        })
    }
    
    @IBAction func lassoTapped(_ sender: UIButton) {
        self.squareBackgroundView.backgroundColor = .clear
        self.squareBackgroundView.removeShadow()

        self.lassoBackgroundView.backgroundColor = UIColor.appColor(.white100)
        self.lassoBackgroundView.layer.cornerRadius = self.lassoBackgroundView.frame.height/2.0
        self.lassoBackgroundView.dropShadowWith(color: UIColor.label.withAlphaComponent(0.12), offset: CGSize(width: 0.0, height: 4.0), radius: 8.0)
        FTRackPreferenceState.lassoSelectionType = 0
    }
    
    @IBAction func squareTapped(_ sender: UIButton) {
        self.lassoBackgroundView.backgroundColor = .clear
        self.lassoBackgroundView.removeShadow()

        self.squareBackgroundView.backgroundColor = UIColor.appColor(.white100)
        self.squareBackgroundView.addShadow(cornerRadius: self.squareBackgroundView.frame.height/2.0, color: UIColor.label.withAlphaComponent(0.12), offset: CGSize(width: 0.0, height: 4.0), opacity: 1.0, shadowRadius: 8.0)
        FTRackPreferenceState.lassoSelectionType = 1
    }
}

//MARK: - Actions
extension FTLassoRackViewController {
    @IBAction func handWritingTapped(_ sender: UISwitch) {
        FTRackPreferenceState.handWriting = sender.isOn
    }
    
    @IBAction func textBoxesTapped(_ sender: UISwitch) {
        FTRackPreferenceState.textBoxes = sender.isOn
    }
    
    @IBAction func photosTapped(_ sender: UISwitch) {
        FTRackPreferenceState.photos = sender.isOn
    }
    
    @IBAction func shapesTapped(_ sender: UISwitch) {
        FTRackPreferenceState.shapes = sender.isOn
    }
}
