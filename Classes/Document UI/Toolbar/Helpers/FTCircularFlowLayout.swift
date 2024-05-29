//
//  FTCircularFlowLayout.swift
//  Noteshelf3
//
//  Created by Narayana on 29/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCircularFlowLayout: UICollectionViewLayout {
    private var centre: CGPoint = .zero
    private var radius: CGFloat = 0
    private var itemSize: CGSize = .zero
    private var angularSpacing: CGFloat = 0
    var scrollDirection: UICollectionView.ScrollDirection = .horizontal
    private var mirrorX: Bool = false
    private var mirrorY: Bool = false
    private var rotateItems: Bool = false

    private var angleOfEachItem: CGFloat = 0
    private var angleForSpacing: CGFloat = 0
    private var circumference: CGFloat = 0
    private var cellCount: Int = 0
    private var maxNoOfCellsInCircle: CGFloat = 0
    private var _startAngle: CGFloat = CGFloat.pi
    private var _endAngle: CGFloat = 0

    init(withCentre centre: CGPoint, radius: CGFloat, itemSize: CGSize, angularSpacing: CGFloat) {
        super.init()
        self.centre = centre
        self.radius = radius
        self.itemSize = itemSize
        self.angularSpacing = angularSpacing
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(startAngle: CGFloat, endAngle: CGFloat) {
        self._startAngle = startAngle
        self._endAngle = endAngle
        if _startAngle == 2.0 * CGFloat.pi {
            _startAngle = 2.0 * CGFloat.pi - CGFloat.pi / 180.0
        }

        if _endAngle == 2.0 * CGFloat.pi {
            _endAngle = 2.0 * CGFloat.pi - CGFloat.pi / 180.0
        }
    }

    override func prepare() {
        super.prepare()
        cellCount = self.collectionView?.numberOfItems(inSection: 0) ?? 0
        circumference = abs(_startAngle - _endAngle) * radius
        maxNoOfCellsInCircle = circumference / (max(itemSize.width, itemSize.height) + angularSpacing / 2.0)
        angleOfEachItem = abs(_startAngle - _endAngle) / maxNoOfCellsInCircle
    }

    override var collectionViewContentSize: CGSize {
        let visibleAngle = abs(_startAngle - _endAngle)
        let remainingItemsCount = cellCount > Int(maxNoOfCellsInCircle) ? cellCount - Int(maxNoOfCellsInCircle) : 0
        let scrollableContentWidth = CGFloat(remainingItemsCount) * angleOfEachItem * radius / (2.0 * CGFloat.pi / visibleAngle)
        let height = radius + (max(itemSize.width, itemSize.height) / 2)
        if scrollDirection == .vertical {
            return CGSize(width: height, height: scrollableContentWidth + (self.collectionView?.bounds.size.height ?? 0.0));
        }
        return CGSize(width: scrollableContentWidth + (self.collectionView?.bounds.size.width ?? 0.0), height: height);
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if scrollDirection == .vertical {
            return self.layoutAttributesForVerticalScrollForItem(at: indexPath)
        }
        return self.layoutAttributesForHorozontalScrollForItem(at: indexPath)
    }

    private func layoutAttributesForHorozontalScrollForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        var offset = self.collectionView?.contentOffset.x ?? 0
        offset = offset == 0 ? 1 : offset
        let offsetPartInMPI = offset/circumference
        let angle = 2.0 * CGFloat.pi * offsetPartInMPI
        let offsetAngle = angle

        attributes.size = itemSize
        let _mirrorX: CGFloat = mirrorX ? -1 : 1
        let _mirrorY: CGFloat = mirrorY ? -1 : 1

        let beta = Float(CGFloat(indexPath.item) * angleOfEachItem - offsetAngle + angleOfEachItem / 2.0 - _startAngle)
        let x = centre.x + offset + _mirrorX * radius * CGFloat(cosf(beta))
        let y = centre.y + _mirrorY * radius * CGFloat(sinf(beta))

        let cellCurrentAngle = (CGFloat(indexPath.item) * angleOfEachItem + angleOfEachItem / 2 - offsetAngle)
        if (cellCurrentAngle >= angleOfEachItem / 4 && cellCurrentAngle <= abs(_startAngle - _endAngle) - angleOfEachItem / 4) {
            attributes.alpha = 1
        } else {
            attributes.alpha = 0
        }

        attributes.center = CGPoint(x: x, y: y)
        attributes.zIndex = cellCount - indexPath.item
        if rotateItems {
            if mirrorY {
                attributes.transform = CGAffineTransform(rotationAngle: CGFloat.pi - cellCurrentAngle - CGFloat.pi / 2)
            } else {
                attributes.transform = CGAffineTransform(rotationAngle: cellCurrentAngle - CGFloat.pi / 2)
            }
        }
        return attributes
    }

    private func layoutAttributesForVerticalScrollForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        var offset = self.collectionView?.contentOffset.y ?? 0
        offset = offset == 0 ? 1 : offset
        let offsetPartInMPI = offset/circumference
        let angle = 2 * CGFloat.pi * offsetPartInMPI
        let offsetAngle = angle

        attributes.size = itemSize
        let _mirrorX: CGFloat = mirrorX ? -1 : 1
        let _mirrorY: CGFloat = mirrorY ? -1 : 1

        let beta = Float(CGFloat(indexPath.item) * angleOfEachItem - offsetAngle + angleOfEachItem / 2 - _startAngle)
        let x = centre.x + _mirrorX * radius * CGFloat(cosf(beta))
        let y = centre.y + offset + _mirrorY * radius * CGFloat(sinf(beta))

        let cellCurrentAngle = CGFloat(indexPath.item) * angleOfEachItem + angleOfEachItem / 2 - offsetAngle;

        if (cellCurrentAngle >= -angleOfEachItem / 2 && cellCurrentAngle <= abs(_startAngle - _endAngle) + angleOfEachItem / 2) {
            attributes.alpha = 1
        } else {
            attributes.alpha = 0
        }

        attributes.center = CGPoint(x: x, y: y)
        attributes.zIndex = cellCount - indexPath.item
        if rotateItems {
            if mirrorX {
                attributes.transform = CGAffineTransform(rotationAngle: 2 * CGFloat.pi - cellCurrentAngle)
            } else {
                attributes.transform = CGAffineTransform(rotationAngle: cellCurrentAngle)
            }
        }

        return attributes
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes: [UICollectionViewLayoutAttributes] = []

        for i in 0..<cellCount {
            let indexPath = IndexPath(row: i, section: 0)
            guard let cellAttributes = self.layoutAttributesForItem(at: indexPath) else {
                continue
            }

            if (rect.intersects(cellAttributes.frame) && cellAttributes.alpha != 0) {
                attributes.append(cellAttributes)
            }
        }
        return attributes;
    }

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let contentOffset = self.collectionView?.contentOffset else {
            return nil
        }

        let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        attributes?.center = CGPoint(x: centre.x + contentOffset.x,
                                     y: centre.y + contentOffset.y)
        attributes?.alpha = 0.2
        attributes?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        return attributes
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let contentOffset = self.collectionView?.contentOffset else {
            return nil
        }

        let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        attributes?.center = CGPoint(x: centre.x,
                                     y: centre.y + contentOffset.y)
        attributes?.alpha = 0.2
        attributes?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        return attributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
