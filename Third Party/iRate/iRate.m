//
//  iRate.m
//
//  Version 1.10.3
//
//  Created by Nick Lockwood on 26/01/2011.
//  Copyright 2011 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/iRate
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//


#import "iRate.h"
#import "FTAppConfigHelper.h"
#import "Noteshelf-Swift.h"

#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


#pragma GCC diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Wunused-macros"
#pragma GCC diagnostic ignored "-Wconversion"
#pragma GCC diagnostic ignored "-Wformat-nonliteral"
#pragma GCC diagnostic ignored "-Wgnu"


NSUInteger const iRateAppStoreGameGenreID = 6014;
NSString *const iRateErrorDomain = @"iRateErrorDomain";


static NSString *const iRateAppStoreIDKey = @"iRateAppStoreID";
static NSString *const iRateRatedVersionKey = @"iRateRatedVersionChecked";
static NSString *const iRateDeclinedVersionKey = @"iRateDeclinedVersion";
static NSString *const iRateLastRemindedKey = @"iRateLastReminded";
static NSString *const iRateLastVersionUsedKey = @"iRateLastVersionUsed";
static NSString *const iRateFirstUsedKey = @"iRateFirstUsed";
static NSString *const iRateUseCountKey = @"iRateUseCount";
static NSString *const iRateEventCountKey = @"iRateEventCount";

static NSString *const iRateMacAppStoreBundleID = @"com.apple.appstore";
static NSString *const iRateAppLookupURLFormat = @"http://itunes.apple.com/%@/lookup";

static NSString *const iRateiOSAppStoreURLScheme = @"itms-apps";
static NSString *const iRateiOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@";
static NSString *const iRateiOSWriteReviewURLFormat = @"itms-apps://itunes.apple.com/app/itunes-u/id%@?action=write-review";
static NSString *const iRateMacAppStoreURLFormat = @"macappstore://itunes.apple.com/app/id%@";


#define SECONDS_IN_A_DAY 86400.0
#define SECONDS_IN_A_WEEK 604800.0
#define MAC_APP_STORE_REFRESH_DELAY 5.0
#define REQUEST_TIMEOUT 60.0


@implementation NSObject (iRate)

- (void)iRateCouldNotConnectToAppStore:(__unused NSError *)error {}
- (void)iRateDidDetectAppUpdate {}
- (BOOL)iRateShouldPromptForRating { return YES; }
- (void)iRateDidPromptForRating {}
- (void)iRateUserDidAttemptToRateApp {}
- (void)iRateUserDidDeclineToRateApp {}
- (void)iRateUserDidRequestReminderToRateApp {}
- (BOOL)iRateShouldOpenAppStore { return YES; }
- (void)iRateDidOpenAppStore {}

@end


@interface iRate()

@property (nonatomic, strong) id visibleAlert;
@property (nonatomic, assign) BOOL checkingForPrompt;
@property (nonatomic, assign) BOOL checkingForAppStoreID;

@end


@implementation iRate

+ (void)load
{
    [self performSelectorOnMainThread:@selector(sharedInstance) withObject:nil waitUntilDone:NO];
}

+ (iRate *)sharedInstance
{
    static iRate *sharedInstance = nil;
    if (sharedInstance == nil)
    {
        sharedInstance = [[iRate alloc] init];
    }
    return sharedInstance;
}

- (NSString *)localizedStringForKey:(NSString *)key withDefault:(NSString *)defaultString
{
    static NSBundle *bundle = nil;
    if (bundle == nil)
    {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"iRate" ofType:@"bundle"];
        if (self.useAllAvailableLanguages)
        {
            bundle = [NSBundle bundleWithPath:bundlePath];
            NSString *language = [[NSLocale preferredLanguages] count]? [NSLocale preferredLanguages][0]: @"en";
            if (![[bundle localizations] containsObject:language])
            {
                language = [language componentsSeparatedByString:@"-"][0];
            }
            if ([[bundle localizations] containsObject:language])
            {
                bundlePath = [bundle pathForResource:language ofType:@"lproj"];
            }
        }
        bundle = [NSBundle bundleWithPath:bundlePath] ?: [NSBundle mainBundle];
    }
    defaultString = [bundle localizedStringForKey:key value:defaultString table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:defaultString table:nil];
}

- (iRate *)init
{
    if ((self = [super init]))
    {
        
#if TARGET_OS_IPHONE
        
        //register for iphone application events
        if (&UIApplicationWillEnterForegroundNotification)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationWillEnterForeground)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:nil];
        }
#endif
        
        //get country
        self.appStoreCountry = [(NSLocale *)[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        if ([self.appStoreCountry isEqualToString:@"150"])
        {
            self.appStoreCountry = @"eu";
        }
        else if ([[self.appStoreCountry stringByReplacingOccurrencesOfString:@"[A-Za-z]{2}" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, 2)] length])
        {
            self.appStoreCountry = @"us";
        }
        
        //application version (use short version preferentially)
        self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if ([self.applicationVersion length] == 0)
        {
            self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        }
        
        //localised application name
        self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        if ([self.applicationName length] == 0)
        {
            self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        }
        
        //bundle id
        self.applicationBundleID = [[NSBundle mainBundle] bundleIdentifier];
#if ENTERPRISE_EDITION
        self.applicationBundleID = @"com.fluidtouch.noteshelf3.enterprise";
        [self setAppStoreIDOnMainThread:@"6471592545"];
#else
        self.applicationBundleID = @"com.fluidtouch.noteshelf3";
        [self setAppStoreIDOnMainThread:@"6458735203"];
#endif

        //default settings
        self.useAllAvailableLanguages = YES;
        self.promptForNewVersionIfUserRated = YES;
        self.onlyPromptIfLatestVersion = YES;
        self.onlyPromptIfMainWindowIsAvailable = YES;
        self.promptAtLaunch = YES;
        self.usesUntilPrompt = 10;
        self.eventsUntilPrompt = 10;
        self.daysUntilPrompt = 10.0f;
        self.usesPerWeekForPrompt = 0.0f;
        self.remindPeriod = 1.0f;
        self.verboseLogging = NO;
        self.previewMode = NO;
        
#if DEBUG
        
        //enable verbose logging in debug mode
        self.verboseLogging = YES;
        
#endif
        
        //app launched
        [self performSelectorOnMainThread:@selector(applicationLaunched) withObject:nil waitUntilDone:NO];
    }
    return self;
}

- (id<iRateDelegate>)delegate
{
    if (_delegate == nil)
    {
        
#if TARGET_OS_IPHONE
#define APP_CLASS UIApplication      
#else
#define APP_CLASS NSApplication  
#endif
        
        _delegate = (id<iRateDelegate>)[[APP_CLASS sharedApplication] delegate];
    }
    return _delegate;
}

- (NSString *)messageTitle
{
    // Disabled in favor of A/B Testing
    //return [_messageTitle ?: [self localizedStringForKey:iRateMessageTitleKey withDefault:@"Rate %@"] stringByReplacingOccurrencesOfString:@"%@" withString:self.applicationName];
    NSString *title = [[FTAppConfigHelper sharedAppConfig] titleforiRate];
    return [title stringByReplacingOccurrencesOfString:@"%@" withString:self.applicationName];
}

- (NSString *)message
{
    // Disabled in favor of A/B Testing
    /*
    NSString *message = _message;
    if (!message)
    {
        message = (self.appStoreGenreID == iRateAppStoreGameGenreID)? [self localizedStringForKey:iRateGameMessageKey withDefault:@"If you enjoy playing %@, would you mind taking a moment to rate it? It won’t take more than a minute. Thanks for your support!"]: [self localizedStringForKey:iRateAppMessageKey withDefault:@"If you enjoy using %@, would you mind taking a moment to rate it? It won’t take more than a minute. Thanks for your support!"];
    }
    return [message stringByReplacingOccurrencesOfString:@"%@" withString:self.applicationName];
     */

    NSString *message = [[FTAppConfigHelper sharedAppConfig] messageforiRate];
    return [message stringByReplacingOccurrencesOfString:@"%@" withString:self.applicationName];
}

- (NSString *)updateMessage
{
    NSString *updateMessage = _updateMessage;
    if (!updateMessage)
    {
        updateMessage = [self localizedStringForKey:iRateUpdateMessageKey withDefault:self.message];
    }
    return [updateMessage stringByReplacingOccurrencesOfString:@"%@" withString:self.applicationName];
}

- (NSString *)cancelButtonLabel
{
    return _cancelButtonLabel ?: [self localizedStringForKey:iRateCancelButtonKey withDefault:@"No, Thanks"];
}

- (NSString *)rateButtonLabel
{
    return _rateButtonLabel ?: [self localizedStringForKey:iRateRateButtonKey withDefault:@"Rate It Now"];
}

- (NSString *)remindButtonLabel
{
    return _remindButtonLabel ?: [self localizedStringForKey:iRateRemindButtonKey withDefault:@"Remind Me Later"];
}

- (NSURL *)ratingsURL
{
    if (_ratingsURL)
    {
        return _ratingsURL;
    }
    
    if (!self.appStoreID && self.verboseLogging)
    {
        NSLog(@"iRate could not find the App Store ID for this application. If the application is not intended for App Store release then you must specify a custom ratingsURL.");
    }
    
    NSString *URLString;
    
#if TARGET_OS_IPHONE
    
    URLString = iRateiOSWriteReviewURLFormat;
#else
    
    URLString = iRateMacAppStoreURLFormat;
    
#endif
            
    return [NSURL URLWithString:[NSString stringWithFormat:URLString, @(self.appStoreID)]];
    
}

- (NSUInteger)appStoreID
{
    return _appStoreID ?: [[[NSUserDefaults standardUserDefaults] objectForKey:iRateAppStoreIDKey] unsignedIntegerValue];
}

- (NSDate *)firstUsed
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:iRateFirstUsedKey];
}

- (void)setFirstUsed:(NSDate *)date
{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:iRateFirstUsedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)lastReminded
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:iRateLastRemindedKey];
}

- (void)setLastReminded:(NSDate *)date
{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:iRateLastRemindedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)usesCount
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:iRateUseCountKey];
}

- (void)setUsesCount:(NSUInteger)count
{
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)count forKey:iRateUseCountKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)eventCount
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:iRateEventCountKey];
}

- (void)setEventCount:(NSUInteger)count
{
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)count forKey:iRateEventCountKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (float)usesPerWeek
{
    return (float)self.usesCount / ([[NSDate date] timeIntervalSinceDate:self.firstUsed] / SECONDS_IN_A_WEEK);
}

- (BOOL)declinedThisVersion
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:iRateDeclinedVersionKey] isEqualToString:self.applicationVersion];
}

- (void)setDeclinedThisVersion:(BOOL)declined
{
    [[NSUserDefaults standardUserDefaults] setObject:(declined? self.applicationVersion: nil) forKey:iRateDeclinedVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)declinedAnyVersion
{
    return [(NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:iRateDeclinedVersionKey] length] != 0;
}

- (BOOL)ratedVersion:(NSString *)version
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:iRateRatedVersionKey] isEqualToString:version];
}

- (BOOL)ratedThisVersion
{
    return [self ratedVersion:self.applicationVersion];
}

- (void)setRatedThisVersion:(BOOL)rated
{
    [[NSUserDefaults standardUserDefaults] setObject:(rated? self.applicationVersion: nil) forKey:iRateRatedVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)ratedAnyVersion
{
    return [(NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:iRateRatedVersionKey] length] != 0;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)incrementUseCount
{
    self.usesCount ++;
}

- (void)incrementEventCount
{
    self.eventCount ++;
}

- (BOOL)shouldPromptForRating
{   
    //preview mode?
    if (self.previewMode)
    {
        NSLog(@"iRate preview mode is enabled - make sure you disable this for release");
        return YES;
    }
    
    //check if we've rated this version
    else if (self.ratedThisVersion)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the user has already rated this version");
        }
        return NO;
    }
    
    //check if we've rated any version
    else if (self.ratedAnyVersion && !self.promptForNewVersionIfUserRated)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the user has already rated this app, and promptForNewVersionIfUserRated is disabled");
        }
        return NO;
    }
    
    //check if we've declined to rate the app
    else if (self.declinedThisVersion)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the user has declined to rate the app");
        }
        return NO;
    }
    
    //check how long we've been using this version
    else if ([[NSDate date] timeIntervalSinceDate:self.firstUsed] < self.daysUntilPrompt * SECONDS_IN_A_DAY)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the app was first used less than %g days ago", self.daysUntilPrompt);
        }
        return NO;
    }
    
    //check how many times we've used it and the number of significant events
    else if (self.usesCount < self.usesUntilPrompt && self.eventCount < self.eventsUntilPrompt)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the app has only been used %@ times and only %@ events have been logged", @(self.usesCount), @(self.eventCount));
        }
        return NO;
    }
    
    //check if usage frequency is high enough
    else if (self.usesPerWeek < self.usesPerWeekForPrompt)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the app has only been used %g times per week on average since it was installed", self.usesPerWeek);
        }
        return NO;
    }

    //check if within the reminder period
    else if (self.lastReminded != nil && [[NSDate date] timeIntervalSinceDate:self.lastReminded] < self.remindPeriod * SECONDS_IN_A_DAY)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the user last asked to be reminded less than %g days ago", self.remindPeriod);
        }
        return NO;
    }
    
    //lets prompt!
    return YES;
}

- (NSString *)valueForKey:(NSString *)key inJSON:(id)json
{
    if ([json isKindOfClass:[NSString class]])
    {
        //use legacy parser
        NSRange keyRange = [json rangeOfString:[NSString stringWithFormat:@"\"%@\"", key]];
        if (keyRange.location != NSNotFound)
        {
            NSInteger start = keyRange.location + keyRange.length;
            NSRange valueStart = [json rangeOfString:@":" options:(NSStringCompareOptions)0 range:NSMakeRange(start, [(NSString *)json length] - start)];
            if (valueStart.location != NSNotFound)
            {
                start = valueStart.location + 1;
                NSRange valueEnd = [json rangeOfString:@"," options:(NSStringCompareOptions)0 range:NSMakeRange(start, [(NSString *)json length] - start)];
                if (valueEnd.location != NSNotFound)
                {
                    NSString *value = [json substringWithRange:NSMakeRange(start, valueEnd.location - start)];
                    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    while ([value hasPrefix:@"\""] && ![value hasSuffix:@"\""])
                    {
                        if (valueEnd.location == NSNotFound)
                        {
                            break;
                        }
                        NSInteger newStart = valueEnd.location + 1;
                        valueEnd = [json rangeOfString:@"," options:(NSStringCompareOptions)0 range:NSMakeRange(newStart, [(NSString *)json length] - newStart)];
                        value = [json substringWithRange:NSMakeRange(start, valueEnd.location - start)];
                        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    }
                    
                    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
                    value = [value stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
                    value = [value stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\f" withString:@"\f"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\b" withString:@"\f"];
                    
                    while (YES)
                    {
                        NSRange unicode = [value rangeOfString:@"\\u"];
                        if (unicode.location == NSNotFound || unicode.location + unicode.length == 0)
                        {
                            break;
                        }
                        
                        uint32_t c = 0;
                        NSString *hex = [value substringWithRange:NSMakeRange(unicode.location + 2, 4)];
                        NSScanner *scanner = [NSScanner scannerWithString:hex];
                        [scanner scanHexInt:&c];
                        
                        if (c <= 0xffff)
                        {
                            value = [value stringByReplacingCharactersInRange:NSMakeRange(unicode.location, 6) withString:[NSString stringWithFormat:@"%C", (unichar)c]];
                        }
                        else
                        {
                            //convert character to surrogate pair
                            uint16_t x = (uint16_t)c;
                            uint16_t u = (c >> 16) & ((1 << 5) - 1);
                            uint16_t w = (uint16_t)u - 1;
                            unichar high = 0xd800 | (w << 6) | x >> 10;
                            unichar low = (uint16_t)(0xdc00 | (x & ((1 << 10) - 1)));
                            
                            value = [value stringByReplacingCharactersInRange:NSMakeRange(unicode.location, 6) withString:[NSString stringWithFormat:@"%C%C", high, low]];
                        }
                    }
                    return value;
                }
            }
        }
    }
    else
    {
        return json[key];
    }
    return nil;
}

- (void)setAppStoreIDOnMainThread:(NSString *)appStoreIDString
{
    _appStoreID = [appStoreIDString integerValue];
    [[NSUserDefaults standardUserDefaults] setInteger:_appStoreID forKey:iRateAppStoreIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)connectionSucceeded
{
    if (self.checkingForAppStoreID)
    {
        //no longer checking
        self.checkingForPrompt = NO;
        self.checkingForAppStoreID = NO;
        
        //open app store
        [self openRatingsPageInAppStore];
    }
    else if (self.checkingForPrompt)
    {
        //no longer checking
        self.checkingForPrompt = NO;
        
        //confirm with delegate
        if (![self.delegate iRateShouldPromptForRating])
        {
            if (self.verboseLogging)
            {
                NSLog(@"iRate did not display the rating prompt because the iRateShouldPromptForRating delegate method returned NO");
            }
            return;
        }
        
        //prompt user
        [self promptForRating];
    }
}

- (void)connectionError:(NSError *)error
{
    if (self.checkingForPrompt || self.checkingForAppStoreID)
    {
        //no longer checking
        self.checkingForPrompt = NO;
        self.checkingForAppStoreID = NO;
        
        //log the error
        if (error)
        {
            NSLog(@"iRate rating process failed because: %@", [error localizedDescription]);
        }
        else
        {
            NSLog(@"iRate rating process failed because an unknown error occured");
        }
        
        //could not connect
        [self.delegate iRateCouldNotConnectToAppStore:error];
    }
}

- (void)checkForConnectivityInBackground
{
    if (![FT_APP_CONFIG shouldShowiRate]) {
        [self performSelectorOnMainThread:@selector(connectionError:) withObject:nil waitUntilDone:YES];
        return;
    }
    
    if ([NSThread isMainThread])
    {
        [self performSelectorInBackground:@selector(checkForConnectivityInBackground) withObject:nil];
        return;
    }
    
    @autoreleasepool
    {
        //prevent concurrent checks
        static BOOL checking = NO;
        if (checking) return;
        checking = YES;
        
        //first check iTunes
        NSString *iTunesServiceURL = [NSString stringWithFormat:iRateAppLookupURLFormat, self.appStoreCountry];
        if (_appStoreID) //important that we check ivar and not getter in case it has changed
        {
            iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?id=%@", @(_appStoreID)];
        }
        else 
        {
            iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?bundleId=%@", self.applicationBundleID];
        }
        
        if (self.verboseLogging)
        {
            NSLog(@"iRate is checking %@ to retrieve the App Store details...", iTunesServiceURL);
        }
        
        __block NSError *error = nil;
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:iTunesServiceURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:REQUEST_TIMEOUT];
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        
        [[session dataTaskWithRequest:request completionHandler:^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
            NSData *data = taskData;
            NSInteger statusCode = ((NSHTTPURLResponse *)taskResponse).statusCode;
            if (data && statusCode == 200)
            {
                //in case error is garbage...
                error = nil;
                
                id json = nil;
                if ([NSJSONSerialization class])
                {
                    json = [[NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&error][@"results"] lastObject];
                }
                else
                {
                    //convert to string
                    json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                }
                
                if (!error)
                {
                    //check bundle ID matches
                    NSString *bundleID = [self valueForKey:@"bundleId" inJSON:json];
                    if (bundleID)
                    {
                        if ([bundleID isEqualToString:self.applicationBundleID])
                        {
                            //get genre
                            if (self.appStoreGenreID == 0)
                            {
                                self.appStoreGenreID = [[self valueForKey:@"primaryGenreId" inJSON:json] integerValue];
                            }
                            
                            //get app id
                            if (!self.appStoreID)
                            {
                                NSString *appStoreIDString = [self valueForKey:@"trackId" inJSON:json];
                                [self performSelectorOnMainThread:@selector(setAppStoreIDOnMainThread:) withObject:appStoreIDString waitUntilDone:YES];
                                
                                if (self.verboseLogging)
                                {
                                    NSLog(@"iRate found the app on iTunes. The App Store ID is %@", appStoreIDString);
                                }
                            }
                            
                            //check version
                            if (self.onlyPromptIfLatestVersion && !self.previewMode)
                            {
                                NSString *latestVersion = [self valueForKey:@"version" inJSON:json];
                                if ([latestVersion compare:self.applicationVersion options:NSNumericSearch] == NSOrderedDescending)
                                {
                                    if (self.verboseLogging)
                                    {
                                        NSLog(@"iRate found that the installed application version (%@) is not the latest version on the App Store, which is %@", self.applicationVersion, latestVersion);
                                    }
                                    
                                    error = [NSError errorWithDomain:iRateErrorDomain code:iRateErrorApplicationIsNotLatestVersion userInfo:@{NSLocalizedDescriptionKey: @"Installed app is not the latest version available"}];
                                }
                            }
                        }
                        else
                        {
                            if (self.verboseLogging)
                            {
                                NSLog(@"iRate found that the application bundle ID (%@) does not match the bundle ID of the app found on iTunes (%@) with the specified App Store ID (%@)", self.applicationBundleID, bundleID, @(self.appStoreID));
                            }
                            
                            error = [NSError errorWithDomain:iRateErrorDomain code:iRateErrorBundleIdDoesNotMatchAppStore userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Application bundle ID does not match expected value of %@", bundleID]}];
                        }
                    }
                    else if (self.appStoreID || !self.ratingsURL)
                    {
                        if (self.verboseLogging)
                        {
                            NSLog(@"iRate could not find this application on iTunes. If your app is not intended for App Store release then you must specify a custom ratingsURL. If this is the first release of your application then it's not a problem that it cannot be found on the store yet");
                        }
                        if (!self.previewMode)
                        {
                            error = [NSError errorWithDomain:iRateErrorDomain
                                                        code:iRateErrorApplicationNotFoundOnAppStore
                                                    userInfo:@{NSLocalizedDescriptionKey: @"The application could not be found on the App Store."}];
                        }
                    }
                    else if (!self.appStoreID && self.verboseLogging)
                    {
                        NSLog(@"iRate could not find your app on iTunes. If your app is not yet on the store or is not intended for App Store release then don't worry about this");
                    }
                }
            }
            else if (statusCode >= 400)
            {
                //http error
                NSString *message = [NSString stringWithFormat:@"The server returned a %@ error", @(statusCode)];
                error = [NSError errorWithDomain:@"HTTPResponseErrorDomain" code:statusCode userInfo:@{NSLocalizedDescriptionKey: message}];
            }
            
            //handle errors (ignoring sandbox issues)
            if (error && !(error.code == EPERM && [error.domain isEqualToString:NSPOSIXErrorDomain] && self.appStoreID))
            {
                [self performSelectorOnMainThread:@selector(connectionError:) withObject:error waitUntilDone:YES];
            }
            else if (self.appStoreID || self.previewMode)
            {
                //show prompt
                [self performSelectorOnMainThread:@selector(connectionSucceeded) withObject:nil waitUntilDone:YES];
            }
            
            //finished
            checking = NO;
        }] resume];
    }
}

- (void)promptIfNetworkAvailable
{
    if (!self.checkingForPrompt && !self.checkingForAppStoreID)
    {
        self.checkingForPrompt = YES;
        [self checkForConnectivityInBackground];
    }
}

- (BOOL)showRemindButton
{
    return [self.remindButtonLabel length];
}

- (BOOL)showCancelButton
{
    return [self.cancelButtonLabel length];
}

- (void)promptForRating
{
    if (!self.visibleAlert)
    {
        if ([FT_APP_CONFIG shouldShowiRate] && [self canShowAlertFromLastAction])
        {
            UIViewController *topController = [[[UIApplication sharedApplication] keyWindow] visibleViewController];
            while (topController.presentedViewController)
            {
                topController = topController.presentedViewController;
            }

            NSString *message = self.ratedAnyVersion? self.updateMessage: self.message;
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.messageTitle message:message preferredStyle:UIAlertControllerStyleAlert];

            [alert addAction:[UIAlertAction actionWithTitle:self.rateButtonLabel style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
                track(@"InAppReview_WriteReview",nil,@"write_review");
                [self didDismissAlert:alert withButtonAtIndex:0];
            }]];

            //cancel action
            if ([self showCancelButton])
            {
                [alert addAction:[UIAlertAction actionWithTitle:self.cancelButtonLabel style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
                    track(@"InAppReview_NoThanks",nil,@"write_review");
                    [self didDismissAlert:alert withButtonAtIndex:1];
                }]];
            }
            
            //remind action
            if ([self showRemindButton])
            {
                [alert addAction:[UIAlertAction actionWithTitle:self.remindButtonLabel style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
                    track(@"InAppReview_RemindMe_Later",nil,@"write_review");
                    [self didDismissAlert:alert withButtonAtIndex:[self showCancelButton]? 2: 1];
                }]];
            }
            
            self.visibleAlert = alert;
            //get current view controller and present alert
            [topController presentViewController:alert animated:YES completion:NULL];
        }
        //inform about prompt
        [self.delegate iRateDidPromptForRating];
    }
}

- (void)applicationLaunched
{
    //check if this is a new version
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lastUsedVersion = [defaults objectForKey:iRateLastVersionUsedKey];
    if (!self.firstUsed || ![lastUsedVersion isEqualToString:self.applicationVersion])
    {
        [defaults setObject:self.applicationVersion forKey:iRateLastVersionUsedKey];
        if (!self.firstUsed || [self ratedAnyVersion])
        {
            //reset defaults
            [defaults setObject:[NSDate date] forKey:iRateFirstUsedKey];
            [defaults setInteger:0 forKey:iRateUseCountKey];
            [defaults setInteger:0 forKey:iRateEventCountKey];
            [defaults setObject:nil forKey:iRateLastRemindedKey];
            [defaults synchronize];
        }
        else if ([[NSDate date] timeIntervalSinceDate:self.firstUsed] > (self.daysUntilPrompt - 1) * SECONDS_IN_A_DAY)
        {
            //if was previously installed, but we haven't yet prompted for a rating
            //don't reset, but make sure it won't rate for a day at least
            self.firstUsed = [[NSDate date] dateByAddingTimeInterval:(self.daysUntilPrompt - 1) * -SECONDS_IN_A_DAY];
        }

        //inform about app update
        [self.delegate iRateDidDetectAppUpdate];
    }
    
    [self incrementUseCount];
    [self checkForConnectivityInBackground];
    if (self.promptAtLaunch && [self shouldPromptForRating])
    {
        [self promptIfNetworkAvailable];
    }
}

- (void)didDismissAlert:(__unused id)alertView withButtonAtIndex:(NSInteger)buttonIndex
{
    //get button indices
    NSInteger rateButtonIndex = 0;
    NSInteger cancelButtonIndex = [self showCancelButton]? 1: 0;
    NSInteger remindButtonIndex = [self showRemindButton]? cancelButtonIndex + 1: 0;
    
    if (buttonIndex == rateButtonIndex)
    {
        [self rate];
    }
    else if (buttonIndex == cancelButtonIndex)
    {
        [self declineThisVersion];
    }
    else if (buttonIndex == remindButtonIndex)
    {
        [self remindLater];
    }
    
    //release alert
    self.visibleAlert = nil;
}

#if TARGET_OS_IPHONE

- (void)applicationWillEnterForeground
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        [self incrementUseCount];
        [self checkForConnectivityInBackground];
        if (self.promptAtLaunch && [self shouldPromptForRating])
        {
            [self promptIfNetworkAvailable];
        }
    }
}

- (void)openRatingsPageInAppStore
{
    if (!_ratingsURL && !self.appStoreID)
    {
        self.checkingForAppStoreID = YES;
        if (!self.checkingForPrompt)
        {
            [self checkForConnectivityInBackground];
        }
        return;
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:self.ratingsURL])
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate will open the App Store ratings page using the following URL: %@", self.ratingsURL);
        }
        
        [[UIApplication sharedApplication] openURL:self.ratingsURL options:@{} completionHandler:nil];
        [self.delegate iRateDidOpenAppStore];
    }
    else
    {
         NSString *message = [NSString stringWithFormat:@"iRate was unable to open the specified ratings URL: %@", self.ratingsURL];
        
#if TARGET_IPHONE_SIMULATOR
        
        if ([[self.ratingsURL scheme] isEqualToString:iRateiOSAppStoreURLScheme])
        {
            message = @"iRate could not open the ratings page because the App Store is not available on the iOS simulator";
        }
        
#endif
        NSLog(@"%@", message);
        NSError *error = [NSError errorWithDomain:iRateErrorDomain code:iRateErrorCouldNotOpenRatingPageURL userInfo:@{NSLocalizedDescriptionKey: message}];
        [self.delegate iRateCouldNotConnectToAppStore:error];
    }
}

#else

- (void)openAppPageWhenAppStoreLaunched
{
    //check if app store is running
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications])
    {
        if ([app.bundleIdentifier isEqualToString:iRateMacAppStoreBundleID])
        {
            //open app page
            [[NSWorkspace sharedWorkspace] performSelector:@selector(openURL:) withObject:self.ratingsURL afterDelay:MAC_APP_STORE_REFRESH_DELAY];
            return;
        }
    }
    
    //try again
    [self performSelector:@selector(openAppPageWhenAppStoreLaunched) withObject:nil afterDelay:0.0];
}

- (void)openRatingsPageInAppStore
{
    if (!_ratingsURL && !self.appStoreID)
    {
        self.checkingForAppStoreID = YES;
        if (!self.checkingForPrompt)
        {
            [self checkForConnectivityInBackground];
        }
        return;
    }
    
    if (self.verboseLogging)
    {
        NSLog(@"iRate will open the App Store ratings page using the following URL: %@", self.ratingsURL);
    }
    
    [[NSWorkspace sharedWorkspace] openURL:self.ratingsURL];
    [self openAppPageWhenAppStoreLaunched];
    [self.delegate iRateDidOpenAppStore];
}

- (void)alertDidEnd:(__unused NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(__unused void *)contextInfo
{
    switch (returnCode)
    {
        case NSAlertAlternateReturn:
        {
            [self declineThisVersion];
            break;
        }
        case NSAlertDefaultReturn:
        {
            [self rate];
            break;
        }
        default:
        {
            [self remindLater];
        }
    }
    
    //release alert
    self.visibleAlert = nil;
}

#endif

- (void)logEvent:(BOOL)deferPrompt
{
    [self incrementEventCount];
    if (!deferPrompt && [self shouldPromptForRating])
    {
        [self promptIfNetworkAvailable];
    }
}

#pragma mark - User's actions

- (void)declineThisVersion
{
    //ignore this version
    self.declinedThisVersion = YES;

    //log event
    [self.delegate iRateUserDidDeclineToRateApp];
    
    [self markAsDeclined];
}

- (void)remindLater
{
    //remind later
    self.lastReminded = [NSDate date];

    //log event
    [self.delegate iRateUserDidRequestReminderToRateApp];
}

- (void)rate
{
    //mark as rated
    self.ratedThisVersion = YES;

    //log event
    [self.delegate iRateUserDidAttemptToRateApp];

    if ([self.delegate iRateShouldOpenAppStore])
    {
        //launch mac app store
        [self openRatingsPageInAppStore];
    }
    [self markAsReviewed];
}

-(BOOL)canShowAlertFromLastAction {
    double lastReviewedDate = [self lastReviewedDate];
    double lastDeclinedDate = [self lastDeclinedDate];
    double currentDate = [[NSDate date] timeIntervalSinceReferenceDate];
    double threshold = 60*60*24*30*3; // 90days
    
    if(lastReviewedDate > lastDeclinedDate) {
        if(currentDate - lastReviewedDate > threshold) {
            return true;
        }
    }
    else {
        if(currentDate - lastDeclinedDate > threshold) {
            return true;
        }
    }
    return false;
}

-(double)lastReviewedDate {
    double lastDate = [[NSUserDefaults standardUserDefaults]  doubleForKey:@"LastReviewedDate"];
    return  lastDate;
}

-(double)lastDeclinedDate {
    double lastDate = [[NSUserDefaults standardUserDefaults]  doubleForKey:@"LastDeclinedDate"];
    return  lastDate;
}

-(void)markAsReviewed  {
    [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSinceReferenceDate] forKey:@"LastReviewedDate"];
}

-(void)markAsDeclined {
    [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSinceReferenceDate] forKey:@"LastDeclinedDate"];
}

-(void)updateLastVersionReviewedDate {
    if(self.declinedAnyVersion) {
        double lastRatedDate = [self lastDeclinedDate];
        if(lastRatedDate == 0) {
            [self markAsDeclined];
        }
    }
    if(self.ratedAnyVersion) {
        double lastRatedDate = [self lastReviewedDate];
        if(lastRatedDate == 0) {
            [self markAsReviewed];
        }
    }
}
@end
