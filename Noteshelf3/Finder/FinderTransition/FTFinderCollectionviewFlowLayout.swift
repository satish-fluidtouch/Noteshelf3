//
//  FTFinderCollectionviewFlowLayout.swift
//  Noteshelf3
//
//  Created by Sameer on 15/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFinderCollectionViewFlowLayout: UICollectionViewFlowLayout {
    var selectedItemIndexPath: IndexPath?
    var draggedOldIndexPath: IndexPath?
    var focusedUUID: String?;

    override class var layoutAttributesClass: AnyClass {
        get{
            return FTFinderCollectionViewLayoutAttributes.classForCoder();
        }
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        if let finderCollectionViewLayoutAttributes = layoutAttributes as? FTFinderCollectionViewLayoutAttributes{
            if layoutAttributes.representedElementCategory == .decorationView {
            }
            finderCollectionViewLayoutAttributes.focusedUUID = self.focusedUUID;
        }
        if layoutAttributes.indexPath == selectedItemIndexPath {
            layoutAttributes.isHidden = true
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if let attributes = super.layoutAttributesForElements(in: rect)?
            .map({ $0.copy() }) as? [UICollectionViewLayoutAttributes] {
                attributes
                    .reduce([CGFloat: (CGFloat, [UICollectionViewLayoutAttributes])]()) {
                        guard $1.representedElementCategory == .cell else { return $0 }
                        return $0.merging([ceil($1.center.y): ($1.frame.origin.y, [$1])]) {
                            ($0.0 < $1.0 ? $0.0 : $1.0, $0.1 + $1.1)
                        }
                    }
                    .values.forEach { minY, line in
                        line.forEach {
                            $0.frame = $0.frame.offsetBy(
                                dx: 0,
                                dy:  $0.frame.origin.y - minY
                            )
                        }
                    }
                for layoutAttributes in attributes {
                    switch layoutAttributes.representedElementCategory {
                    case .cell:
                        apply(layoutAttributes)
                    default:
                        break
                    }
                }
                return attributes
            }
        return nil
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let layoutAttributes = super.layoutAttributesForItem(at: indexPath) {
            switch layoutAttributes.representedElementCategory {
            case .cell:
                apply(layoutAttributes)
            default:
                break
            }
            return layoutAttributes
        }
        return nil
    }
}

final class FTFinderCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    var focusedUUID: String?;
    
    override func copy(with zone: NSZone?) -> Any {
        let copy: FTFinderCollectionViewLayoutAttributes = super.copy(with: zone) as! FTFinderCollectionViewLayoutAttributes
        copy.focusedUUID = self.focusedUUID
        return copy
    }
    override func isEqual(_ object: Any?) -> Bool {
        guard object is FTFinderCollectionViewLayoutAttributes else {
            return false
        }
        
        let otherObject: FTFinderCollectionViewLayoutAttributes = object as! FTFinderCollectionViewLayoutAttributes
        
        if (self.focusedUUID != otherObject.focusedUUID) {
            return false
        }
        return super.isEqual(otherObject);
    }
}
