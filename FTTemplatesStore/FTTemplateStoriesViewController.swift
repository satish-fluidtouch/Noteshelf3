//
//  FTTemplateStoriesViewController.swift
//  FTTemplatesStore
//
//  Created by Narayana on 21/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTemplateStoriesViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!

    private var imgNames: [String] = ["story1_big", "Image1", "Image2", "Image3", "Image4", "Image5", "Image6", "story1_big", "Image2", "Image3", "Image4", "Image5", "Image6", "story1_big", "Image2", "Image3"]

    private var layout = FTCustomFlowLayout()
    private var size: CGSize = .zero

    class func storiesController() -> FTTemplateStoriesViewController {
        let storyboard = UIStoryboard(name: "FTTemplatesStore", bundle: storeBundle)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "FTTemplateStoriesViewController") as? FTTemplateStoriesViewController else {
            fatalError("Programmer error, unable to find FTTemplateStoriesViewController")
        }
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureCollectionView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.size != self.view.frame.size {
            self.size = self.view.frame.size
            let displayType = FTTemplateStoryDisplayType.currentType(for: self.size)
            self.layout.numberOfColumns = displayType.columnCount
            self.layout.cellPadding = displayType.interSpacing
            self.collectionView.contentInset = displayType.contentInset
            self.layout.clearCache()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.layoutIfNeeded()
            self.collectionView.reloadData()
        }
    }
}

extension FTTemplateStoriesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imgNames.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTTemplateCollectionViewCell", for: indexPath) as? FTTemplateCollectionViewCell else {
            fatalError("No such cell")
        }
        cell.configCell(with: imgNames[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? FTTemplateCollectionViewCell, let img = UIImage(named: imgNames[indexPath.row], in: storeBundle, with: nil) {
            if let splitVc = self.splitViewController {
                let cellFrameInSuperview = cell.convert(cell.imageView.frame, to: splitVc.view)
                FTTemplateWebViewScollController.showFromViewController(splitVc, with: img, initialFrame: cellFrameInSuperview)
            }
        }
    }
}

extension FTTemplateStoriesViewController: FTTemplateLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForImageAtIndexPath indexPath: IndexPath, cellWidth: CGFloat) -> CGFloat {
        var imgHeight: CGFloat = 100
        if let img = UIImage(named: imgNames[indexPath.row], in: storeBundle, compatibleWith: nil) {
            imgHeight = calculateImageHeight(sourceImage: img, scaledToWidth: cellWidth)
        }
        return imgHeight
    }

    func calculateImageHeight (sourceImage: UIImage, scaledToWidth: CGFloat) -> CGFloat {
        let oldWidth = CGFloat(sourceImage.size.width)
        let scaleFactor = scaledToWidth / oldWidth
        let newHeight = CGFloat(sourceImage.size.height) * scaleFactor
        return newHeight
    }
}

private extension FTTemplateStoriesViewController {
    func configureCollectionView() {
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        layout.delegate = self
        self.collectionView.collectionViewLayout = layout
    }
}
