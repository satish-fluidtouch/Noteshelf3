//
//  FTCSIndexFileManager.m
//  FTWhink
//
//  Created by Chandan on 14/10/15.
//  Copyright © 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTCSIndexCacheManager.h"

#define CORESPOTLIGHT_SEARCHINDEX @"CoreSpotlightSearchIndex"

@interface FTCSIndexCacheManager()

@property(nonatomic,strong)NSMutableDictionary *searchIndexDictionary;
@property(nonatomic,assign)BOOL isDirty;

@end

@implementation FTCSIndexCacheManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self load];
    }
    return self;
}

+(id)sharedManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

-(FTCSIndexItem*)modelForUniqueID:(NSString*)uniqueID
{
    FTCSIndexItem *model = nil;
    NSDictionary *dictionary = [_searchIndexDictionary objectForKey:uniqueID];
    if(dictionary){
      model = [[FTCSIndexItem alloc] initWithDictionary:dictionary];
    }
    return model;
}

-(void)addIndexItem:(FTCSIndexItem*)item
{
    if(item.uniqueID.length){
        [self.searchIndexDictionary setObject:[item dictionary] forKey:item.uniqueID];
        _isDirty = YES;
    }
}

-(void)removeIndexItem:(FTCSIndexItem*)item
{
    if(item.uniqueID.length){
        [self.searchIndexDictionary removeObjectForKey:item.uniqueID];
        _isDirty = YES;
    }
}

-(NSArray*)getAllUniqueIDs
{
    return [self.searchIndexDictionary allKeys];
}

-(void)removeIndexForUniqueIDs:(NSArray*)array
{
    if(array.count){
        _isDirty = YES;
        [self.searchIndexDictionary removeObjectsForKeys:array];
    }
}

-(void)save
{
    if(_searchIndexDictionary && _isDirty){
        [[NSUserDefaults standardUserDefaults] setObject:_searchIndexDictionary forKey:CORESPOTLIGHT_SEARCHINDEX];
        [[NSUserDefaults standardUserDefaults] synchronize];
        _isDirty = NO;
    }
}

-(void)load
{
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:CORESPOTLIGHT_SEARCHINDEX];
    if(dictionary){
        self.searchIndexDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    }
    else{
        self.searchIndexDictionary = [NSMutableDictionary dictionary];
    }
}

@end
