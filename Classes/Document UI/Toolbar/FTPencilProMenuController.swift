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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.centerPanelDelegate = self
        self.collectionView.dataSourceItems = FTCurrentToolbarSection().displayTools
        let circularLayout = FTCircularFlowLayout(withCentre: CGPoint(x: 160, y: 160), radius: 120, itemSize: CGSize(width: 50, height: 50), angularSpacing: 10)
        circularLayout.set(startAngle: .pi, endAngle: .pi/4)
        circularLayout.scrollDirection = .horizontal
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
     func drawCollectionViewBackground() {
        let center = CGPoint(x: 160.0, y: 160.0)
        let radius: CGFloat = 120.0
        self.view.layoutIfNeeded()

        let startAngle: CGFloat = .pi
        let endAngle: CGFloat = -.pi / 4
        let menuLayer = FTPencilProMenuLayer()
        menuLayer.setPath(with: center, radius: radius, startAngle: startAngle, endAngle: endAngle)
        let borderLayer = FTPencilProBorderLayer()
        borderLayer.setPath(with: center, radius: radius, startAngle: startAngle, endAngle: endAngle)

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
        // To post notification center panel or to create delegate communication if possible
    }
    
    func currentDeskMode() -> RKDeskMode? {
        return RKDeskMode.deskModePen
    }

    func getScreenMode() -> FTScreenMode {
        return .normal
    }
}
