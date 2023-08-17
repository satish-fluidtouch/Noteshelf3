//
//  FTDropboxManager.m
//  Noteshelf
//
//  Created by Amar Udupa on 20/3/14.
//
//

#import "FTDropboxManager.h"
#import "FTBackUpAccountInfo.h"

@import ObjectiveDropboxOfficial;

CG_EXTERN NSString *const FTDidCompleteDropBoxAuthetication;
CG_EXTERN NSString *const FTDidCancelDropBoxAuthetication;

@interface FTDropboxManager()

@property (copy)FTDropboxAuthenticateCallback authCallBack;
@property (strong) FTBackUpAccountInfo *accountInfo;
@property (strong) NSMutableArray *accInfoCallBackArray;

@end

@implementation FTDropboxManager
@synthesize authCallBack;

static FTDropboxManager *dropboxManager = nil;

+ (instancetype)sharedDropboxManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dropboxManager = [[FTDropboxManager alloc] init];
        dropboxManager.accInfoCallBackArray = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:dropboxManager selector:@selector(dropboxClientUnlinked:) name:FTDidUnlinkAllDropboxClient object:nil];
    });
    return dropboxManager;
}

- (BOOL)isLoggedIn
{
    return [[DBClientsManager authorizedClient] isAuthorized];
}

-(void)authenticateToDropBoxFromController:(UIViewController*)controller
                              onCompletion:(FTDropboxAuthenticateCallback)completionHandler
{
    self.authCallBack = completionHandler;
    [DBClientsManager authorizeFromController:[UIApplication sharedApplication]
                                   controller:controller
                                      openURL:^(NSURL *url) {
                                          [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                                      }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCompleteDropBoxAuthetication:) name:FTDidCompleteDropBoxAuthetication object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCancelDropBoxAuthetication:) name:FTDidCancelDropBoxAuthetication object:nil];
}

-(void)signOutOnCompletionHandler:(GenericSuccessBlock)block
{
    dbSharedSessionUnlink();
    if (block)
    {
        block(YES);
    }
}

-(void)didCancelDropBoxAuthetication:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(self.authCallBack)
    {
        self.authCallBack(NO,YES);
        self.authCallBack = nil;
    }
}

-(void)didCompleteDropBoxAuthetication:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(self.authCallBack)
    {
        self.authCallBack(YES,NO);
        self.authCallBack = nil;
    }
}

-(void)accountInfoOnCompletion:(FTDropboxAccountInfoCallback)completionHandler
{
    if (self.accountInfo && completionHandler)
    {
        completionHandler(self.accountInfo,nil);
    }
    [self.accInfoCallBackArray addObject:completionHandler];
    [self loadAccountInfo];
}


-(void)dropboxClientUnlinked:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.accountInfo = nil;
}

-(void)loadAccountInfo
{
    DBUserClient *client = [DBClientsManager authorizedClient];
    [[client.usersRoutes getCurrentAccount] setResponseBlock:^(DBUSERSFullAccount * _Nullable result, DBNilObject * _Nullable routeError, DBRequestError * _Nullable networkError) {
        if(nil != result) {
            FTBackUpAccountInfo *accountInfo = [[FTBackUpAccountInfo alloc] init];
            accountInfo.name = [[result name] displayName];
            
            [[client.usersRoutes getSpaceUsage] setResponseBlock:^(DBUSERSSpaceUsage * _Nullable result, DBNilObject * _Nullable routeError, DBRequestError * _Nullable networkError) {
                if(nil != result) {
                    switch ([result allocation].tag){
                        case DBUSERSSpaceAllocationIndividual:
                        {
                            accountInfo.consumedBytes = [[result used] longLongValue];
                            accountInfo.totalBytes = [[[[result allocation] individual] allocated] longLongValue];
                        }
                            break;
                        case DBUSERSSpaceAllocationTeam:
                        {
                            accountInfo.consumedBytes = [[[[result allocation] team] used] longLongValue];
                            accountInfo.totalBytes = [[[[result allocation] team] allocated] longLongValue];
                        }
                            break;
                        default:
                            break;
                    }
                }
                
                for (FTDropboxAccountInfoCallback eachInfo in self.accInfoCallBackArray)
                {
                    eachInfo(accountInfo,nil);
                }
                [self.accInfoCallBackArray removeAllObjects];
            }];
            self.accountInfo = accountInfo;
        }
        else {
            for (FTDropboxAccountInfoCallback eachInfo in self.accInfoCallBackArray)
            {
                if (networkError.statusCode.integerValue == 401) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"DBLoggedOut" object:nil];
                }
                else {
                    eachInfo(nil,[networkError nsError]);
                }
            }
        }
    }];
}

@end
