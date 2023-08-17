//
//  FTTile.m
//  Noteshelf
//
//  Created by Rama Krishna on 7/5/13.
//
//

#import "FTTile.h"
#import <QuartzCore/QuartzCore.h>
#import "FTSegmentCache.h"

@implementation FTTile

@synthesize isDirty, shouldRemove;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.isDirty = YES;
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
//        self.layer.borderColor = [UIColor blueColor].CGColor;
//        self.layer.borderWidth = 1.0;
        self.userInteractionEnabled = false;
        
        self.backgroundColor=[UIColor clearColor];
        self.segmentCache = [[FTSegmentCache alloc] init];
    }
    return self;
}

-(void)removeAssociatedSegments{
    
    [self.segmentCache removeAssociatedSegments];
}


-(void)dealloc{
    [self.segmentCache clearCache];
}

-(void)tileDidGetRemoved
{

}

-(void)tileDidGetAdded
{
    
}
@end
