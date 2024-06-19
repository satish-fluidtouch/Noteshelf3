//
//  FTDeskToolView.swift
//  Noteshelf
//
//  Created by Bharath on 08/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon
import Foundation

class FTDeskToolView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet weak var toolButton: UIButton!
    @IBOutlet weak var tintButton: UIButton?
    @IBOutlet private weak var bgButton: FTToolBgButton!

    var toolType: FTDeskCenterPanelTool = .pen
    var deskToolBtnTapHandler: (() -> Void)?

    var isSelected: Bool {
        didSet {
            if toolType.toolDisplayStyle == .style1 {
                self.updateToolImageIfNeeded()
                self.updateBackground()
            }
        }
    }

  override init(frame: CGRect) {
        self.isSelected = false
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        self.isSelected = false
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("FTDeskToolView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        self.toolButton.imageView?.contentMode = .scaleAspectFit
        self.bgButton.imageView?.contentMode = .scaleAspectFit
        self.tintButton?.imageView?.contentMode = .scaleAspectFit

        let pointerInteraction = UIPointerInteraction(delegate: self)
        self.addInteraction(pointerInteraction)
    }

    func updateToolImageIfNeeded() {
        if let selImgName = toolType.selectedIconName(), isSelected {
            self.toolButton.setImage(named: selImgName, for: .normal,renderMode: .alwaysOriginal);
        } else {
            self.toolButton.setImage(named: toolType.iconName(), for: .normal);
        }
    }

    func updateBackground(status: Bool) {
        if status {
            self.setBackGround()
        } else {
            self.clearBackground()
        }
    }
    
    private func setBackGround() {
        self.bgButton.backgroundColor = self.toolType.displayBgColorStyle()
        self.bgButton.addRequiredShadow()
    }
    
    private func clearBackground() {
        self.bgButton.backgroundColor = .clear
        self.bgButton?.removeShadow()
        self.bgButton.layer.cornerRadius = 0.0
    }
    
    private func updateBackground() {
        if isSelected {
            self.setBackGround()
            if let selImgName = self.toolType.selectedIconName() {
                self.toolButton.setImage(named: selImgName, for: .normal, renderMode: .alwaysOriginal);
            }
        } else {
            self.clearBackground()
            if nil != self.toolType.selectedIconName() {
                self.toolButton.setImage(named: self.toolType.iconName(), for: .normal);
            }
        }
    }

    func applyTint(color: UIColor) {
        let bgImg = self.toolType.backGroundImage()
        self.bgButton.setImage(bgImg, for: .normal)
        let tintImg = self.toolType.tintImage()
        self.tintButton?.setImage(tintImg, for: .normal)
        self.tintButton?.tintColor = color
    }

     func resetTint() {
        self.bgButton.setImage(nil, for: .normal)
        self.tintButton?.setImage(nil, for: .normal)
        self.tintButton?.tintColor = .clear
    }

    @IBAction func deskToolButtonTapped(_ sender: Any) {
        self.deskToolBtnTapHandler?()
    }
}

class FTDeskShortcutView: FTDeskToolView {
    override var toolType: FTDeskCenterPanelTool {
        didSet {
            if toolType == .zoomBox {
                NotificationCenter.default.addObserver(self, selector: #selector(enterZoomModeNotified), name: NSNotification.Name(FTAppDidEnterZoomMode), object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(exitZoomModeNotified(_:)), name: NSNotification.Name(FTAppDidEXitZoomMode), object: nil)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    private func initialize() {
        self.tintButton?.isHidden = true
        self.isSelected = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func enterZoomModeNotified() {
        if self.toolType == .zoomBox {
            self.isSelected = true
        }
    }

    @objc func exitZoomModeNotified(_ notification: Notification) {
        if self.toolType == .zoomBox {
            self.isSelected = false
        }
    }
    
    override var isSelected: Bool {
        didSet {
            switch self.toolType.toolDisplayStyle {
            case .style1:
                super.isSelected = isSelected
            case .style3,.style2:
                self.currentStateTool = isSelected
            }
        }
    }
    
    var currentStateTool: Bool = false{
        didSet {
            super.updateToolImageIfNeeded()
        }
    }
        
    var isPopoverTool: Bool = false{
        didSet {
            super.updateToolImageIfNeeded()
        }
    }
}

final class FTToolBgButton: UIButton {
    func addRequiredShadow() {
        self.layer.masksToBounds = false
        self.layer.shadowOpacity = 0.0
        self.layer.cornerRadius = 7.0
        self.layer.shadowColor = UIColor.label.withAlphaComponent(0.12).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 8.0
        let reqBounds = self.bounds.insetBy(dx: 4.0, dy: 8.0)
        self.layer.shadowPath = UIBezierPath(roundedRect: reqBounds, cornerRadius: 7).cgPath
    }
}

extension FTDeskToolView: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        if let superView = superview {
            let target = UIDragPreviewTarget(container: superView, center: center)
            let targetedPreview = UITargetedPreview(view: self.toolButton, parameters: UIPreviewParameters(), target: target)
            let pointerEffect = UIPointerEffect.highlight(targetedPreview)
            return UIPointerStyle(effect: pointerEffect)
        }
        return nil
    }
}

private extension UIButton {
    func setImage(named: String?, for state: UIControl.State,renderMode: UIImage.RenderingMode? = nil) {
        var image: UIImage?
        if let _imgName = named {
            image = UIImage(named: _imgName,in: nil, compatibleWith: self.traitCollection)
        }
        if let _renderMode = renderMode {
            image = image?.withRenderingMode(_renderMode)
        }
        self.setImage(image, for: state)
    }
    
}
