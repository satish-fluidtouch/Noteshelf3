//
//  FTCustomFlowLayout.swift
//  FTTemplatesStore
//
//  Created by Narayana on 21/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTTemplateLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForImageAtIndexPath indexPath: IndexPath , cellWidth: CGFloat ) -> CGFloat
}

class FTTemplateCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Configure cell appearance
    }

    func configCell(with story: FTTemplateStory) {
        self.imageView?.image = UIImage(named: story.largeImageName, in: storeBundle, with: nil)
//        self.imageView?.contentMode = .scaleAspectFill
        self.imageView?.layer.contentsRect = CGRect(x: story.thumbnailRectXPercent, y: story.thumbnailRectYPercent, width: story.thumbnailRectWidthPercent, height: story.thumbnailRectHeightPercent)
    }
}

class FTCustomFlowLayout: UICollectionViewFlowLayout {
    var numberOfColumns = 2 
    var cellPadding: CGFloat = 16

    weak var delegate: FTTemplateLayoutDelegate?

    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    func clearCache() {
        cache = []
        contentHeight = 0
    }

    override func prepare() {
        super.prepare()
        guard cache.isEmpty == true,let collectionView = collectionView else {
            return
        }
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }

        var column = 0
        var yOffset: [CGFloat] = .init(repeating: 0, count: numberOfColumns)

        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            let imgHeight = delegate?.collectionView(collectionView, heightForImageAtIndexPath: indexPath, cellWidth: columnWidth) ?? 100
            let height = cellPadding * 2 + imgHeight
            let frame = CGRect(x: xOffset[column],y: yOffset[column],width: columnWidth,height: height)
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)
            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height
            column = column < (numberOfColumns - 1) ? (column + 1) : 0
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        return visibleLayoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
}

