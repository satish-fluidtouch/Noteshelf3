//
//  FTZoomSettingsViewController.swift
//  Noteshelf
//
//  Created by Amar on 10/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTZoomSettingsViewControllerDelegate: AnyObject {
    func zoomSettingsButtonsPositionChangedAction()
    func zoomSettingsAutoAdvanceSettingsChanged(_ shouldShow: Bool)
    func zoomSettingsMarginPositionChanged(_ newPosition: Int)
    func leftMarginMappedValue(forPercentage percentage: Int) -> CGFloat
    func zoomSettingsDidChangeLineHeight(_ newLineHeight: Int)
}

class FTZoomSettingsViewController: UIViewController {
    weak var delegate: FTZoomSettingsViewControllerDelegate?
    weak var document: FTDocumentProtocol?
    weak var currentPage: FTPageProtocol?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet private weak var leftRightInfoLabel: UILabel?
    @IBOutlet private weak var leftRightSegmentedControl: UISegmentedControl?
    @IBOutlet private weak var marginSlider: UISlider?
    @IBOutlet private weak var marginInfoLabel: UILabel?
    @IBOutlet private weak var marginValueLabel: UILabel?
    @IBOutlet private weak var autoAdvanceInfoLabel: UILabel?
    @IBOutlet private weak var autoAdvanceSwitch: UISwitch?

    @IBOutlet private weak var lineHeightInfoLabel: UILabel?
    @IBOutlet private weak var lineHeightLabel: UILabel?
    @IBOutlet private weak var lineHeightSlider: UISlider?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
        self.updateUI()
    }

    private func configureUI() {
        self.leftRightInfoLabel?.text = NSLocalizedString("ButtonsPosition", comment: "Buttons Position")
        self.marginInfoLabel?.text = NSLocalizedString("MarginPosition", comment:"MarginPosition")
        self.autoAdvanceInfoLabel?.text = NSLocalizedString("AutoAdvance", comment:"Auto Advance")
        self.lineHeightLabel?.text = NSLocalizedString("LineSpacing", comment:"Line Spacing")
        self.lineHeightSlider?.maximumValue = 200
        self.lineHeightSlider?.minimumValue = 0
        self.autoAdvanceSwitch?.isOn = self.document?.localMetadataCache?.zoomPanelAutoAdvanceEnabled ?? false
        self.configureSegmentControl()
        self.configureSlider()
        self.configureTableView()
    }

    private func configureSegmentControl() {
        self.leftRightSegmentedControl?.selectedSegmentIndex = (self.document?.localMetadataCache?.zoomPanelButtonPositionIsLeft ?? false) ? 0 : 1
        self.leftRightSegmentedControl?.setTitle(NSLocalizedString("Left", comment: "Left"), forSegmentAt: 0)
        self.leftRightSegmentedControl?.setTitle(NSLocalizedString("Right", comment: "Right"), forSegmentAt: 1)
    }

    private func configureSlider() {
        self.marginSlider?.minimumValue = 0
        self.marginSlider?.maximumValue = 80
        if let cache = self.document?.localMetadataCache {
            self.marginSlider?.value = Float(cache.zoomLeftMargin)
        }
        else {
            self.marginSlider?.value = 34
        }
    }

    private func configureTableView() {
        self.tableView.setBorderColor(withBorderWidth: 1.0, withColor: UIColor.label.withAlphaComponent(0.04))
        self.tableView.addShadow(cornerRadius: 10.0, color: UIColor.label.withAlphaComponent(0.1), offset: CGSize(width: 0.0, height: 1.0), opacity: 1.0, shadowRadius: 4.0)
    }

    @IBAction private func zoomButtonPositionChangedAction(_ leftRightSegmentedControl:UISegmentedControl) {
        if(leftRightSegmentedControl.selectedSegmentIndex == 0) {
            self.document?.localMetadataCache?.zoomPanelButtonPositionIsLeft = true;
        }
        else {
            self.document?.localMetadataCache?.zoomPanelButtonPositionIsLeft = false;
        }
        UserDefaults.standard.synchronize();
        self.delegate?.zoomSettingsButtonsPositionChangedAction();
    }

    @IBAction private func toggleAutoAdvance(_ sender:Any) {
        if let cache = self.document?.localMetadataCache {
            let autoAdvance = cache.zoomPanelAutoAdvanceEnabled;
            cache.zoomPanelAutoAdvanceEnabled = !autoAdvance;
            self.delegate?.zoomSettingsAutoAdvanceSettingsChanged(!autoAdvance);
        }
    }

    @IBAction private func marginValueDidChange(_ sender:UISlider) {
        self.delegate?.zoomSettingsMarginPositionChanged(Int(sender.value));
        self.updateUI();
    }

    @IBAction private func lineHeightValueDidChange(_ sender:UISlider) {
        let newLineHeight = Int(sender.value);
        self.currentPage?.lineHeight = newLineHeight;
        self.delegate?.zoomSettingsDidChangeLineHeight(newLineHeight);
        self.updateUI();
    }

    func updateUI() {
        if let marginValue = self.marginSlider?.value, let value = self.delegate?.leftMarginMappedValue(forPercentage: Int(marginValue)) {
            self.marginValueLabel?.text = "\(Int(value))"
        }
        if let lineHeight = self.currentPage?.lineHeight {
            self.lineHeightInfoLabel?.text = "\(lineHeight)"
            self.lineHeightSlider?.value = Float(lineHeight)
        }
    }
}
