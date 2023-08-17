//
//  FTSearchIndexUtility.m
//  FTWhink
//
//  Created by Chandan on 13/10/15.
//  Copyright © 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTSearchIndexManager.h"
#import "FTCSIndexCacheManager.h"
#import "FTCSIndexItem.h"
#import "FTCoreSpotlightSearchIndex.h"

//#define ENABLE_CSLOG

#ifdef ENABLE_CSLOG
#define CSLog(...) NSLog(__VA_ARGS__)
#else
#define CSLog(...)
#endif

@interface FTSearchIndexManager ()

@property(nonatomic,strong)dispatch_group_t group;
@property(nonatomic,strong)NSMutableArray *deleteIndexList;

@end

@implementation FTSearchIndexManager

+(id)sharedManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

-(void)updateSearchIndex:(nonnull id<FTCSIndexableItem>)inItem completion:(void (^ __nullable)(NSError * __nullable error))block
{
    if(![FTCoreSpotlightSearchIndex isCoreSpotlightAvailable]){
        return;
    }
    
    if(_group){
        dispatch_group_enter(_group);
    }
    
    BOOL canUpdate = NO;

    NSString *uniqueID = nil;
    if([inItem respondsToSelector:@selector(uniqueIDForCSSearchIndex)]){
        uniqueID = [inItem uniqueIDForCSSearchIndex];
    }
    
    NSDate *modifiedDate = nil;
    if([inItem respondsToSelector:@selector(modifiedDateForCSSearchIndex)]){
        modifiedDate = [inItem modifiedDateForCSSearchIndex];
    }
    
    NSString *content = nil;
    if([inItem respondsToSelector:@selector(contentForCSSearchIndex)]){
        content = [inItem contentForCSSearchIndex];
    }
    
    UIImage *thumbnail = nil;
    if([inItem respondsToSelector:@selector(thumbnailForCSSearchIndex)]){
        thumbnail = [inItem thumbnailForCSSearchIndex];
    }
    
    NSString *title = nil;
    if([inItem respondsToSelector:@selector(titleForCSSearchIndex)]){
        title = [inItem titleForCSSearchIndex];
    }

    //Check if document modified date is greater than indexed modified date
    __block FTCSIndexItem *model = [[FTCSIndexCacheManager sharedManager] modelForUniqueID:uniqueID];
    NSComparisonResult result = [model.modifiedDate compare:modifiedDate];
    if(!model.modifiedDate || result == NSOrderedAscending){
        if([inItem conformsToProtocol:@protocol(FTCSIndexableItem)] && uniqueID && title){
            canUpdate = YES;
        }
    }
    
    if(canUpdate){
        [FTCoreSpotlightSearchIndex addItem:uniqueID
                                               domain:nil
                                                title:title
                                              content:content
                                             keywords:nil
                                                image:thumbnail
                                           completion:^(NSError * _Nullable error) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   if(!error){
                                                       if(!model){
                                                           model = [[FTCSIndexItem alloc] init];
                                                       }
                                                       model.uniqueID = uniqueID;
                                                       if(!modifiedDate){
                                                           model.modifiedDate = [NSDate date];
                                                       }
                                                       else{
                                                           model.modifiedDate = modifiedDate;
                                                       }
                                                       [[FTCSIndexCacheManager sharedManager] addIndexItem:model];
                                                       [self.deleteIndexList removeObject:model.uniqueID];
                                                       CSLog(@"CoreSpotlightSearch: CSSearchIndex added %@",model.uniqueID);
                                                   }
                                                   else{
                                                       CSLog(@"CoreSpotlightSearch: error %@",error);
                                                   }
                                                   
                                                   if(block){
                                                       block(error);
                                                   }
                                                   
                                                   if(_group){
                                                       dispatch_group_leave(_group);
                                                   }
                                               });
                                           }];
    }
    else{
        CSLog(@"CoreSpotlightSearch: CSSearchIndex already upto date %@",model.uniqueID);
        [self.deleteIndexList removeObject:model.uniqueID];

        if(block){
            block(nil);
        }
        
        if(_group){
            dispatch_group_leave(_group);
        }
    }
}

-(void)updateSearchIndexForDocuments:(NSArray*)documents
{
    if(![FTCoreSpotlightSearchIndex isCoreSpotlightAvailable]){
        return;
    }
    
    BOOL canIndexDocuments = YES;
    static NSTimeInterval lastExecutionTime = 0;
    if([NSDate timeIntervalSinceReferenceDate]-lastExecutionTime < 10){
        canIndexDocuments = NO;
        CSLog(@"CoreSpotlightSearch: Many updates within short interval");
    }
    
    if(canIndexDocuments){
        lastExecutionTime = [NSDate timeIntervalSinceReferenceDate];
        UIBackgroundTaskIdentifier taskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        
        //1.Create Set - to know the indexes to remove
        self.deleteIndexList = [[[FTCSIndexCacheManager sharedManager] getAllUniqueIDs] mutableCopy];
        
        //2.Index documents
        _group = dispatch_group_create();
        [self indexDocuments:documents];
        
        dispatch_group_notify(self.group, dispatch_get_main_queue(), ^{
            //3.Remove the missed index
            [FTCoreSpotlightSearchIndex deleteItemWithUniqueIdentfiers:self.deleteIndexList completion:^(NSError * _Nullable error) {
                CSLog(@"CoreSpotlightSearch: Saved and deleted index for items %@",self.deleteIndexList);
                [[FTCSIndexCacheManager sharedManager] removeIndexForUniqueIDs:self.deleteIndexList];
                
                //Save
                [[FTCSIndexCacheManager sharedManager] save];
                
                self.group = nil;
                [[UIApplication sharedApplication] endBackgroundTask:taskIdentifier];
            }];
        });
    }
}

-(void)indexDocuments:(NSArray*)documents
{
    [documents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
    {
        [self updateSearchIndex:obj completion:nil];
    }];
}

@end
