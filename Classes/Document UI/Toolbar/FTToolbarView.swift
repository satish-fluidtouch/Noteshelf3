//
//  FTToolbarView.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 04/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

struct FTToolBarConstants {
    static var statusBarOffset: CGFloat  {
        return UserDefaults.standard.showStatusBar ? 8 : 0;
    }
    static let yOffset: CGFloat = 14;
    static let subtoolbarOffset: CGFloat = 8; //used for audio player
}


class FTToolbarView: UIView {
    weak var deskToolbarController: FTiOSDeskToolbarController?

    var screenMode: FTScreenMode = .normal {
        didSet {
            self.updateUIConfig()
        }
    }

    func addToolbar() -> FTiOSDeskToolbarController? {
#if !targetEnvironment(macCatalyst)
        let storyboard = UIStoryboard(name: "FTDocumentView", bundle: nil)
        guard let toolbarVc = storyboard.instantiateViewController(withIdentifier: "FTiOSDeskToolbarController") as? FTiOSDeskToolbarController else {
            return nil
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        toolbarVc.view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(toolbarVc.view)
        toolbarVc.view.addEqualConstraintsToView(toView: self)
        self.deskToolbarController = toolbarVc
        return toolbarVc
#else
        return nil
#endif
    }

    private var leftPanel: FTToolbarVisualEffectView? {
        return self.deskToolbarController?.visualEffectView(for: .left)
    }

    private var rightPanel: FTToolbarVisualEffectView? {
        return self.deskToolbarController?.visualEffectView(for: .right)
    }

    private var centerPanel: FTToolbarVisualEffectView? {
        return self.deskToolbarController?.visualEffectView(for: .center)
    }

    private weak var pageLayoutObserver: NSObjectProtocol?;
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.pageLayoutObserver = NotificationCenter.default.addObserver(forName: .pageLayoutDidChange,
                                               object: nil,
                                               queue: nil)
        { [weak self] (_) in
            guard let strongSelf = self else {
                return;
            }
            strongSelf.updateUIConfig()
            strongSelf.deskToolbarController?.didChangePageLayout();
        }
    }

    deinit {
        if let observer = pageLayoutObserver {
            NotificationCenter.default.removeObserver(observer);
        }
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.screenMode == .shortCompact || UserDefaults.standard.pageLayoutType == .horizontal {
            return super.hitTest(point, with: event)
        } else {
            if let leftpanel = self.leftPanel, let leftSuperView = leftpanel.superview {
                let newPoint = self.convert(point, to: leftSuperView)
                if leftpanel.frame.contains(newPoint) {
                    return super.hitTest(point, with: event)
                }
            }

            if let rightpanel = self.rightPanel, let rightSuperView = rightpanel.superview {
                let newPoint = self.convert(point, to: rightSuperView)
                if rightpanel.frame.contains(newPoint) {
                    return super.hitTest(point, with: event)
                }
            }

            if let centerpanel = self.centerPanel, let centerSuperView = centerpanel.superview {
                let newPoint = self.convert(point, to: centerSuperView)
                if centerpanel.frame.contains(newPoint) {
                    return super.hitTest(point, with: event)
                }
            }
            return nil
        }
    }

    private func updateUIConfig() {
        let layoutType = UserDefaults.standard.pageLayoutType

        guard let leftPanelBlurView = self.leftPanel, let rightPanelBlurView = self.rightPanel, let centerPanelBlurView = self.centerPanel, let dividerView = self.deskToolbarController?.dividerLine else {
            return
        }
        if self.screenMode == .normal {
            if layoutType == .horizontal {
                self.backgroundColor = FTToolbarConfig.stickyBgColor
                self.addVisualEffectBlur(cornerRadius: 0.0)
                dividerView.isHidden = false
                leftPanelBlurView.clearStyling()
                centerPanelBlurView.clearStyling()
                rightPanelBlurView.clearStyling()
            } else {
                self.backgroundColor = .clear
                self.removeVisualEffectBlur()
                dividerView.isHidden = true
                leftPanelBlurView.stylePanel()
                centerPanelBlurView.stylePanel()
                rightPanelBlurView.stylePanel()
            }
        } else if self.screenMode == .shortCompact {
            leftPanelBlurView.clearStyling()
            centerPanelBlurView.clearStyling()
            rightPanelBlurView.clearStyling()
            dividerView.isHidden = false
            self.backgroundColor = FTToolbarConfig.stickyBgColor
            self.addVisualEffectBlur(cornerRadius: 0.0)
        }
    }
}

class FTFocusModeView: FTToolbarVisualEffectView {
    private var keyValueObserver: NSKeyValueObservation?;
    let size = CGSize(width: 44.0, height: 44.0)
    func styleView() {
        super.stylePanel()
        self.layer.masksToBounds = true
        self.frame.size = size
        self.keyValueObserver = UserDefaults.standard.observe(\.showStatusBar, options: [.new]) { [weak self] (userdefaults, change) in
            if let strongSelf = self {
                var frame = strongSelf.frame;
                frame.origin.y = strongSelf.topOffset;
                strongSelf.frame = frame;
            }
        }
    }

    deinit {
        self.keyValueObserver?.invalidate();
        self.keyValueObserver = nil;
    }
    
    var topOffset: CGFloat {
        var offset: CGFloat = FTToolBarConstants.yOffset
        if UIDevice.current.isPhone() {
            if let window = UIApplication.shared.keyWindow {
                let topSafeAreaInset = window.safeAreaInsets.top
                if topSafeAreaInset > 0 {
                    offset += topSafeAreaInset
                }
            }
        }
        else {
            offset += FTToolBarConstants.statusBarOffset
        }
        return offset
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event)
    }
}

class FTToolbarVisualEffectView: UIVisualEffectView {
    func stylePanel() {
        let blurEffect = UIBlurEffect(style: .regular)
        self.effect = blurEffect
        self.backgroundColor = FTToolbarConfig.bgColor
        self.layer.borderWidth = FTToolbarConfig.borderWidth
        self.layer.cornerRadius = FTToolbarConfig.cornerRadius
        self.layer.borderColor = FTToolbarConfig.borderColor.cgColor
    }

    func clearStyling() {
        self.effect = nil
        self.backgroundColor = .clear
        self.layer.borderWidth = 0.0
        self.layer.cornerRadius = 0.0
    }
}
