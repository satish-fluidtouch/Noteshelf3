//
//  FTCollectionViewFlowLayout+Shelf.swift
//  Noteshelf
//
//  Created by Siva on 22/02/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    @IBInspectable var shouldShowDecoration = false;
    override class var layoutAttributesClass: AnyClass { get{
        return FTShelfCollectionViewLayoutAttributes.classForCoder();
        }
    }
    //MARK:- Attributes
    var shelves: NSMutableDictionary!
    var shouldUpdateDecoration = false;

    var isReorderActive: Bool = false
    var focusedUUID: String?;
    
    //MARK:- Custom
    func applyLayoutAttributes(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        if let shelfCollectionViewLayoutAttributes = layoutAttributes as? FTShelfCollectionViewLayoutAttributes{
            if layoutAttributes.representedElementCategory == .decorationView {
                shelfCollectionViewLayoutAttributes.shouldUpdateDecoration = self.shouldUpdateDecoration;
            }
            shelfCollectionViewLayoutAttributes.focusedUUID = self.focusedUUID;
        }
    }
    
    //MARK:- LayoutProcess
    override func prepare() {
        super.prepare();
    
        if nil == self.shelves {
            self.shelves = NSMutableDictionary();
        }
        self.shelves.removeAllObjects();
        
        self.register(UINib(nibName: "FTShelfCollectionReusableView", bundle: nil), forDecorationViewOfKind: FTShelfCollectionReusableView.kind())
        
        let rows = max(self.collectionView!.numberOfItems(inSection: 0), 10);

        if self.shouldShowDecoration {
            var y: CGFloat = 0
            for index in 0...rows - 1 {
                let shelfHeight: CGFloat;
                if self.collectionView?.isRegularClass() == true {
                    #if targetEnvironment(macCatalyst)
                        shelfHeight = 250
                    #else
                        shelfHeight = 260
                    #endif
                }
                else {
                   shelfHeight = 260
                }
                let collectionViewWidth = self.collectionView!.frame.width;
                if index == 0 {
                    let hiddenBouncingPoint: CGFloat = -1000

                    let value = NSValue(cgRect: CGRect(x: 0, y: hiddenBouncingPoint, width: collectionViewWidth, height: -hiddenBouncingPoint + shelfHeight));
                    self.shelves[IndexPath(row: index, section: 0)] = value;
                }
                else {
                    let value = NSValue(cgRect: CGRect(x: 0, y: CGFloat(y), width: collectionViewWidth, height: shelfHeight));
                    self.shelves[IndexPath(row: index, section: 0)] = value;
                }
                y += shelfHeight
            }
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true;
    }
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect);
        
        var attributesToReturn = [UICollectionViewLayoutAttributes]();
        for eachAttribute in attributes!
        {
            switch eachAttribute.representedElementCategory {
            case .cell:
                guard let copiedAttribute = eachAttribute.copy() as? UICollectionViewLayoutAttributes else {
                    break
                }
                self.applyLayoutAttributes(copiedAttribute);
                attributesToReturn.append(copiedAttribute)
                
            case .supplementaryView: //  Footer is added
                guard let footerAttribute = eachAttribute.copy() as? UICollectionViewLayoutAttributes else {
                    break
                }
                if self.collectionView!.contentSize.height < self.collectionView!.frame.height {
                    footerAttribute.frame = CGRect(x: self.collectionView!.frame.origin.x, y: self.collectionView!.frame.height - 80, width: self.collectionView!.frame.width, height: 100.0)
                }
                attributesToReturn.append(footerAttribute)
            default:
                break;
            }
        }
        
        //Add shelf
        for (key, value) in self.shelves {
            let rectShelf = (value as AnyObject).cgRectValue
            if (rectShelf?.intersects(rect))! {
                let layoutAttributesShelfBackground = FTShelfCollectionViewLayoutAttributes(forDecorationViewOfKind: FTShelfCollectionReusableView.kind(), with: key as! IndexPath);
                layoutAttributesShelfBackground.frame = rectShelf!
                layoutAttributesShelfBackground.zIndex = -1
                layoutAttributesShelfBackground.shouldUpdateDecoration = self.shouldUpdateDecoration;
                attributesToReturn.append(layoutAttributesShelfBackground)
            }
        }
        return attributesToReturn
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? FTShelfCollectionViewLayoutAttributes {
            self.applyLayoutAttributes(attributes);
            return attributes
        }
        else {
            return super.layoutAttributesForItem(at: indexPath)
        }
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if(elementKind == FTShelfCollectionReusableView.kind()) {
            let layoutAttributesShelfBackground = FTShelfCollectionViewLayoutAttributes(forDecorationViewOfKind: FTShelfCollectionReusableView.kind(), with: indexPath);
            layoutAttributesShelfBackground.frame = CGRect.zero;
            layoutAttributesShelfBackground.zIndex = -1
            if let valueRect = self.shelves[indexPath] {
                let rectShelf = (valueRect as AnyObject).cgRectValue
                layoutAttributesShelfBackground.frame = rectShelf!
            }
            return layoutAttributesShelfBackground
        }
        return nil
    }
}
