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
    func getCurrentDeskMode() -> RKDeskMode
    func updateShapeModel(_ model: FTFavoriteShapeViewModel)
    func updateColorModel(_ model: FTFavoriteColorViewModel)
}

class FTPencilProMenuController: UIViewController {
    @IBOutlet private weak var collectionView: FTCenterPanelCollectionView?
    
    private var size = CGSize.zero
    private let center = CGPoint(x: 250, y: 250)
    private let config = FTCircularLayoutConfig()
    private var undoBtn: FTPencilProUndoButton?
    private var redoBtn: FTPencilProRedoButton?
    private weak var validateToolbarObserver: NSObjectProtocol?

    weak var delegate: FTPencilProMenuDelegate?

    lazy var primaryMenuHitTestLayer: FTPencilProMenuLayer = {
       return FTPencilProMenuLayer(strokeColor: .clear, lineWidth: 50)
    }()
    lazy var primaryMenuLayer: FTPencilProMenuLayer = {
       return FTPencilProMenuLayer(strokeColor: UIColor.appColor(.pencilProMenuBgColor), lineWidth: 40)
    }()

    lazy var secondaryMenuHitTestLayer: FTPencilProMenuLayer = {
       return FTPencilProMenuLayer(strokeColor: .clear, lineWidth: 50)
    }()
    lazy var secondaryMenuLayer: FTPencilProMenuLayer = {
        return FTPencilProMenuLayer(strokeColor: UIColor.appColor(.pencilProMenuBgColor), lineWidth: 40)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        (self.view as? FTPencilProMenuContainerView)?.collectionView = collectionView
        self.configureCollectionView()
        self.addObservers()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        self.showSecondaryMenuIfneeded()
        self.initiateUndoRedoIfNeeded()
    }
    
    deinit {
        if let observer = self.validateToolbarObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.size != self.view.frame.size {
            self.size = self.view.frame.size
            self.collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    func showSecondaryMenuIfneeded() {
        self.removeSecondaryMenuIfExist()
        if let mode = self.delegate?.getCurrentDeskMode(), shouldShowSecondaryMenu(for: mode) {
            self.addSecondaryMenu(with: mode, rect: self.view.bounds)
        }
    }

    func isPointInside(_ point: CGPoint) -> Bool {
        let newPoint = self.view.convert(point, to: self.view)
        if let view = self.view as? FTPencilProMenuContainerView {
            return view.isPointInside(point: newPoint, event: nil)
        }
        return false
    }
}

// Primary Menu
private extension FTPencilProMenuController {
    func configureCollectionView() {
        self.collectionView?.mode = .circular
        self.collectionView?.centerPanelDelegate = self
        self.collectionView?.dataSourceItems = FTCurrentToolbarSection().displayTools
        let circularLayout = FTCircularFlowLayout(withCentre: center, config: config)
        let startAngle: CGFloat = .pi - .pi/30
        let endAngle = self.getEndAngle(with: startAngle)
        circularLayout.set(startAngle: startAngle, endAngle: endAngle)
        self.collectionView?.collectionViewLayout = circularLayout
        self.drawCollectionViewBackground()
        self.collectionView?.isScrollEnabled = false
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.collectionView?.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let collectionView = self.collectionView else { return }
        let translation = gesture.translation(in: collectionView)
        if gesture.state == .changed {
            let decelerationRate: CGFloat = 0.4
            let adjustment = translation.x * decelerationRate
            var proposedOffsetX = collectionView.contentOffset.x - adjustment
            let contentWidth = collectionView.contentSize.width
            let collectionViewWidth = collectionView.bounds.width
            let minOffsetX: CGFloat = 0.0
            let maxOffsetX = contentWidth - collectionViewWidth
            if proposedOffsetX < minOffsetX {
                proposedOffsetX = minOffsetX
            } else if proposedOffsetX > maxOffsetX {
                proposedOffsetX = maxOffsetX
            }
            let adjustedOffset = CGPoint(x: proposedOffsetX, y: collectionView.contentOffset.y)
            if proposedOffsetX >= minOffsetX && proposedOffsetX <= maxOffsetX {
                collectionView.setContentOffset(adjustedOffset, animated: false)
                gesture.setTranslation(.zero, in: collectionView)
            }
        }
    }

    func drawCollectionViewBackground() {
        let startAngle: CGFloat = .pi + .pi/15
        // TODO: Narayana - to be calculated end angle properly using start angle
        let endAngle = self.getEndAngle(with: .pi)
        self.primaryMenuHitTestLayer.setPath(with: center, radius: self.config.radius, startAngle: startAngle, endAngle: -endAngle)
        self.primaryMenuLayer.setPath(with: center, radius: self.config.radius, startAngle: startAngle, endAngle: -endAngle)
        self.primaryMenuLayer.addShadow(offset: CGSize(width: 0, height: 10), radius: 20)
        self.view.layer.insertSublayer(primaryMenuHitTestLayer, at: 0)
        self.view.layer.insertSublayer(primaryMenuLayer, above: primaryMenuHitTestLayer)
        (self.view as? FTPencilProMenuContainerView)?.primaryMenuHitTestLayer = primaryMenuHitTestLayer
    }
}

// Undo Redo
private extension FTPencilProMenuController {
    func addObservers() {
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
    
    func initiateUndoRedoIfNeeded() {
        guard let delegate = self.delegate else { return }
        let canUndo = delegate.canPerformUndo()
        let canRedo = delegate.canPerformRedo()

        if canUndo || canRedo {
            if nil ==  self.undoBtn {
                self.addUndoButton()
            }
            self.undoBtn?.isEnabled = canUndo
        }

        if canRedo {
            if nil == self.redoBtn {
                self.addRedoButton()
            }
            self.redoBtn?.isEnabled = canRedo
        }
    }

    func addUndoButton() {
        let radius: CGFloat = self.config.radius
        let angle: CGFloat = .pi - .pi/90
        let xPosition = self.view.bounds.origin.x + center.x + radius * cos(angle)
        let yPosition = self.view.bounds.origin.y + center.y + radius * sin(angle)
        let buttonSize = CGSize(width: 40, height: 40)
        let undoBtn = FTPencilProUndoButton(frame: CGRect(x: xPosition - buttonSize.width/2, y: yPosition - buttonSize.height/2, width: buttonSize.width, height: buttonSize.height))
        undoBtn.addTarget(self, action:  #selector(undo(_ :)), for: .touchUpInside)
        self.view.addSubview(undoBtn)
        self.undoBtn = undoBtn
        (self.view as? FTPencilProMenuContainerView)?.undoBtn = undoBtn
    }
    
    func addRedoButton() {
        let radius: CGFloat = self.config.radius
        var angle: CGFloat = .pi - .pi/90
        if self.delegate?.canPerformRedo() ?? false {
            angle -= self.config.angleOfEachItem
        }
        let xPosition = self.view.bounds.origin.x + center.x + radius * cos(angle)
        let yPosition = self.view.bounds.origin.y + center.y + radius * sin(angle)
        let buttonSize = CGSize(width: 40, height: 40)
        let redoBtn = FTPencilProRedoButton(frame: CGRect(x: xPosition - buttonSize.width/2, y: yPosition - buttonSize.height/2, width: buttonSize.width, height: buttonSize.height))
        redoBtn.addTarget(self, action:  #selector(redo(_ :)), for: .touchUpInside)
        self.view.addSubview(redoBtn)
        self.redoBtn = redoBtn
        (self.view as? FTPencilProMenuContainerView)?.redoBtn = redoBtn
    }
    
    @objc func undo(_ sender: Any) {
        self.delegate?.performUndo()
    }

    @objc func redo(_ sender: Any) {
        self.delegate?.performRedo()
    }

    func getEndAngle(with startAngle: CGFloat) -> CGFloat {
        guard let collectionView = self.collectionView else {
            return .zero
        }
        var itemsToShow = self.config.maxVisibleItemsCount
        if collectionView.dataSourceItems.count < self.config.maxVisibleItemsCount {
            itemsToShow = collectionView.dataSourceItems.count
        }
        let endAngle = startAngle - (CGFloat(itemsToShow) * self.config.angleOfEachItem)
        return endAngle
    }
}

// Secondary menu
private extension FTPencilProMenuController {
    func removeSecondaryMenuIfExist() {
        self.children.compactMap { $0 as? FTSliderHostingControllerProtocol }.forEach { $0.removeHost() }
        self.secondaryMenuLayer.removeFromSuperlayer()
        self.secondaryMenuHitTestLayer.removeFromSuperlayer()
    }

    func shouldShowSecondaryMenu(for mode: RKDeskMode) -> Bool {
        var status = false
        if mode == .deskModePen || mode == .deskModeMarker || mode == .deskModeShape || mode == .deskModeLaser {
            status = true
        }
        return status
    }

    func addSecondaryMenu(with mode: RKDeskMode, rect: CGRect) {
        guard let parent = self.parent as? FTPDFRenderViewController else {
            return
        }
        var rackType = FTRackType.pen
        if mode == .deskModeMarker {
            rackType = .highlighter
        } else if mode == .deskModeShape {
            rackType = .shape
        } else if mode == .deskModeLaser {
            rackType = .presenter
        }
        let activity = self.view.window?.windowScene?.userActivity
        let rack = FTRackData(type: rackType, userActivity: activity)
        let _colorModel =
        FTFavoriteColorViewModel(rackData: rack, delegate: parent, scene: self.view?.window?.windowScene)
      
        let convertedOrigin = self.view.convert(rect.origin, to: parent.view)
        _colorModel.colorSourceOrigin = convertedOrigin
        self.delegate?.updateColorModel(_colorModel)
        let sizeModel =
        FTFavoriteSizeViewModel(rackData: rack, delegate: parent, scene: self.view?.window?.windowScene)
        
        var items = FTPenSliderConstants.penShortCutItems
        if rack.type == .pen || rack.type == .highlighter {
            let shortcutView = FTPenSliderShortcutView(colorModel: _colorModel, sizeModel: sizeModel)
            let hostingVc = FTPenSliderShortcutHostingController(rootView: shortcutView)
            self.add(hostingVc, frame: rect)
        } else if rack.type == .shape {
            let _shapeModel = FTFavoriteShapeViewModel(rackData: rack, delegate: parent)
            _shapeModel.shapeSourceOrigin = convertedOrigin
            let shortcutView = FTShapeCurvedShortcutView(shapeModel: _shapeModel, colorModel: _colorModel, sizeModel: sizeModel)
            let hostingVc = FTShapeCurvedShortcutHostingController(rootView: shortcutView)
            self.add(hostingVc, frame: rect)
            items = FTPenSliderConstants.shapeShortcutItems
            self.delegate?.updateShapeModel(_shapeModel)
        } else if rack.type == .presenter {
            let shortcutView = FTPresenterSliderShortcutView(viewModel: FTPresenterShortcutViewModel(rackData: rack, delegate: parent))
            let hostingVc = FTPresenterSliderShortcutHostingController(rootView: shortcutView)
            self.add(hostingVc, frame: rect)
            items = FTPenSliderConstants.presenterShortcutItems
        }
        self.drawSecondaryBg(items: items)
    }

    func drawSecondaryBg(items: Int) {
        let startAngle: CGFloat =  .pi + .pi/12
        let endAngle = self.getEndAngle(with: startAngle, with: items)
        let rect = self.view.bounds
        let center = CGPoint(x: rect.midX, y: rect.midY)
        self.secondaryMenuLayer.setPath(with: center, radius: FTPenSliderConstants.sliderRadius, startAngle: startAngle, endAngle: -endAngle)
        self.secondaryMenuLayer.addShadow(offset: CGSize(width: 0, height: -10), radius: 20)
        self.secondaryMenuHitTestLayer.setPath(with: center, radius: FTPenSliderConstants.sliderRadius, startAngle: startAngle, endAngle: -endAngle)
        self.view.layer.insertSublayer(secondaryMenuHitTestLayer, above: primaryMenuLayer)
        self.view.layer.insertSublayer(secondaryMenuLayer, above: secondaryMenuHitTestLayer)
        (self.view as? FTPencilProMenuContainerView)?.secondaryMenuHitTestLayer = secondaryMenuHitTestLayer
    }

    func getEndAngle(with startAngle: CGFloat, with items: Int) -> CGFloat {
        let endAngle = 2 * .pi - (startAngle + (CGFloat(items - 1) * FTPenSliderConstants.spacingAngle.degreesToRadians) + 3.degreesToRadians)
        return endAngle
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
        self.showSecondaryMenuIfneeded()
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
    weak var primaryMenuHitTestLayer: CAShapeLayer?
    weak var secondaryMenuHitTestLayer: CAShapeLayer?

    weak var undoBtn: FTPencilProUndoButton?
    weak var redoBtn: FTPencilProRedoButton?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        guard let collectionView else {
            return hitView
        }
        let collectionViewPoint = self.convert(point, to: collectionView)
        collectionView.layoutIfNeeded()
        for cell in collectionView.visibleCells {
            if cell.frame.contains(collectionViewPoint) {
                let cellPoint = collectionView.convert(collectionViewPoint, to: cell)
                return cell.hitTest(cellPoint, with: event)
            }
        }
        
        if let undoBtn = self.undoBtn, undoBtn.frame.contains(point) {
            return hitView
        }
        
        if let redoBtn = self.redoBtn, redoBtn.frame.contains(point) {
            return hitView
        }
        
        if let layer = primaryMenuHitTestLayer, self.isPointInside(point, lineWidth: layer.lineWidth, radius: 200) {
            return collectionView
        }
        if let layer = secondaryMenuHitTestLayer, self.isPointInside(point, lineWidth: layer.lineWidth, radius: 250) {
            return hitView
        }
        return nil
    }
    
    func isPointInside(_ point: CGPoint, lineWidth: CGFloat, radius: CGFloat) -> Bool {
          let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
          let distanceFromCenter = point.distance(to: center)
          let angle = atan2(point.y - center.y, point.x - center.x)
          let isInRadiusRange = (distanceFromCenter >= radius - lineWidth / 2 && distanceFromCenter <= radius + lineWidth / 2)
          let isInAngleRange = (angle >= -CGFloat.pi && angle <= 0)
          return isInRadiusRange && isInAngleRange
      }

    func isPointInside(point: CGPoint, event: UIEvent?) -> Bool {
        guard let collectionView = collectionView else {
            return false
        }
        var value = false
        collectionView.layoutIfNeeded()
        for cell in collectionView.visibleCells {
            if cell.frame.contains(point) {
                value = true
                break
            }
        }
        return value
    }
}

class FTPencilProButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.tintColor = UIColor.label
        self.backgroundColor = UIColor.appColor(.pencilProMenuBgColor)
        self.layer.cornerRadius = self.frame.height/2
        
        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.16).cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize(width: 0, height: 10)
        self.layer.shadowRadius = 20.0
        self.layer.masksToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FTPencilProUndoButton: FTPencilProButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(UIImage(named: "desk_tool_undo"), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FTPencilProRedoButton: FTPencilProButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(UIImage(named: "desk_tool_redo"), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension CGPath {
    func contains(_ point: CGPoint) -> Bool {
        return self.contains(point, using: .evenOdd, transform: .identity)
    }
}
