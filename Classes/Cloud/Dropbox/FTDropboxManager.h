//
//  FTDropboxManager.h
//  Noteshelf
//
//  Created by Amar Udupa on 20/3/14.
//
//

#import <Foundation/Foundation.h>

@class FTBackUpAccountInfo;

typedef void (^FTDropboxAuthenticateCallback)(BOOL success,BOOL cancelled);
typedef void (^FTDropboxAccountInfoCallback)(FTBackUpAccountInfo *accountInfo,NSError *error);

CG_EXTERN NSString *const FTDidUnlinkAllDropboxClient;

@interface FTDropboxManager : NSObject

+ (instancetype)sharedDropboxManager;

- (BOOL)isLoggedIn;

- (void)authenticateToDropBoxFromController:(UIViewController*)controller
                               onCompletion:(FTDropboxAuthenticateCallback)completionHandler;
-(void)accountInfoOnCompletion:(FTDropboxAccountInfoCallback)completionHandler;

-(void)signOutOnCompletionHandler:(GenericSuccessBlock)block;

@end
