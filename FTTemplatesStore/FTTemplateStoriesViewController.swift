//
//  FTTemplateStoriesViewController.swift
//  FTTemplatesStore
//
//  Created by Narayana on 21/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

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
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {[weak self](_) in
            guard let self = self else { return }
            self.collectionView?.reloadData()
        }, completion: { (_) in
        })
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
        let imgHeight = self.layout.getImageHeight(with: indexPath)
        cell.configCell(with: self.stories[indexPath.row], imgHeight: imgHeight)
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
    func collectionView(_ collectionView: UICollectionView, heightForCellAtIndexPath indexPath: IndexPath, columnWidth: CGFloat) -> CGFloat {
        var cellHeight: CGFloat = 0
        let imgHeight = self.layout.getImageHeight(with: indexPath)
        cellHeight += imgHeight
        let story = self.stories[indexPath.row]
        let labelWidth = columnWidth - (2 * layout.cellPadding) - 24.0 // 2*12.0 h-paddings
        let titleHeight = story.title.sizeWithFont(.systemFont(ofSize: 16), constrainedToSize: CGSize(width: labelWidth, height: 0), lineBreakMode: .byWordWrapping).height
        cellHeight += titleHeight
        let subTitleHeight = story.subtitle.sizeWithFont(.systemFont(ofSize: 13), constrainedToSize: CGSize(width: labelWidth, height: 0), lineBreakMode: .byWordWrapping).height
        cellHeight += subTitleHeight
        cellHeight += 28 // v-paddings + offset
        return cellHeight
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
