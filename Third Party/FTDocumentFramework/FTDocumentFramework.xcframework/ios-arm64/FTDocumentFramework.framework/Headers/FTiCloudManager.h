//
//  FTiCloudManager.h
//  FTDocumentSample
//
//  Created by Ashok Prabhu on 3/11/14.
//  Copyright (c) 2014 FluidTouch.biz. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FTDocumentProvider;
typedef NS_ENUM(NSInteger, FTiCloudActionType)
{
    kiCloudActionNone,
    kiCloudStartUsingMessageAction,
    kiCloudNotAvailableMessageAction,
    kiCloudUserTurnedOffAction,
    kiCloudUserTurnedOnAction
};

@interface FTiCloudManager : NSObject
@property (nonatomic,assign) FTiCloudActionType messageTypeToShow;
@property (nonnull, strong) NSUserDefaults *defaultUserDefaults; //Set from outside to have customization. By default [NSUserDefaults standardUserDefaults]
+ (instancetype _Nonnull)sharedManager;

- (nullable NSURL*)iCloudRootURL;

- (BOOL)iCloudOn;
- (BOOL)iCloudWasOn;
- (void)setiCloudOn:(BOOL)on;
- (void)setiCloudWasOn:(BOOL)on;
- (BOOL)iCloudPrompted;
- (void)setiCloudPrompted:(BOOL)prompted;
- (void)updateiCloudStatus:(NSString *)containerID withCompletionHandler:(void (^)(BOOL available))completionBlock;

- (void)moveItemsFromiCloud:(FTDocumentProvider *)iCloudProvider
                    toLocal:(FTDocumentProvider *)localProvider
               onCompletion:(void (^)(BOOL success))completionBlock;

- (void)moveItemsFromLocal:(FTDocumentProvider *)localProvider
                  toiCloud:(FTDocumentProvider *)iCloudProvider
              onCompletion:(void (^)(BOOL success))completionBlock;

@end
