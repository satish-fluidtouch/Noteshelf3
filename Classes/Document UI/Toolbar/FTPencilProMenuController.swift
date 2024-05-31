//
//  FTPencilProMenuController.swift
//  Noteshelf3
//
//  Created by Narayana on 29/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPencilProMenuController: UIViewController {
    @IBOutlet private weak var collectionView: FTCenterPanelCollectionView!
    private var size = CGSize.zero

    private let center = CGPoint(x: 250, y: 250)
    private let config = FTCircularLayoutConfig()
    weak var delegate: FTCenterPanelActionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
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
        let menuLayer = FTPencilProMenuLayer(strokeColor: .red.withAlphaComponent(0.7))
        let startAngle: CGFloat = .pi + .pi/30
        let endAngle = self.getEndAngle(with: .pi - .pi/30)
        menuLayer.setPath(with: center, radius: self.config.radius, startAngle: startAngle, endAngle: -endAngle)
        let borderLayer = FTPencilProBorderLayer()
        borderLayer.setPath(with: center, radius: self.config.radius, startAngle: startAngle, endAngle: -endAngle)
        self.view.layer.insertSublayer(borderLayer, at: 0)
        self.view.layer.insertSublayer(menuLayer, at: 1)
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
