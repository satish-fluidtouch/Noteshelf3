//
//  FTSegmentCache.m
//  FTWhink
//
//  Created by Amar on 12/7/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTSegmentCache.h"

@implementation FTSegmentCache

@synthesize associatedSegmentsCount,associatedSegmentsAllocationCount;

- (id)init
{
    self = [super init];
    if (self) {
        associatedSegments = nil;
        associatedSegmentsCount = 0;
        associatedSegmentsAllocationCount = 0;
    }
    return self;
}

-(void)removeAssociatedSegments
{
    @synchronized(self)
    {
        if (associatedSegmentsAllocationCount > 0) free(associatedSegments);
        
        associatedSegments = malloc(sizeof(FTSegmentPointer) * SEGMENT_CHUNK_SIZE);
        associatedSegmentsCount = 0;
        associatedSegmentsAllocationCount = SEGMENT_CHUNK_SIZE;
    }
}

-(FTSegmentPointer *)associatedSegments
{
    return associatedSegments;
}

-(FTSegmentPointer **)associatedSegmentsAddress
{
    return &associatedSegments;
}

-(void)dealloc
{
    [self clearCache];
}

-(void)clearCache
{
    @synchronized(self)
    {
        if (associatedSegments) {
            free(associatedSegments);
            associatedSegments = nil;
            associatedSegmentsCount = 0;
            associatedSegmentsAllocationCount = 0;
        }
    }
}
@end
