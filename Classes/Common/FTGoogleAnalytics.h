//
//  FTGoogleAnalytics.h
//  FTWhink
//
//  Created by Chandan on 15/6/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

//TODO: GOOGLE_ANALYTICS
#if GOOGLE_ANALYTICS
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#endif

#define GOOGLE_ANALYTICS_PRODUCTION_ID @"UA-67309609-1"
#define GOOGLE_ANALYTICS_DEV_ID @"UA-67306327-1"

CG_EXTERN NSString *const FTGoogleEventCategoryNotificationsKey;
CG_EXTERN NSString *const FTGoogleEventErrorNotificationsKey;
CG_EXTERN NSString *const FTGoogleEventUnexpectedErrorNotificationsKey;

@interface FTGoogleAnalytics : NSObject

+(void)logGoogleEventWithCategory:(NSString *)category
                           action:(NSString *)action
                            label:(NSString *)label
                            value:(NSNumber *)value;

+(void)logGoogleErrorWithDescription:(NSString *)description
                               fatal:(NSNumber *)fatal;

@end
