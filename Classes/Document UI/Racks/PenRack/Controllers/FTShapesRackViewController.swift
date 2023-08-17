//
//  FTShapesRackViewController.swift
//  Noteshelf
//
//  Created by srinivas on 06/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

@objcMembers public class FTShapesRackViewController: FTBasePenRackViewController {
    @IBOutlet private weak var shapesTitle: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var infoLabel: UILabel!

    let cellIdentifier = "shapeCell"
    weak var shapeEditDelegate: FTShapeSelectDelegate?

    override class var identifier: String {
        "FTShapesRackViewController"
    }
    
    class override var contentSize: CGSize {
        CGSize(width: 375, height: 268)
    }
    
    var penTypeRack = FTPenRackViewController.selectedRack
    
    private var shapes : [FTShapeType] {
        return penTypeRack.type.shapeTypes
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let title = NSLocalizedString("notebook.shapesRack.NavTitle", comment: "SHAPES")
        shapesTitle.text = title
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.shapeEditDelegate?.saveFavoriteShapes()
    }
}

// MARK :- DataSource
extension FTShapesRackViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        shapes.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? FTShapeCollectionViewCell else {
            fatalError("Failed to create Cell!")
        }
        cell.penRack = penTypeRack
        cell.configure(with: shapes[indexPath.row])
        return cell
    }
}

// MARK : - Delegate
extension FTShapesRackViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.indexPathsForVisibleItems.forEach({ index in
            if let cell = collectionView.cellForItem(at: index) as? FTShapeCollectionViewCell {
                cell.isSelected ? cell.select() : cell.deSelect()
            }
        })

        let shape = shapes[indexPath.row]
        shape.saveSelection()
        self.shapeEditDelegate?.didSelectShape(shape: shape)
        dismiss(animated: true)
    }
}
