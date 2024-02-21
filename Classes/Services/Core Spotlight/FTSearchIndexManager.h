//
//  FTSearchIndexUtility.h
//  FTWhink
//
//  Created by Chandan on 13/10/15.
//  Copyright © 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FTCSIndexableItem <NSObject>

-(BOOL)canSupportCSSearchIndex;
-(nonnull NSString*)uniqueIDForCSSearchIndex;
-(nonnull NSString*)titleForCSSearchIndex;
-(nullable NSString*)contentForCSSearchIndex;
-(nullable NSDate*)modifiedDateForCSSearchIndex;
-(nullable UIImage*)thumbnailForCSSearchIndex;
-(void)prepare:(__nullable dispatch_queue_t)queue onCompletion:(void (^ __nullable)(void))block;

@end

@interface FTSearchIndexManager : NSObject

+(nonnull instancetype)sharedManager;
-(void)updateSearchIndex:(nonnull id<FTCSIndexableItem>)inObject completion:(void (^ __nullable)(NSError * __nullable error))block;
-(void)updateSearchIndexForDocuments:(nonnull NSArray*)documents;
-(void)resumeIndexing;
@end


