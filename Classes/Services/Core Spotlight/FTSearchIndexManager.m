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

@property(strong) FTCSIndexCacheManager *cacheManager;
@property(strong) dispatch_queue_t spotlightQueue;
@property(strong) NSMutableArray *deleteIndexList;
@property(strong) NSMutableSet<id<FTCSIndexableItem>> *itemsToIndex;

@property(assign) BOOL isIndexingInProgress;
@property(assign) UIBackgroundTaskIdentifier identifier;
@property(assign) BOOL paused;

@end

@interface FTSearchIndexManager (Private)

-(void)startIndexing;
-(void)indexDocuments:(NSArray*)documents;
-(void)addItemToSpotlightSearch:(id<FTCSIndexableItem>)inItem onCompletion: (void(^)(void))block;

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

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cacheManager = [[FTCSIndexCacheManager alloc] init];
        _spotlightQueue = dispatch_queue_create("con.fluidtouch.ns3spotlight", nil);
        _itemsToIndex = [NSMutableSet set];
        self.identifier = UIBackgroundTaskInvalid;
//#if DEBUG
//        [FTCoreSpotlightSearchIndex deleteAllItemsWithcompletionhandler:nil];
//        [self.cacheManager removeIndexForUniqueIDs:[self.cacheManager getAllUniqueIDs]];
//#endif
    }
    return self;
}

-(BOOL)supportsSpotlightSearch {
    return [FTCoreSpotlightSearchIndex isCoreSpotlightAvailable];
}
- (void)resumeIndexing {
    if(self.paused) {
        self.paused = false;
        [self startIndexing];
    }
}

-(void)updateSearchIndex:(nonnull id<FTCSIndexableItem>)inItem completion:(void (^ __nullable)(NSError * __nullable error))block
{
    if(![FTCoreSpotlightSearchIndex isCoreSpotlightAvailable]){
        return;
    }
    
    //Check if document modified date is greater than indexed modified date
    FTCSIndexItem *model = [self.cacheManager modelForUniqueID:[inItem uniqueIDForCSSearchIndex]];
    NSComparisonResult result = [model.modifiedDate compare:inItem.modifiedDateForCSSearchIndex];
    if(!model.modifiedDate || result == NSOrderedAscending){
        @synchronized (self.itemsToIndex) {
            [self.itemsToIndex addObject:inItem];
            DEBUGLOG(@"CoreSpotlightSearch: item added: %d",(int)self.itemsToIndex.count);
        }
        if(!self.isIndexingInProgress) {
            self.isIndexingInProgress = TRUE;
            [self startIndexing];
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
        
        //1.Create Set - to know the indexes to remove
        self.deleteIndexList = [[self.cacheManager getAllUniqueIDs] mutableCopy];
        
        //2.Index documents
        [self indexDocuments:documents];
    }
}
@end

@implementation FTSearchIndexManager (Private)
-(id<FTCSIndexableItem>)firstItem {
    @synchronized (self.itemsToIndex) {
        id<FTCSIndexableItem> item = [self.itemsToIndex anyObject];
        if(nil != item) {
            [self.itemsToIndex removeObject:item];
        }
        return item;
    }
}

-(NSInteger)count {
    @synchronized (self.itemsToIndex) {
        return self.itemsToIndex.count;
    }
}

-(void)startIndexing {
    __block __weak FTSearchIndexManager *weakSelf = self;
    dispatch_async(self.spotlightQueue, ^{
        if(weakSelf.paused) {
            DEBUGLOG(@"CoreSpotlightSearch: startIndexing");
            return;
        }
        if(weakSelf.identifier == UIBackgroundTaskInvalid) {
            weakSelf.identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                weakSelf.paused = true;
                [weakSelf.cacheManager save];
                [[UIApplication sharedApplication] endBackgroundTask:weakSelf.identifier];
                weakSelf.identifier = UIBackgroundTaskInvalid;
                DEBUGLOG(@"CoreSpotlightSearch: background task expiration");
            }];
        }
        id<FTCSIndexableItem> itemToIndex = [weakSelf firstItem];
        if(nil == itemToIndex) {
            if(weakSelf.paused) {
                DEBUGLOG(@"CoreSpotlightSearch: itemToIndex nil");
                return;
            }
            DEBUGLOG(@"CoreSpotlightSearch: Finalizing nil");
            [FTCoreSpotlightSearchIndex deleteItemWithUniqueIdentfiers:weakSelf.deleteIndexList completion:^(NSError * _Nullable error) {
                dispatch_async(weakSelf.spotlightQueue, ^{
                    DEBUGLOG(@"CoreSpotlightSearch: Saved and deleted index for items %@",self.deleteIndexList);
                    [weakSelf.cacheManager removeIndexForUniqueIDs:weakSelf.deleteIndexList];
                    //Save
                    [weakSelf.cacheManager save];
                    if(weakSelf.identifier != UIBackgroundTaskInvalid) {
                        [[UIApplication sharedApplication] endBackgroundTask:weakSelf.identifier];
                        weakSelf.identifier = UIBackgroundTaskInvalid;
                    }
                    if([weakSelf count] > 0) {
                        [weakSelf startIndexing];
                    }
                    else{
                        weakSelf.isIndexingInProgress = FALSE;
                    }
                });
            }];
            return;
        }
        DEBUGLOG(@"CoreSpotlightSearch: item removed: %d",[self count]);
        [itemToIndex prepare:weakSelf.spotlightQueue onCompletion:^{
            [weakSelf addItemToSpotlightSearch:itemToIndex onCompletion:^{
                [weakSelf startIndexing];
            }];
        }];
    });
}

-(void)indexDocuments:(NSArray*)documents
{
    [documents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
    {
        [self updateSearchIndex:obj completion:nil];
    }];
}

-(void)addItemToSpotlightSearch:(id<FTCSIndexableItem>)inItem onCompletion: (void(^)(void))block {
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
    __block FTCSIndexItem *model = [self.cacheManager modelForUniqueID:uniqueID];
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
            dispatch_async(self.spotlightQueue, ^{
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
                    [self.cacheManager addIndexItem:model];
                    [self.deleteIndexList removeObject:model.uniqueID];
                    CSLog(@"CoreSpotlightSearch: CSSearchIndex added %@",model.uniqueID);
                }
                else{
                    CSLog(@"CoreSpotlightSearch: error %@",error);
                }
                if(block) {
                    block();
                }
            });
        }];
    }
    else{
        CSLog(@"CoreSpotlightSearch: CSSearchIndex already upto date %@",model.uniqueID);
        [self.deleteIndexList removeObject:model.uniqueID];
        if(block) {
            block();
        }
    }
}

@end
