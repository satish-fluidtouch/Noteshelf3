//
//  ServerURLManager.h
//  Noteshelf
//
//  Created by Developer on 17/6/14.
//
//

#define USER_GUIDE_URL @"USER_GUIDE_URL"
#define NOTESHELF_SUPPORT_URL @"NOTESHELF_SUPPORT_URL"
#define AIR_TRANSFER_FAQ_URL @"AIR_TRANSFER_FAQ_URL"
#define AIR_TRANSFER_SUPPORT_URL @"AIR_TRANSFER_SUPPORT_URL"
#define TELL_A_FRIEND_FULL_URL @"TELL_A_FRIEND_FULL_URL"
#define TELL_A_FRIEND_SHORT_URL @"TELL_A_FRIEND_SHORT_URL"
#define LEARN_MORE_LIVESCRIBE @"LEARN_MORE_LIVESCRIBE"
#define LEARN_MORE_LIVESCRIBE_JP @"LEARN_MORE_LIVESCRIBE_JP"

CG_EXTERN NSString *const FTDismissPopOverControllerNotification;

CG_EXTERN NSString* applicationGenreName(void);
CG_EXTERN NSString* applicationName(void);
CG_EXTERN NSURL *appStoreShortURL(void);
CG_EXTERN NSURL *appStoreURL(void);
CG_EXTERN NSString *appIconBase64Encoding(void);

#define SERVER_URL_MANAGER [ServerURLManager sharedInstance]

@interface ServerURLManager : NSObject

-(NSString *)urlForKey:(NSString *)key;
+(ServerURLManager *)sharedInstance;
-(void)updateServerUrlDictIfNeeded;

@end
