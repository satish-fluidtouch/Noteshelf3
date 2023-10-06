//
//  FTDeskToolView.swift
//  Noteshelf
//
//  Created by Bharath on 08/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTDeskToolView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet weak var toolButton: UIButton!
    @IBOutlet weak var tintButton: UIButton?
    @IBOutlet private weak var bgButton: FTToolBgButton!

    var toolType: FTDeskCenterPanelTool = .pen
    var deskToolBtnTapHandler: (() -> Void)?

    var isSelected: Bool {
        didSet {
            self.updateToolImageIfNeeded()
            self.showBgIfNeeded()
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

   private func updateToolImageIfNeeded() {
        let image: UIImage!
        if let selImgName = toolType.selectedIconName(), isSelected {
            image = UIImage(named: selImgName)
        } else {
            image = UIImage(named: toolType.iconName())
        }
        self.toolButton.setImage(image, for: .normal)
       self.toolButton?.applyInteraction()
       self.bgButton?.applyInteraction()
       if let tintButton = tintButton{
           self.tintButton?.applyInteraction()
       }

    }

    private func showBgIfNeeded() {
        if isSelected {
            self.bgButton.backgroundColor = UIColor.appColor(.white100)
            self.bgButton.addRequiredShadow()
            if let selImgName = self.toolType.selectedIconName() {
                let img = UIImage(named: selImgName)?.withRenderingMode(.alwaysOriginal)
                self.toolButton.setImage(img, for: .normal)
            }
        } else {
            self.bgButton.backgroundColor = .clear
            self.bgButton?.removeShadow()
            self.bgButton.layer.cornerRadius = 0.0
            if nil != self.toolType.selectedIconName() {
                let img = UIImage(named: self.toolType.iconName())
                self.toolButton.setImage(img, for: .normal)
            }
        }
    }

    func applyTint(color: UIColor) {
        let bgImg = self.toolType.backGroundImage()
        self.bgButton.setImage(bgImg, for: .normal)
        let tintImg = self.toolType.tintImage()
        self.tintButton?.setImage(tintImg, for: .normal)
        self.tintButton?.tintColor = color
        self.toolButton?.applyInteraction()
        self.bgButton?.applyInteraction()
        if let tintButton = tintButton{
            self.tintButton?.applyInteraction()
        }
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
            if isSelected {
                UIView.animate(withDuration: 0.3, animations: {
                    super.isSelected = true
                }) { _ in
                    if self.toolType != .zoomBox {
                        runInMainThread(0.5) {
                            super.isSelected = false
                        }
                    }
                }
            } else {
                super.isSelected = false
            }
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
