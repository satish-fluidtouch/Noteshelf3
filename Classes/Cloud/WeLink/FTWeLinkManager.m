//
//  FTWeLinkManager.m
//  Noteshelf
//
//  Created by Naidu on 16/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTWeLinkManager.h"
#import "FTBackUpAccountInfo.h"
#import "FTWeLinkLoginHelper.h"

#if TARGET_OS_IPHONE
#import <HWClouddriveLib/HWClouddriveManger.h>
#endif

CG_EXTERN NSString *const FTDidCompleteWeLinkAuthetication;
CG_EXTERN NSString *const FTDidCancelWeLinkAuthetication;

@interface FTWeLinkManager()

@property (copy)FTWeLinkAuthenticateCallback authCallBack;
@property (strong) FTBackUpAccountInfo *accountInfo;
@property (strong) NSMutableArray *accInfoCallBackArray;

@end

@implementation FTWeLinkManager
@synthesize authCallBack;

static FTWeLinkManager *weLinkManager = nil;

+ (instancetype)sharedWeLinkManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        weLinkManager = [[FTWeLinkManager alloc] init];
        weLinkManager.accInfoCallBackArray = [NSMutableArray array];
        //[[NSNotificationCenter defaultCenter] addObserver:weLinkManager selector:@selector(welinkClientUnlinked:) name:FTDidUnlinkAllWelinkClient object:nil];
    });
    return weLinkManager;
}
-(void)authenticateToWeLinkFromController:(UIViewController*)controller
                             onCompletion:(FTWeLinkAuthenticateCallback)completionHandler
{
    self.authCallBack = completionHandler;
    __weak FTWeLinkManager *weakSelf = self;
    [FTWeLinkLoginHelper loginWithCompletionHandler:^(BOOL success) {
        if(success && weakSelf.authCallBack){
            weakSelf.authCallBack(YES,NO);
            weakSelf.authCallBack = nil;
        }
    }];
}

-(void)signOutOnCompletionHandler:(GenericSuccessBlock)block
{
    dbSharedSessionUnlink();
    if (block)
    {
        block(YES);
    }
}

-(void)accountInfoOnCompletion:(FTWeLinkAccountInfoCallback)completionHandler
{
    if (self.accountInfo && completionHandler)
    {
        completionHandler(self.accountInfo,nil);
    }
    [self.accInfoCallBackArray addObject:completionHandler];
    [self loadAccountInfo];
}


-(void)welinkClientUnlinked:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.accountInfo = nil;
}

-(void)loadAccountInfo
{
    
}

@end
