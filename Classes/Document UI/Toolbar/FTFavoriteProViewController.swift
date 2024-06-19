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

    private let config = FTCircularLayoutConfig(radius: 250, itemSize: CGSize(width: 28, height: 28))
    private let center = CGPoint(x: 250, y: 250)

    lazy var primaryMenuHitTestLayer: FTPencilProMenuLayer = {
       return FTPencilProMenuLayer(strokeColor: .clear, lineWidth: 50)
    }()
    lazy var primaryMenuLayer: FTPencilProMenuLayer = {
       return FTPencilProMenuLayer(strokeColor: UIColor.appColor(.pencilProMenuBgColor), lineWidth: 40)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.manager = FTFavoritePensetManager(activity: activity)
        self.configureCollectionView()
        self.favorites = self.manager.fetchFavorites()
    }
}

private extension FTFavoriteProViewController {
    func configureCollectionView() {
        self.collectionView.mode = .circular
        self.collectionView.isPagingEnabled = true
        self.collectionView.interactionDelegate = self
        let circularLayout = FTCircularFlowLayout(withCentre: center, config: config)
        let startAngle: CGFloat = .pi - .pi/30
        let endAngle = self.getEndAngle(with: startAngle)
        circularLayout.set(startAngle: startAngle, endAngle: endAngle)
        self.collectionView?.collectionViewLayout = circularLayout
        self.drawCollectionViewBackground()
    }
    
    func getEndAngle(with startAngle: CGFloat) -> CGFloat {
        let endAngle = startAngle - (CGFloat(7) * self.config.angleOfEachItem)
        return endAngle
    }

    func drawCollectionViewBackground() {
        let startAngle: CGFloat = .pi + .pi/15
        // TODO: Narayana - to be calculated end angle properly using start angle
        let endAngle = self.getEndAngle(with: .pi)
        self.primaryMenuHitTestLayer.setPath(with: center, radius: self.config.radius, startAngle: startAngle, endAngle: -endAngle)
        self.primaryMenuLayer.setPath(with: center, radius: self.config.radius, startAngle: startAngle, endAngle: -endAngle)
        self.primaryMenuLayer.addShadow(offset: CGSize(width: 0, height: 0), radius: 20)
        self.view.layer.insertSublayer(primaryMenuHitTestLayer, at: 0)
        self.view.layer.insertSublayer(primaryMenuLayer, above: primaryMenuHitTestLayer)
        (self.view as? FTPencilProMenuContainerView)?.primaryMenuHitTestLayer = primaryMenuHitTestLayer
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
