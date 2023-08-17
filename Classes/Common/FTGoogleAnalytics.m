//
//  FTGoogleAnalytics.m
//  FTWhink
//
//  Created by Chandan on 15/6/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTGoogleAnalytics.h"

NSString *const FTGoogleEventCategoryNotificationsKey = @"notifications";
NSString *const FTGoogleEventErrorNotificationsKey = @"Error";
NSString *const FTGoogleEventUnexpectedErrorNotificationsKey = @"Unexpected";

@implementation FTGoogleAnalytics

+(void)logGoogleEventWithCategory:(NSString *)category
                           action:(NSString *)action
                            label:(NSString *)label
                            value:(NSNumber *)value
{
    #if !TARGET_OS_MACCATALYST
#if GOOGLE_ANALYTICS
   NSAssert(category.length > 0 && action.length > 0, @"logGoogleEventWithCategory called with invalid parameters");
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category
                                                          action:action
                                                           label:label
                                                           value:value] build]];
#endif
    #endif
}

+(void)logGoogleErrorWithDescription:(NSString *)description
                               fatal:(NSNumber *)fatal
{
    #if !TARGET_OS_MACCATALYST
#if GOOGLE_ANALYTICS
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createExceptionWithDescription:description withFatal:fatal] build]];
#endif
    #endif
}

@end
