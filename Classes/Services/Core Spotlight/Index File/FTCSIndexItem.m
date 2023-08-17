//
//  FTCSIndexModel.m
//  FTWhink
//
//  Created by Chandan on 14/10/15.
//  Copyright © 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTCSIndexItem.h"

#define INDEX_UNIQUE_ID @"uniqueID"
#define INDEX_MODIFIED_DATE @"modifiedDate"

@implementation FTCSIndexItem

-(NSDictionary*)dictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if(_uniqueID){
        [dict setObject:_uniqueID forKey:INDEX_UNIQUE_ID];
    }
    if(_modifiedDate){
        [dict setObject:_modifiedDate forKey:INDEX_MODIFIED_DATE];
    }

    return [NSDictionary dictionaryWithDictionary:dict];
}

-(id)initWithDictionary:(NSDictionary*)dictionary
{
    self = [super init];
    if (self) {
        _uniqueID = [dictionary objectForKey:INDEX_UNIQUE_ID];
        _modifiedDate = [dictionary objectForKey:INDEX_MODIFIED_DATE];
    }
    return self;
}

@end
