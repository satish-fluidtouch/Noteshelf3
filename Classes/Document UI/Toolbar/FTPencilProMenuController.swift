//
//  FTPencilProMenuController.swift
//  Noteshelf3
//
//  Created by Narayana on 29/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTPencilProMenuDelegate: FTCenterPanelActionDelegate {
    func canPerformUndo() -> Bool
    func performUndo()
    func canPerformRedo() -> Bool
    func performRedo()
}

class FTPencilProMenuController: UIViewController {
    @IBOutlet private weak var collectionView: FTCenterPanelCollectionView!
    private var size = CGSize.zero
    private weak var validateToolbarObserver: NSObjectProtocol?

    private let center = CGPoint(x: 250, y: 250)
    private let config = FTCircularLayoutConfig()
    weak var delegate: FTPencilProMenuDelegate? {
        didSet {
            self.initiateUndoRedoIfNeeded()
        }
    }
    private var undoBtn: FTPencilProUndoButton?
    private var redoBtn: FTPencilProRedoButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        (self.view as? FTPencilProMenuContainerView)?.collectionView = collectionView
        self.collectionView.mode = .circular
        self.collectionView.centerPanelDelegate = self
        self.collectionView.dataSourceItems = FTCurrentToolbarSection().displayTools
        let circularLayout = FTCircularFlowLayout(withCentre: center, config: config)
        let startAngle: CGFloat = .pi - .pi/30
        let endAngle = self.getEndAngle(with: startAngle)
        circularLayout.set(startAngle: startAngle, endAngle: endAngle)
        self.collectionView.collectionViewLayout = circularLayout

        self.validateToolbarObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTValidateToolBarNotificationName), object: nil, queue: .main) { [weak self] notification in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.view.window == notification.object as? UIWindow {
                let undoStatus = strongSelf.delegate?.canPerformUndo() ?? false
                if undoStatus && nil == strongSelf.undoBtn {
                    strongSelf.addUndoButton()
                }
                strongSelf.undoBtn?.isEnabled = undoStatus
                let redoStatus = strongSelf.delegate?.canPerformRedo() ?? false
                if redoStatus && nil == strongSelf.redoBtn {
                    strongSelf.addRedoButton()
                }
                strongSelf.redoBtn?.isEnabled = redoStatus
            }
        }
    }

    deinit {
        if let observer = self.validateToolbarObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        self.drawCollectionViewBackground()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.size != self.view.frame.size {
            self.size = self.view.frame.size
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
}

private extension FTPencilProMenuController {
    func initiateUndoRedoIfNeeded() {
        var toShow = false
        if let canUndo = self.delegate?.canPerformUndo(), let canRedo = self.delegate?.canPerformRedo() {
             toShow = canUndo || canRedo
        }
        if toShow {
            self.undoBtn?.removeFromSuperview()
            self.addUndoButton()
            let undoStatus = self.delegate?.canPerformUndo() ?? false
            self.undoBtn?.isEnabled = undoStatus
        }
        if self.delegate?.canPerformRedo() ?? false {
            self.redoBtn?.removeFromSuperview()
            self.addRedoButton()
            let redoStatus = self.delegate?.canPerformRedo() ?? false
            self.redoBtn?.isEnabled = redoStatus
        }
    }

    func addUndoButton() {
        let radius: CGFloat = self.config.radius
        let angle: CGFloat = .pi - .pi/90
        let xPosition = self.view.frame.origin.x + center.x + radius * cos(angle)
        let yPosition = self.view.frame.origin.y + center.y + radius * sin(angle)
        let buttonSize = CGSize(width: 40, height: 40)
        let undoBtn = FTPencilProUndoButton(frame: CGRect(x: xPosition - buttonSize.width/2, y: yPosition - buttonSize.height/2, width: buttonSize.width, height: buttonSize.height))
        undoBtn.addTarget(self, action:  #selector(undo(_ :)), for: .touchUpInside)
        self.parent?.view.addSubview(undoBtn)
        self.undoBtn = undoBtn
    }
    
    func addRedoButton() {
        let radius: CGFloat = self.config.radius
        var angle: CGFloat = .pi - .pi/90
        if self.delegate?.canPerformUndo() ?? false {
            angle -= self.config.angleOfEachItem
        }
        let xPosition = self.view.frame.origin.x + center.x + radius * cos(angle)
        let yPosition = self.view.frame.origin.y + center.y + radius * sin(angle)
        let buttonSize = CGSize(width: 40, height: 40)
        let redoBtn = FTPencilProRedoButton(frame: CGRect(x: xPosition - buttonSize.width/2, y: yPosition - buttonSize.height/2, width: buttonSize.width, height: buttonSize.height))
        redoBtn.addTarget(self, action:  #selector(redo(_ :)), for: .touchUpInside)
        self.parent?.view.addSubview(redoBtn)
        self.redoBtn = redoBtn
    }
    
    @objc func undo(_ sender: Any) {
        self.delegate?.performUndo()
    }

    @objc func redo(_ sender: Any) {
        self.delegate?.performRedo()
    }

    func getEndAngle(with startAngle: CGFloat) -> CGFloat {
        var itemsToShow = self.config.maxVisibleItemsCount
        if self.collectionView.dataSourceItems.count < self.config.maxVisibleItemsCount {
            itemsToShow = self.collectionView.dataSourceItems.count
        }
        let endAngle = startAngle - (CGFloat(itemsToShow) * self.config.angleOfEachItem)
        return endAngle
    }

    func drawCollectionViewBackground() {
        self.view.layoutIfNeeded()
        let menuLayer = FTPencilProMenuLayer(strokeColor: UIColor.init(hexString: "#E8E8E8"))
        let startAngle: CGFloat = .pi + .pi/15
        let endAngle = self.getEndAngle(with: .pi)
        menuLayer.setPath(with: center, radius: self.config.radius, startAngle: startAngle, endAngle: -endAngle)
        let borderLayer = FTPencilProBorderLayer(strokeColor: UIColor.init(hexString: "#CECECE"))
        borderLayer.setPath(with: center, radius: self.config.radius, startAngle: startAngle, endAngle: -endAngle)
        self.view.layer.insertSublayer(borderLayer, at: 0)
        self.view.layer.insertSublayer(menuLayer, at: 1)
        (self.view as? FTPencilProMenuContainerView)?.menuLayer = menuLayer
        (self.view as? FTPencilProMenuContainerView)?.borderLayer = borderLayer
    }
}

extension FTPencilProMenuController: FTCenterPanelCollectionViewDelegate {
    func isZoomModeEnabled() -> Bool {
        return false
    }
    
    func maxCenterPanelItemsToShow() -> Int {
        return 7
    }
    
    func didTapCenterPanelButton(type: FTDeskCenterPanelTool, sender: UIView) {
        self.delegate?.didTapCenterPanelTool(type, source: sender)
    }
    
    func currentDeskMode() -> RKDeskMode? {
        var deskMode = RKDeskMode.deskModePen
        if let parent = self.parent as? FTPDFRenderViewController {
            deskMode = parent.currentDeskMode
        }
        return deskMode
    }

    func getScreenMode() -> FTScreenMode {
        return .normal
    }
}

final class FTPencilProMenuContainerView: UIView {
    weak var collectionView: UICollectionView?
    weak var menuLayer: CALayer?
    weak var borderLayer: CALayer?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let collectionView else {
            return super.hitTest(point, with: event)
        }
        let collectionViewPoint = self.convert(point, to: collectionView)
        collectionView.layoutIfNeeded()
        for cell in collectionView.visibleCells {
            if cell.frame.contains(collectionViewPoint) {
                let cellPoint = collectionView.convert(collectionViewPoint, to: cell)
                return cell.hitTest(cellPoint, with: event)
            }
        }
        if let firstLayer = menuLayer, firstLayer.frame.contains(point) {
            return collectionView
        }
        if let secondLayer = borderLayer, secondLayer.frame.contains(point) {
            return collectionView
        }
        return nil
    }
}

final class FTPencilProUndoButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(UIImage(named: "desk_tool_undo"), for: .normal)
        self.tintColor = UIColor.label
        self.backgroundColor = UIColor.appColor(.finderBgColor)
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = self.frame.height/2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FTPencilProRedoButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(UIImage(named: "desk_tool_redo"), for: .normal)
        self.tintColor = UIColor.label
        self.backgroundColor = UIColor.appColor(.finderBgColor)
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = self.frame.height/2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
