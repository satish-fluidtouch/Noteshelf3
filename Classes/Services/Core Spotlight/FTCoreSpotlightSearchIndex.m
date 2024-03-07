//
//  FTCoreSpotlightSearchIndex.m
//  FTWhink
//
//  Created by Chandan on 12/10/15.
//  Copyright © 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTCoreSpotlightSearchIndex.h"

@implementation FTCoreSpotlightSearchIndex

+(BOOL)isCoreSpotlightAvailable
{
//TODO: temporarily masked the core spot light query
    return ([CSSearchableIndex class] && [CSSearchableIndex isIndexingAvailable])?true:false;
//    return false;
}

+(CSSearchableItemAttributeSet*)createSearchableItemAttributeSet:(NSString*)title
                                                         content:(NSString*)content
                                                        keywords:(NSArray*)keywords
                                                           image:(UIImage*)image
{
    if(![self isCoreSpotlightAvailable]){
        return nil;
    }
    
    CSSearchableItemAttributeSet *attributeSet;
    attributeSet = [[CSSearchableItemAttributeSet alloc] initWithContentType:[UTType typeWithFilenameExtension:@"ns3"]];

    attributeSet.title = title;
    attributeSet.contentDescription = content;
    if(keywords.count > 0){
        attributeSet.keywords = [NSArray arrayWithArray:keywords];
    }
    
    if(image){
        NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
        attributeSet.thumbnailData = imageData;
    }
    
    return attributeSet;
}

+(void)addItem:(nonnull NSString*)uniqueId
        domain:(nullable NSString*)domainId
         title:(nonnull NSString*)title
       content:(nullable NSString*)content
      keywords:(nullable NSArray*)keywords
         image:(nullable UIImage*)image
    completion:(void (^ __nullable)(NSError * __nullable error))completionHandler
{
    if(![self isCoreSpotlightAvailable]){
        return;
    }
    
    CSSearchableItemAttributeSet *attributeSet = [self createSearchableItemAttributeSet:title
                                                                                content:content
                                                                               keywords:keywords
                                                                                image:image];
    attributeSet.relatedUniqueIdentifier = uniqueId;
    CSSearchableItem *item = [[CSSearchableItem alloc]
                              initWithUniqueIdentifier:uniqueId
                              domainIdentifier:domainId
                              attributeSet:attributeSet];
    [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[item]
                                                   completionHandler: ^(NSError * __nullable error) {
                                                       if(completionHandler){
                                                           completionHandler(error);
                                                       };
                                                   }];
}

+(void)deleteItemWithUniqueIdentfiers:(nonnull NSArray*)identifiers
                           completion:(void (^ __nullable)(NSError * __nullable error))completionHandler
{
    if(![self isCoreSpotlightAvailable]){
        if(completionHandler){
            completionHandler(nil);
        }
        return;
    }
    
    if([identifiers count] == 0) {
        if(completionHandler){
            completionHandler(nil);
        }
        return;
    }
    
    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithIdentifiers:identifiers
                                                                   completionHandler:^(NSError * _Nullable error) {
                                                                       if(completionHandler){
                                                                           completionHandler(error);
                                                                       }
                                                                   }];
}

+(void)deleteAllItemsWithcompletionhandler:(void (^ __nullable)(NSError * __nullable error))completionHandler
{
    if(![self isCoreSpotlightAvailable]){
        return;
    }
    
    [[CSSearchableIndex defaultSearchableIndex] deleteAllSearchableItemsWithCompletionHandler:^(NSError * _Nullable error) {
        if(completionHandler){
            completionHandler(error);
        }
    }];
}

+(void)deleteItemWithDomainIdentifiers:(nonnull NSArray*)domainIdentifiers
                            completion:(void (^ __nullable)(NSError * __nullable error))completionHandler
{
    if(![self isCoreSpotlightAvailable]){
        return;
    }
    
    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithDomainIdentifiers:domainIdentifiers
                                                                         completionHandler:^(NSError * _Nullable error) {
                                                                             if(completionHandler){
                                                                                 completionHandler(error);
                                                                             }
                                                                         }];
}

@end
