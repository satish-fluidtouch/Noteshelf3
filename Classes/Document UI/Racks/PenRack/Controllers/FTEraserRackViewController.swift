//
//  FTEraserRackViewController.swift
//  Noteshelf
//
//  Created by Siva on 08/09/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

@objc public protocol FTEraserRackControllerDelegate: NSObjectProtocol {
    @objc optional func rackViewController(_ rackViewController: FTEraserRackViewController,
                                           didChooseEraserSize size: FTEraseSize)
    @objc optional func didChooseClearPage(_ rackViewController: FTEraserRackViewController)
}

@objcMembers public class FTEraserRackViewController: FTBasePenRackViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var smallSizeView: FTEraserSizeView?
    @IBOutlet private weak var mediumSizeView: FTEraserSizeView?
    @IBOutlet private weak var largeSizeView: FTEraserSizeView?
    @IBOutlet private weak var autosizeView: FTEraserSizeView?
    @IBOutlet private weak var stackView: UIStackView?
    
    @IBOutlet private weak var autoSelectPreviousToolSwitch: UISwitch!
    @IBOutlet private weak var eraseEntireStrokeSwitch: UISwitch!
    @IBOutlet private weak var eraseHighlighterOnlySwitch: UISwitch!
    @IBOutlet private weak var erasePencilOnlySwitch: UISwitch!

    weak var eraserDelegate: FTEraserRackControllerDelegate?

    override class var identifier: String {
        "FTEraserRackViewController"
    }
    
    override class var contentSize: CGSize {
        CGSize(width: 375, height: 479)
    }

    private var size: FTEraseSize! {
        return FTEraseSize(rawValue: UserDefaults.standard.integer(forKey: "FTEraseSize"))
    }

    //MARK: - View Life cycle methods, configurations
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "notebook.eraserRack.NavTitle".localized
        self.configureEraserButtons()
        self.activatePanGesture()
        self.validateEraserButtons()
        self.initPreferences()
    }
    
    private func initPreferences() {
        let autoSelectValue = FTUserDefaults.shouldAutoSelectPreviousTool()
        self.autoSelectPreviousToolSwitch.setOn(autoSelectValue, animated: true)

        let eraseEntireValue = FTUserDefaults.shouldEraseEntireStroke()
        self.eraseEntireStrokeSwitch.setOn(eraseEntireValue, animated: true)

        let eraseHighlighterValue = FTUserDefaults.shouldEraseHighlighterOnly()
        self.eraseHighlighterOnlySwitch.setOn(eraseHighlighterValue, animated: true)

        let erasePencilValue = FTUserDefaults.shouldErasePencilOnly()
        self.erasePencilOnlySwitch.setOn(erasePencilValue, animated: true)
    }

    //MARK: - Static function
    public static func eraserSize() -> FTEraseSize  {
        let currentSize = UserDefaults.standard.integer(forKey: "FTEraseSize")
        let eraserSize = FTEraseSize.init(rawValue: currentSize)
        return eraserSize!
    }

    private func configureEraserButtons() {
        self.smallSizeView?.size = .small
        self.mediumSizeView?.size = .medium
        self.largeSizeView?.size = .large
        self.autosizeView?.size = .auto
    }

    //MARK: - validate methods
    fileprivate func validateEraserButtons() {
        self.smallSizeView?.isSelected = false
        self.mediumSizeView?.isSelected = false
        self.largeSizeView?.isSelected = false
        self.autosizeView?.isSelected = false
        
        let eraserSize = FTEraserRackViewController.eraserSize()
        switch eraserSize {
        case .small:
            self.smallSizeView?.isSelected = true
        case .medium:
            self.mediumSizeView?.isSelected = true
        case .large:
            self.largeSizeView?.isSelected = true
        case .auto:
            self.autosizeView?.isSelected = true
        }
    }

    // MARK: - IBActions
    @IBAction private func sizeButtonClicked(sizeButton: UIButton) {
        var eraserSize = FTEraseSize.init(rawValue: sizeButton.tag)
        if(nil == eraserSize) {
            eraserSize = FTEraseSize.auto
        }
        let userDefaults = UserDefaults.standard
        userDefaults.set(eraserSize!.rawValue, forKey: "FTEraseSize")
        userDefaults.synchronize()

        self.validateEraserButtons()
        self.eraserDelegate?.rackViewController?(self, didChooseEraserSize: self.size)
    }
}

// MARK: - Actions
extension FTEraserRackViewController {
    @IBAction func autoSelectPreviousToolTapped(_ sender: UISwitch) {
        let value = FTUserDefaults.shouldAutoSelectPreviousTool()
        FTUserDefaults.saveAutoSelectPreviousToolTo(!value)
    }
    
    @IBAction func eraseEntireStrokeTapped(_ sender: UISwitch) {
        let value = FTUserDefaults.shouldEraseEntireStroke()
        FTUserDefaults.saveEraseEntireStrokeTo(!value)
    }
    
    @IBAction func eraseHighlighterOnlyTapped(_ sender: UISwitch) {
        let value = FTUserDefaults.shouldEraseHighlighterOnly()
        FTUserDefaults.saveEraseHighlighterOnlyTo(!value)
    }
    
    @IBAction func erasePencilOnlyTapped(_ sender: UISwitch) {
        let value = FTUserDefaults.shouldErasePencilOnly()
        FTUserDefaults.saveErasePencilOnlyTo(!value)
    }

    @IBAction func clearPageTapped(_ sender: UIButton) {
        self.popoverPresentationController?.passthroughViews = nil
        self.eraserDelegate?.didChooseClearPage?(self)
    }
}

// MARK: - Gesture handling
extension FTEraserRackViewController{
    func activatePanGesture(){
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(FTEraserRackViewController.handlePanGesture(_:)))
        self.stackView?.addGestureRecognizer(panGesture)
    }

    @objc func handlePanGesture(_ panGesture:UIPanGestureRecognizer){
        switch (panGesture.state) {
        case .changed:
            let touchPoint = panGesture.location(in: panGesture.view!)
            self.stackView?.arrangedSubviews.forEach { (sizeView) in
                if sizeView.frame.contains(touchPoint){
                    (sizeView as! FTEraserSizeView).sizeButton.sendActions(for: UIControl.Event.touchUpInside)
                }
            }
        default:
            break
        }
    }
}
