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

    private let center = CGPoint(x: 250, y: 250)
    private let config = FTCircularLayoutConfig()
    weak var delegate: FTPencilProMenuDelegate?

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
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        self.drawCollectionViewBackground()
        self.addUndoRedoViewsIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.size != self.view.frame.size {
            self.size = self.view.frame.size
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.drawCollectionViewBackground()
        }
    }
}

private extension FTPencilProMenuController {
    func addUndoRedoViewsIfNeeded() {
        let centerPoint = self.center
        var radius: CGFloat = self.config.radius
        let angle: CGFloat = .pi - .pi/90
//        if self.delegate?.canPerformUndo() ?? false {
            addButton(isUndo: true)
//        }
//        if self.delegate?.canPerformRedo() ?? false {
            addButton(isUndo: false)
//        }

        func addButton(isUndo: Bool) {
            let button = UIButton(type: .system)
            button.tintColor = UIColor.label
            button.backgroundColor = UIColor.appColor(.finderBgColor)
            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1.0
            
            let buttonSize = CGSize(width: 40, height: 40)
            var imgName = "desk_tool_undo"
            var selector = #selector(undo(_ :))
            if !isUndo {
                radius += 45.0
                imgName = "desk_tool_redo"
                selector = #selector(redo(_ :))
            }
            let xPosition = self.view.frame.origin.x + centerPoint.x + radius * cos(angle)
            let yPosition = self.view.frame.origin.y + centerPoint.y + radius * sin(angle)
            button.setImage(UIImage(named: imgName), for: .normal)
            button.frame = CGRect(x: xPosition - buttonSize.width/2, y: yPosition - buttonSize.height/2, width: buttonSize.width, height: buttonSize.height)
            button.layer.cornerRadius = button.frame.height/2
            button.addTarget(self, action: selector, for: .touchUpInside)
            self.parent?.view.addSubview(button)
        }
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
        let menuLayer = FTPencilProMenuLayer(strokeColor: UIColor.appColor(.finderBgColor))
        let startAngle: CGFloat = .pi + .pi/15
        let endAngle = self.getEndAngle(with: .pi)
        menuLayer.setPath(with: center, radius: self.config.radius, startAngle: startAngle, endAngle: -endAngle)
        let borderLayer = FTPencilProBorderLayer(strokeColor: .black)
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
