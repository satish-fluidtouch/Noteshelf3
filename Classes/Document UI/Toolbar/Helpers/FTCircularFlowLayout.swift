//
//  FTCircularFlowLayout.swift
//  Noteshelf3
//
//  Created by Narayana on 29/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

struct FTCircularLayoutConfig {
    var maxVisibleItemsCount: Int
    var angleOfEachItem: CGFloat
    var radius: CGFloat
    var itemSize: CGSize

    init(maxVisibleItemsCount: Int = 7, angleOfEachItem: CGFloat = 14.degreesToRadians, radius: CGFloat = 200, itemSize: CGSize = CGSize(width: 40, height: 40)) {
        self.maxVisibleItemsCount = maxVisibleItemsCount
        self.angleOfEachItem = angleOfEachItem
        self.radius = radius
        self.itemSize = itemSize
    }
}

class FTCircularFlowLayout: UICollectionViewLayout {
    private var cellCount: Int = 0
    private var startAngle: CGFloat = .pi
    private var endAngle: CGFloat = 0
    private var circumference: CGFloat = 0

    private let centre: CGPoint
    private let config: FTCircularLayoutConfig

    init(withCentre centre: CGPoint, config: FTCircularLayoutConfig) {
        self.centre = centre
        self.config = config
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(startAngle: CGFloat, endAngle: CGFloat) {
        self.startAngle = startAngle
        self.endAngle = endAngle
    }

    override func prepare() {
        super.prepare()
        guard let collectionView = self.collectionView else {
            return
        }
        self.cellCount = collectionView.numberOfItems(inSection: 0)
        self.circumference = abs(startAngle - endAngle) * self.config.radius
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = self.collectionView else {
            return .zero
        }
        let visibleAngle = abs(startAngle - endAngle)
        var contentWidth: CGFloat = collectionView.bounds.size.width
        if cellCount > self.config.maxVisibleItemsCount {
            let remainingItemsCount = cellCount - self.config.maxVisibleItemsCount
            contentWidth += CGFloat(remainingItemsCount) * self.config.angleOfEachItem * self.config.radius / (2.0 * CGFloat.pi / visibleAngle)
        }
        let height = self.config.radius + (max(self.config.itemSize.width, self.config.itemSize.height) / 2)
        return CGSize(width: contentWidth, height: height)
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = self.collectionView else {
            return nil
        }
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        let offset = collectionView.contentOffset.x
        let offsetPartInMPI = offset/circumference
        let angle = 2.0 * CGFloat.pi * offsetPartInMPI
        let offsetAngle = angle
        attributes.size = self.config.itemSize

        let beta = Float(CGFloat(indexPath.item) * self.config.angleOfEachItem - offsetAngle + self.config.angleOfEachItem / 2.0 - startAngle)
        let x = centre.x + offset +  self.config.radius * CGFloat(cosf(beta))
        let y = centre.y +  self.config.radius * CGFloat(sinf(beta))

        let cellCurrentAngle = (CGFloat(indexPath.item) * self.config.angleOfEachItem + self.config.angleOfEachItem / 2 - offsetAngle)
        if (cellCurrentAngle >= self.config.angleOfEachItem / 4 && cellCurrentAngle <= abs(startAngle - endAngle) - self.config.angleOfEachItem / 4) {
            attributes.alpha = 1
        } else {
            attributes.alpha = 0
        }
        attributes.center = CGPoint(x: x, y: y)
        attributes.zIndex = cellCount - indexPath.item
        
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
        return attributes
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

final class FTPencilProMenuLayer: CAShapeLayer {
    init(strokeColor: UIColor, lineWidth: CGFloat) {
        super.init()
        self.strokeColor = strokeColor.cgColor
        self.fillColor = UIColor.clear.cgColor
        self.lineWidth = lineWidth
        self.lineCap = .round
    }
    
    func setPath(with center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) {
        let path = UIBezierPath()
        path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        self.path = path.cgPath
    }
    
    func addShadow(offset: CGSize, radius: CGFloat) {
        self.shadowColor = UIColor.black.withAlphaComponent(0.16).cgColor
        self.shadowOpacity = 1
        self.shadowOffset = offset
        self.shadowRadius = radius
        self.masksToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
