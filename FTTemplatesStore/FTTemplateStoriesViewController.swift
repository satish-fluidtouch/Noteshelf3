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

    private var size: CGSize = .zero
    private var stories: [FTTemplateStory] = []
    private var layout = FTCustomFlowLayout()

    class func storiesController() -> FTTemplateStoriesViewController {
        let storyboard = UIStoryboard(name: "FTTemplatesStore", bundle: storeBundle)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "FTTemplateStoriesViewController") as? FTTemplateStoriesViewController else {
            fatalError("Programmer error, unable to find FTTemplateStoriesViewController")
        }
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.stories = FTTemplateStoryManager.loadStories()
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
        return self.stories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTTemplateCollectionViewCell", for: indexPath) as? FTTemplateCollectionViewCell else {
            fatalError("No such cell")
        }
        cell.configCell(with: self.stories[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let splitVc = self.splitViewController {
            let story = self.stories[indexPath.row]
            FTTemplateWebViewScollController.showFromViewController(splitVc, with: story, delegate: self)
        }
    }
}

extension FTTemplateStoriesViewController: FTTemplateStoryDelegate {
    func getStoryFrameWrtoSplitController(_ story: FTTemplateStory) -> CGRect? {
        var rect: CGRect?
        if let splitVc = self.splitViewController,
            let index = self.stories.firstIndex(where: { $0.title == story.title }),
           let cell = self.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? FTTemplateCollectionViewCell {
            rect = cell.convert(cell.imageView.frame, to: splitVc.view)
        }
        return rect
    }
}

extension FTTemplateStoriesViewController: FTTemplateLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForImageAtIndexPath indexPath: IndexPath, cellWidth: CGFloat) -> CGFloat {
        var imgHeight: CGFloat = 100
        let story = self.stories[indexPath.row]
        if let img = UIImage(named: story.largeImageName, in: storeBundle, compatibleWith: nil) {
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
        self.layout.delegate = self
        self.collectionView.collectionViewLayout = self.layout
    }
}
