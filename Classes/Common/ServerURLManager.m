//
//  ServerURLManager.m
//  Noteshelf
//
//  Created by Developer on 17/6/14.
//
//

#import "ServerURLManager.h"

#define ServerURLManager_DEBUG_MODE  0

#define SERVER_URL_SET_S3_URL @"https://noteshelfv2-public.s3.amazonaws.com/ServerURLs.plist"

#define SERVER_URL_SET_LAST_UPDATE_TIME @"SERVER_URL_SET_LAST_UPDATE_TIME"

#if ServerURLManager_DEBUG_MODE
    #define SERVER_URL_SET_EXPIRY_SECONDS 10 //10 seconds
    #define ServerURLManager_DEBUG(...) NSLog(__VA_ARGS__)
#else
    #define SERVER_URL_SET_EXPIRY_SECONDS 24*60*60*7 //7 days
    #define ServerURLManager_DEBUG(...)
#endif

@interface ServerURLManager()

@property (atomic,strong) NSDictionary *serverUrlDict;

@end


@implementation ServerURLManager

+(ServerURLManager *)sharedInstance{
    static dispatch_once_t onceToken;
    static ServerURLManager *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ServerURLManager alloc] init];
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"SERVER_URL_USING_v2"]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:SERVER_URL_SET_LAST_UPDATE_TIME];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SERVER_URL_USING_v2"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        ServerURLManager_DEBUG(@"ServerURLManager: sharedInstance created");
    });
    return sharedInstance;
}

-(void)updateServerUrlDictIfNeeded{
    
    NSTimeInterval lastUpdatedTime = [[NSUserDefaults standardUserDefaults] doubleForKey:SERVER_URL_SET_LAST_UPDATE_TIME];
    
    if ([NSDate timeIntervalSinceReferenceDate] - lastUpdatedTime >= SERVER_URL_SET_EXPIRY_SECONDS) {
     
        //Download in background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            __unused NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];
            ServerURLManager_DEBUG(@"ServerURLManager: Dict expired, trying to download in background");
            
            //Try to download the file
            self.serverUrlDict = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:SERVER_URL_SET_S3_URL]];
            if (self.serverUrlDict) {
                BOOL success = [self.serverUrlDict writeToFile:[self serverURLsLocalPath] atomically:YES];
                if (success) {
                    __unused NSTimeInterval t2 = [NSDate timeIntervalSinceReferenceDate];
                    ServerURLManager_DEBUG(@"ServerURLManager: download successful (%.2f sec)", t2-t1);
                    [[NSUserDefaults standardUserDefaults] setDouble:[NSDate timeIntervalSinceReferenceDate] forKey:SERVER_URL_SET_LAST_UPDATE_TIME];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }else{
                ServerURLManager_DEBUG(@"ServerURLManager: download failed");
            }
        });
    }else{
        ServerURLManager_DEBUG(@"ServerURLManager: local dict still valid");
    }
}

-(NSDictionary *)serverUrls{
    
    ServerURLManager_DEBUG(@"ServerURLManager: self.serverUrlDict");

    if (!self.serverUrlDict) {
        
        ServerURLManager_DEBUG(@"ServerURLManager: reading from local");
        
        //If download fails, read from the latest one
        self.serverUrlDict = [NSDictionary dictionaryWithContentsOfFile:[self serverURLsLocalPath]];
        
        //If read fails, read from the bundle one
        if (!self.serverUrlDict) {
            ServerURLManager_DEBUG(@"ServerURLManager: unable to read local, using bundle defaults");
            self.serverUrlDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ServerURLs.plist" ofType:nil]];
        }
    }else{
        ServerURLManager_DEBUG(@"ServerURLManager: Using loaded instance variable");
    }
    
    return self.serverUrlDict;
}

-(NSString *)urlForKey:(NSString *)key{
    ServerURLManager_DEBUG(@"ServerURLManager: getURLString: %@", key);
    NSString *url = [[self serverUrls] objectForKey:key];
    if(!url)
    {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ServerURLs.plist" ofType:nil]];

        url = [dict objectForKey:key];
    }
    return url;
}


-(NSString *)serverURLsLocalPath{
    
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"ServerURLs.plist"];
}

@end

NSString* applicationGenreName(void)
{
    return @"Productivity";
}

NSString* applicationName(void)
{
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if ([applicationName length] == 0)
    {
        applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
    }
    return applicationName;
}

NSURL *appStoreShortURL(void)
{
    return [NSURL URLWithString:[SERVER_URL_MANAGER urlForKey:TELL_A_FRIEND_SHORT_URL]]; //from google url shortner
    //removed http:// as the twitter itself adds this while posting on the page.
}

NSURL *appStoreURL(void)
{
    return [NSURL URLWithString:[SERVER_URL_MANAGER urlForKey:TELL_A_FRIEND_FULL_URL]];
}

NSString* appIconBase64Encoding(void)
{
    UIImage *emailImage = [UIImage imageNamed:@"TellAFriendAppIcon"];
    //Convert the image into data
    NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(emailImage)];
    NSString *base64String = [imageData base64EncodedStringWithOptions:0];
    return base64String;
}
