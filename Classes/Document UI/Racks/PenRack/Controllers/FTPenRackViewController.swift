//
//  FTPenRackViewController.swift
//  FTPenRack
//
//  Created by Narayana on 12/06/20.
//  Copyright © 2020 Simhachalam Naidu. All rights reserved.
//

import UIKit
import FTStyles

@objc public protocol FTPenRackSelectDelegate: AnyObject {
    func didSelectPenSet(penSet: FTPenSet)
}

@objcMembers class FTPenRackViewController: FTBasePenRackViewController {
    @IBOutlet private weak var pentypeCollectionView: UICollectionView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var holdToConvertToShapeSwitch: UISwitch!
    @IBOutlet private weak var drawStraightLinesSwitch: UISwitch!
    @IBOutlet private weak var convertToShapeView: UIView!
    @IBOutlet private weak var drawStraightLinesView: UIView!

    private let cellIdentifier = "PenType"
    var penTypeRack = FTPenRackViewController.selectedRack

    override class var identifier: String {
        "FTPenRackViewController"
    }
    
    override class var contentSize: CGSize {
        let height = FTPenRackViewController.selectedRack.type == .highlighter ? 290 : 242
        return CGSize(width: 375, height: height)
    }

    private var type: FTRackType {
        return self.penTypeRack.type
    }

    private var penTypeOrder: [FTPenType] {
        return self.type.penTypes
    }
    
    // MARK: - View LifeCycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePenTypeCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let rackType = FTPenRackViewController.selectedRack.type
        self.titleLabel.text = self.penTypeRack.currentPenset.type.name
        self.drawStraightLinesView.isHidden = rackType == .pen
        self.configureOptions()
    }

    private func configureOptions() {
        if type == .pen {
            self.holdToConvertToShapeSwitch?.isOn = FTUserDefaults.isHoldToConvertToShapeOnForPen()
        } else {
            self.drawStraightLinesSwitch?.isOn = FTUserDefaults.isDrawStraightLinesOn()
            self.holdToConvertToShapeSwitch?.isOn = FTUserDefaults.isHoldToConvertToShapeOnForHighlighter()
        }
    }

    private func configurePenTypeCollectionView() {
        self.pentypeCollectionView?.register(UINib.init(nibName: "FTPenTypeCollectionViewCell",
                                                        bundle: Bundle(for: FTPenRackViewController.self)), forCellWithReuseIdentifier: cellIdentifier)
    }
    
    @IBAction func drawStriaghtLinesSwitchChanged(_ sender: Any){
        FTUserDefaults.setDrawStriaghtLinesOption(self.drawStraightLinesSwitch?.isOn ?? false)
    }
    
    @IBAction func holdToConvertToShapeSwitchValueChanged(_ sender: UISwitch) {
        if type == .pen {
            FTUserDefaults.setHoldToConvertToShapeForPen(holdToConvertToShapeSwitch?.isOn ?? false)
        }
        else {
            FTUserDefaults.setHoldToConvertToShapeForHighlighter(holdToConvertToShapeSwitch?.isOn ?? false)
        }
    }
}

// MARK: - DataSource
extension FTPenRackViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        penTypeOrder.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? FTPenTypeCollectionViewCell else {
            fatalError("Programmer error, Couldnot find FTPenTypeCollectionViewCell")
        }
        let penType = self.penTypeOrder[indexPath.item]
        let color = self.penTypeRack.lastSelectedColor(for: penType)
        cell.configure(penType: penType, penSet: penTypeRack.currentPenset, color: color)
        return cell
    }
}

// MARK: - Delegate
extension FTPenRackViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let penType = self.penTypeOrder[indexPath.item]
        let currentPenSet = self.penTypeRack.currentPenset
        if currentPenSet.type == penType {
            return
        }
        self.titleLabel.text = penType.name
        self.penTypeRack.currentPenset.type = penType
        self.penTypeRack.currentPenset.color = self.penTypeRack.lastSelectedColor(for: penType)
        self.penTypeRack.currentPenset.size = self.penTypeRack.lastSelectedPenSize(for: penType).size
        self.penTypeRack.currentPenset.preciseSize = self.penTypeRack.lastSelectedPenSize(for: penType).preciseSize

        self.penTypeRack.saveCurrentSelection()

        // In MAC window scene is coming as UIPopoverscene which is different than notebook-split-controller
        // If window scene is differed, we ll not be able to listen to the notification, so handled like below
        var scene: UIWindowScene?
#if targetEnvironment(macCatalyst)
        scene =  self.parent?.presentingViewController?.view.uiWindowScene // Notebook split view controller - window scene
#else
        scene = self.view?.window?.windowScene
#endif
        NotificationCenter.default.post(name: .penTypeDisplayChange, object: scene, userInfo: ["FTRackData": self.penTypeRack])

        collectionView.indexPathsForVisibleItems.forEach({ (penTypeIndexPath) in
            if let cell = collectionView.cellForItem(at: penTypeIndexPath) as? FTPenTypeCollectionViewCell {
                let penType = self.penTypeOrder[penTypeIndexPath.item]
                let color = self.penTypeRack.lastSelectedColor(for: penType)
                cell.configure(penType: penType, penSet: currentPenSet, color: color)
            }
        })
        
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            collectionView.layoutIfNeeded()
        })
    }
}

// MARK: - DelegateFlowLayout
extension FTPenRackViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellDimension = 72
        let cellCount = self.penTypeOrder.count
        let cellSpacing = 16
        let totalWidth = cellDimension * cellCount
        let totalSpacingWidth = cellSpacing * (cellCount - 1)
        let horizantalInset = (collectionView.frame.width - CGFloat(totalWidth + totalSpacingWidth)) / 2
        let vertInset = (collectionView.frame.height - CGFloat(cellDimension))/2
        return UIEdgeInsets(top: vertInset, left: horizantalInset, bottom: vertInset, right: horizantalInset)
    }
}
