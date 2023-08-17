//
//  FTEventsTracker.m
//  Noteshelf
//
//  Created by Akshay on 09/04/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTEventsTracker.h"
#import "Noteshelf-Swift.h"

void track( NSString * _Nonnull event,  NSDictionary * _Nullable params, NSString * _Nullable screenName) {
    #if !TARGET_OS_MACCATALYST
    [[FTMetrics shared] trackWithEvent:event params:params screeName:screenName];
    #endif
    FTCLSLog([NSString stringWithFormat:@"%@:%@", event, params]);
}
