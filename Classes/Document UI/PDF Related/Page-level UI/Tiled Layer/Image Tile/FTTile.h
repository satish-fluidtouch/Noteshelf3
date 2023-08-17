//
//  FTTile.h
//  Noteshelf
//
//  Created by Rama Krishna on 7/5/13.
//
//

#import <UIKit/UIKit.h>
@class FTSegmentCache;

@interface FTTile : UIView {
}

@property (strong) UIImageView *imageView;

@property (nonatomic) BOOL isDirty;
@property (nonatomic) BOOL shouldRemove;
@property (strong) FTSegmentCache *segmentCache;

-(void)removeAssociatedSegments;
-(void)tileDidGetRemoved;
-(void)tileDidGetAdded;

@end
