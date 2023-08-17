//
//  FTCSIndexFileManager.h
//  FTWhink
//
//  Created by Chandan on 14/10/15.
//  Copyright © 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTCSIndexItem.h"

@interface FTCSIndexCacheManager : NSObject

+(id)sharedManager;

-(void)addIndexItem:(FTCSIndexItem*)item;
-(void)removeIndexItem:(FTCSIndexItem*)item;
-(FTCSIndexItem*)modelForUniqueID:(NSString*)uniqueID;

-(NSArray*)getAllUniqueIDs;
-(void)removeIndexForUniqueIDs:(NSArray*)array;

-(void)save;

@end
