//
//  FTSegmentCache.h
//  FTWhink
//
//  Created by Amar on 12/7/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTStrokeConstants.h"

@interface FTSegmentCache : NSObject
{
    FTSegmentPointer *associatedSegments;
}

@property (nonatomic) int associatedSegmentsCount;
@property (nonatomic) int associatedSegmentsAllocationCount;

-(void)removeAssociatedSegments;
-(FTSegmentPointer *)associatedSegments;
-(FTSegmentPointer **)associatedSegmentsAddress;

-(void)clearCache;

@end

