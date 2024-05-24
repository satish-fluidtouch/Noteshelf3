//
//  FTCustomFlowLayout.swift
//  FTTemplatesStore
//
//  Created by Narayana on 21/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTemplateCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet private weak var titleView: UIView!
    @IBOutlet private weak var titleLabel: FTTopLeftAlignedLabel!
    @IBOutlet private weak var descriptionLabel: FTTopLeftAlignedLabel!
    @IBOutlet private weak var imgViewHeightConstraint: NSLayoutConstraint?

    func configCell(with story: FTTemplateStory, imgHeight: CGFloat) {
        let titleViewBgColor = UIColor(hexString: story.titleViewBgColor)
        self.titleView.backgroundColor = titleViewBgColor
        self.titleLabel.textColor = titleViewBgColor.isLightColor() ? .black : .white
        self.titleLabel.text = story.title
        self.descriptionLabel.textColor = titleViewBgColor.isLightColor() ? .black.withAlphaComponent(0.7) : .white.withAlphaComponent(0.7)
        self.descriptionLabel.text = story.subtitle
        self.imageView?.image = UIImage(named: story.largeImageName, in: storeBundle, with: nil)
        self.imageView?.layer.contentsRect = CGRect(x: story.thumbnailRectXPercent, y: story.thumbnailRectYPercent, width: story.thumbnailRectWidthPercent, height: story.thumbnailRectHeightPercent)
        self.layoutIfNeeded()
        self.imgViewHeightConstraint?.constant = imgHeight
    }
}

protocol FTTemplateLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForCellAtIndexPath indexPath: IndexPath , columnWidth: CGFloat ) -> CGFloat
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
            let imgHeight = delegate?.collectionView(collectionView, heightForCellAtIndexPath: indexPath, columnWidth: columnWidth) ?? 100
            let height =  cellPadding * 2 + imgHeight
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

    func getImageHeight(with indexPath: IndexPath) -> CGFloat {
        let height: CGFloat
        if indexPath.row % 3 == 0 {
            height = 192
        } else if indexPath.row % 3 == 1 {
            height = 260
        } else {
            height = 220
        }
        return height
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

class FTTopLeftAlignedLabel: UILabel {
    override func drawText(in rect: CGRect) {
        guard let text = self.text else { return }
        let textRect = text.boundingRect(
            with: CGSize(width: rect.size.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: self.font],
            context: nil)
        var newRect = rect
        newRect.size.height = ceil(textRect.size.height)
        super.drawText(in: newRect)
    }

    override var intrinsicContentSize: CGSize {
        guard let text = self.text else { return super.intrinsicContentSize }
        let textRect = text.boundingRect(
            with: CGSize(width: self.bounds.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: self.font],
            context: nil)
        let size = CGSize(width: ceil(textRect.size.width), height: ceil(textRect.size.height))
        return size
    }
}
