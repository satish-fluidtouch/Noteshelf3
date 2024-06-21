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
    private var sizeBtn: FTSizeDisplayButton?
    
    // Don't make below viewmodel weak as this is needed for eyedropper delegate to be implemented here(since we are dismissing edit controller)
    internal var presetViewModel: FTFavoritePresetsViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        (self.view as? FTFavoriteProContainerView)?.collectionView = collectionView
        self.manager = FTFavoritePensetManager(activity: activity)
        self.center = CGPoint(x: FTPenSliderConstants.primaryMenuSize.width/2, y: FTPenSliderConstants.primaryMenuSize.height/2)
        self.configureCollectionView()
        self.favorites = self.manager.fetchFavorites()
        self.addSizeDisplayButton()
    }
}

private extension FTFavoriteProViewController {
    func addSizeDisplayButton() {
        let radius: CGFloat = self.config.radius
        let angle: CGFloat = .pi + .pi/45
        let xPosition = self.view.bounds.origin.x + center.x + radius * cos(angle)
        let yPosition = self.view.bounds.origin.y + center.y + radius * sin(angle)
        let buttonSize = CGSize(width: 40, height: 40)
        let sizeBtn = FTSizeDisplayButton(frame: CGRect(x: xPosition - buttonSize.width/2, y: yPosition - buttonSize.height/2, width: buttonSize.width, height: buttonSize.height))
        sizeBtn.addTarget(self, action:  #selector(sizeBtnTapped(_ :)), for: .touchUpInside)
        self.sizeBtn = sizeBtn
        let containerFrame =  sizeBtn.frame.insetBy(dx: -1, dy: -1)
        let container = UIView(frame: containerFrame)
        container.backgroundColor = .clear
        sizeBtn.center = CGPoint(x: container.bounds.midX, y: container.bounds.midY)
        container.addSubview(sizeBtn)
        container.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        container.layer.shadowOpacity = 1
        container.layer.shadowOffset = CGSize(width: 0, height: 0)
        container.layer.shadowRadius = 20.0
        self.view.addSubview(container)
        (self.view as? FTFavoriteProContainerView)?.sizeContainer = container
        self.updateDisplay()
    }

    func configureCollectionView() {
        self.collectionView.mode = .circular
        self.collectionView.interactionDelegate = self
        let circularLayout = FTCircularFlowLayout(withCentre: self.center, config: config)
        let startAngle: CGFloat = .pi - .pi/16
        let endAngle = self.getEndAngle(with: startAngle, with: 7)
        circularLayout.set(startAngle: startAngle, endAngle: endAngle)
        self.collectionView?.collectionViewLayout = circularLayout
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

    @objc func sizeBtnTapped(_ sender : UIButton) {
        let curPenset = self.fetchCurrentPenset()
        let sizeEditVc = FTFavoriteSizeEditController(size: curPenset.preciseSize, penType: curPenset.type, displayMode: .favoriteEdit, activity: self.activity)
        sizeEditVc.delegate = self
        sizeEditVc.ftPresentationDelegate.source = sender
        sizeEditVc.ftPresentationDelegate.sourceRect = sender.bounds
        self.ftPresentPopover(vcToPresent: sizeEditVc, contentSize: CGSize(width: 340.0, height: 80.0), hideNavBar: true)
    }
    
    func getEndAngle(with startAngle: CGFloat, with items: Int) -> CGFloat {
        let endAngle = startAngle - (CGFloat(items) * self.config.angleOfEachItem)
        return endAngle
    }
    
    func reloadFavoritesData() {
        self.collectionView.reloadData()
    }
    
    func handleEditScreenDismissal() {
        let favTuple = self.manager.removeDuplicates(fromFavPenSets: self.favorites)
        self.favorites = favTuple.uniqueElements
        self.manager.saveFavorites(favorites)
        self.updateDisplay()
        if(favTuple.duplicateExists) {
            FTToastHostController.showToast(from: self, toastConfig: FTToastConfiguration(title: "AlreadyInFavorites".localized))
            self.reloadFavoritesData()
        } else {
            if(self.collectionView.isAddingNewPenSet) {
                FTToastHostController.showToast(from: self, toastConfig: FTToastConfiguration(title: "FavoriteAddedNotification".localized))
                self.reloadFavoritesData()
            }
        }
        self.collectionView.isScrollEnabled = true
        self.collectionView.isDisplayedEditPenRack = false
        self.collectionView.isAddingNewPenSet = false
    }
    
    func updateDisplay() {
        let currentPenset = self.fetchCurrentPenset()
        let penType = currentPenset.type
        let reqWidth = penType.getIndicatorSize(using: currentPenset.preciseSize).width
        self.sizeBtn?.displaySize = reqWidth
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
        self.updateDisplay()
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
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: FTFavoriteEditViewController.self))
        guard let controller  = storyboard.instantiateViewController(withIdentifier: "FTFavoriteEditViewController") as? FTFavoriteEditViewController else {
            fatalError("Proggrammer error")
        }
        controller.delegate = self
        controller.favorite = penset
        controller.manager = self.manager
        controller.activity = self.activity
        controller.ftPresentationDelegate.source = sourceView
        controller.ftPresentationDelegate.sourceRect = sourceView.bounds
        controller.ftPresentationDelegate.compactGrabFurther = false
        self.ftPresentPopover(vcToPresent: controller, contentSize: FTFavoriteEditViewController.contentSize, hideNavBar: true)
    }
}

extension FTFavoriteProViewController: FTFavoriteEditDelegate {
    func didChangeFavorite(_ penset: FTPenSetProtocol) {
        if let index = self.collectionView.editFavoriteCurrentIndex, index < self.favorites.count {
            if let currentCell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell {
                currentCell.configure(favorite: penset, currentPenset: penset)
            }
            if(index < self.favorites.count) {
                self.favorites[index] = penset
            } else if index == self.favorites.count {
                self.favorites.append(penset)
            }
            self.manager.saveFavorites(favorites)
            self.updateDisplay()
        }
    }

    func didDeleteFavorite(_ favorite: FTPenSetProtocol) {
        if let index = self.collectionView.editFavoriteCurrentIndex, index < self.favorites.count {
            self.favorites.remove(at: index)
            self.manager.saveFavorites(favorites)
            self.dismiss(animated: false)
            // After removal of favorite, we need to make the one comes in the slot as current penset or, the last one
            if index < self.favorites.count {
                let immediateFav = self.favorites[index]
                self.manager.saveCurrentSelection(penSet: immediateFav)
            } else if let last = self.favorites.last {
                self.manager.saveCurrentSelection(penSet: last)
            }
            self.reloadFavoritesData()
            self.collectionView.isAddingNewPenSet = false
            self.collectionView.isDisplayedEditPenRack = false
            self.collectionView.isScrollEnabled = true
            self.updateDisplay()
        }
    }

    func didDismissEditModeScreen() {
        self.handleEditScreenDismissal()
    }

    func currentFavoriteCount() -> Int {
        return self.favorites.count
    }
}

extension FTFavoriteProViewController: FTFavoriteSizeUpdateDelegate {
    func didChangeSize(_ size: CGFloat) {
        let curPenset = self.fetchCurrentPenset()
        if let size = FTPenSize(rawValue: Int(Float(size))) {
            curPenset.size = size
        }
        curPenset.preciseSize = size
        self.manager.saveCurrentSelection(penSet: curPenset)
        self.updateDisplay()
    }

    func didDismissCurrentsizeEditScreen() {
        self.reloadFavoritesData()
    }
}

extension FTFavoriteProViewController: FTColorEyeDropperPickerDelegate {
    func colorPicker(picker: FTColorEyeDropperPickerController,didPickColor color:UIColor) {
        let hexColor = color.hexString
        if let index = self.collectionView.editFavoriteCurrentIndex, index < self.favorites.count {
            let penset = self.favorites[index]
            penset.color = hexColor
            if let currentCell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell {
                currentCell.configure(favorite: penset, currentPenset: penset)
            }
            if(index < self.favorites.count) {
                self.favorites[index] = penset
                self.manager.saveCurrentSelection(penSet: penset)
            } else if index == self.favorites.count {
                self.favorites.append(penset)
                self.manager.saveCurrentSelection(penSet: penset)
            }
            self.manager.saveFavorites(favorites)
        }
        if let vm = self.presetViewModel {
            vm.updateCurrentSelection(colorHex: hexColor)
            if let editIndex = vm.presetEditIndex {
                vm.updatePresetColor(hex: color.hexString, index: editIndex)
                NotificationCenter.default.post(name: .PresetColorUpdate, object: nil, userInfo: ["type": FTColorToastType.edit.rawValue])
            }
            else {
                vm.addSelectedColorToPresets()
                NotificationCenter.default.post(name: .PresetColorUpdate, object: nil, userInfo: ["type": FTColorToastType.add.rawValue])
            }
            vm.updateCurrentColors()
        }
        self.presetViewModel = nil
    }
}

class FTFavoriteProContainerView: UIView {
    weak var collectionView: UICollectionView?
    weak var hitTestLayer: CAShapeLayer?
    weak var sizeContainer: UIView?
    
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
        if let sizeContainer = self.sizeContainer {
            let convertedPoint = sizeContainer.convert(point, from: self)
            if sizeContainer.bounds.contains(convertedPoint) {
                return sizeContainer.subviews.first
            }
        }
        return collectionView
    }
}

class FTSizeDisplayButton: UIButton {
    var displaySize: CGFloat = 2 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configure()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.size.width / 2
        self.clipsToBounds = true
    }
    
    private func configure() {
        self.backgroundColor = UIColor.appColor(.pencilProMenuBgColor)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let innerRect = CGRect(
            x: (rect.width - displaySize) / 2,
            y: (rect.height - displaySize) / 2,
            width: displaySize,
            height: displaySize
        )
        UIColor.label.setFill()
        context.fillEllipse(in: innerRect)
    }
}
