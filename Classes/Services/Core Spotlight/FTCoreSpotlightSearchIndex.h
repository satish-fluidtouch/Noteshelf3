//
//  FTCoreSpotlightSearchIndex.h
//  FTWhink
//
//  Created by Chandan on 12/10/15.
//  Copyright © 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface FTCoreSpotlightSearchIndex : NSObject

+(BOOL)isCoreSpotlightAvailable;

+(void)addItem:(nonnull NSString*)uniqueId
        domain:(nullable NSString*)domainId
         title:(nonnull NSString*)title
       content:(nullable NSString*)content
      keywords:(nullable NSArray*)keywords
         image:(nullable UIImage*)image
    completion:(void (^ __nullable)(NSError * __nullable error))completionHandler;

+(void)deleteItemWithUniqueIdentfiers:(nonnull NSArray*)identifiers
                           completion:(void (^ __nullable)(NSError * __nullable error))completionHandler;

+(void)deleteAllItemsWithcompletionhandler:(void (^ __nullable)(NSError * __nullable error))completionHandler;

+(void)deleteItemWithDomainIdentifiers:(nonnull NSArray*)domainIdentifiers
                            completion:(void (^ __nullable)(NSError * __nullable error))completionHandler;
@end
