//
//  FTFinderCollectionViewFlowLayoutDelegate.h
//  FTWhink
//
//  Created by Ashok Prabhu on 19/3/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

@protocol FTFinderCollectionViewFlowLayoutDelegate <NSObject>

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath;

- (BOOL)collectionView:(UICollectionView *)collectionView canDragItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(UICollectionView *)collectionView canDropItemAtIndexPath:(NSIndexPath *)indexPath;

@end
