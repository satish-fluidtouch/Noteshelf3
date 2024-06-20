//
//  FTFavoriteProViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 19/06/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTFavoriteProViewController: UIViewController {
    @IBOutlet private weak var collectionView: FTFavoritebarCollectionView!
    
    private var favorites: [FTPenSetProtocol] = []
    private var manager = FTFavoritePensetManager(activity: nil)
    var activity: NSUserActivity?

    private let config = FTCircularLayoutConfig(angleOfEachItem: 10.degreesToRadians, radius: 250.0, itemSize: CGSize(width: 28, height: 28))
    private var center = CGPoint.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        (self.view as? FTFavoriteProContainerView)?.collectionView = collectionView
        self.manager = FTFavoritePensetManager(activity: activity)
        self.center = CGPoint(x: FTPenSliderConstants.primaryMenuSize.width/2, y: FTPenSliderConstants.primaryMenuSize.height/2)
        self.configureCollectionView()
        self.favorites = self.manager.fetchFavorites()
    }
}

private extension FTFavoriteProViewController {
    func configureCollectionView() {
        self.collectionView.mode = .circular
        self.collectionView.isPagingEnabled = true
        self.collectionView.interactionDelegate = self
        let circularLayout = FTCircularFlowLayout(withCentre: self.center, config: config)
        let startAngle: CGFloat = .pi - .pi/16
        let endAngle = self.getEndAngle(with: startAngle, with: 7)
        circularLayout.set(startAngle: startAngle, endAngle: endAngle)
        self.collectionView?.collectionViewLayout = circularLayout
    }
    
    func getEndAngle(with startAngle: CGFloat, with items: Int) -> CGFloat {
        let endAngle = startAngle - (CGFloat(items) * self.config.angleOfEachItem)
        return endAngle
    }
}

extension FTFavoriteProViewController: FTFavoritebarDelegate {
    func getFavorites() -> [FTPenSetProtocol] {
        return self.favorites
    }
    
    func getSavedPlacement() -> FTShortcutPlacement? {
        let placement = FTShortcutPlacement.getSavedPlacement(activity: self.activity)
        return placement
    }

    func updateSizeDisplay()  {
//        return self.updateDisplay()
    }
    
    func saveFavorites(_ favorites: [FTPenSetProtocol]) {
        self.favorites = favorites
        self.manager.saveFavorites(favorites)
    }
    
    func saveCurrentSelection(penset: FTPenSetProtocol) {
        self.manager.saveCurrentSelection(penSet: penset)
    }
    
    func fetchCurrentPenset() -> FTPenSetProtocol {
        return self.manager.fetchCurrentPenset()
    }

    func displayMaximumFavoritesAlert() {
       let titleString = "MaximumFavoritesWarningTitle".localized
       let messageString = "MaximumFavoritesWarning".localized
       let okString = "OK".localized

       let alert = UIAlertController(title: titleString, message: messageString, preferredStyle: UIAlertController.Style.alert)
       alert.addAction(UIAlertAction(title: okString, style: .default, handler: nil))
       self.present(alert, animated: true, completion: nil)
   }
    
    func showFavoriteEditScreen(with penset: FTPenSetProtocol, sourceView: UIView) {
//        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: FTFavoriteEditViewController.self))
//        guard let controller  = storyboard.instantiateViewController(withIdentifier: "FTFavoriteEditViewController") as? FTFavoriteEditViewController else {
//            fatalError("Proggrammer error")
//        }
//        controller.delegate = self
//        controller.favorite = penset
//        controller.manager = self.manager
//        controller.activity = self.activity
//        controller.ftPresentationDelegate.source = sourceView
//        var rect = sourceView.bounds
//        let placement = FTShortcutPlacement.getSavedPlacement(activity: self.activity)
//        // To fix the arrow position
//        let offset: CGFloat = 8.0
//        if placement == .top || placement.isRightPlacement() {
//            rect.origin.y += offset
//        } else if placement.isLeftPlacement() {
//            rect.origin.y -= offset
//        }
//        controller.ftPresentationDelegate.sourceRect = rect
//        controller.ftPresentationDelegate.compactGrabFurther = false
//        self.ftPresentPopover(vcToPresent: controller, contentSize: FTFavoriteEditViewController.contentSize, hideNavBar: true)
    }
}

class FTFavoriteProContainerView: UIView {
    weak var collectionView: UICollectionView?
    weak var hitTestLayer: CAShapeLayer?
    
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
        return collectionView
    }
    
    func isPointInside(_ point: CGPoint, lineWidth: CGFloat, radius: CGFloat) -> Bool {
          let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
          let distanceFromCenter = point.distance(to: center)
          let angle = atan2(point.y - center.y, point.x - center.x)
          let isInRadiusRange = (distanceFromCenter >= radius - lineWidth / 2 && distanceFromCenter <= radius + lineWidth / 2)
          let isInAngleRange = (angle >= -CGFloat.pi && angle <= 0)
          return isInRadiusRange && isInAngleRange
      }
}
