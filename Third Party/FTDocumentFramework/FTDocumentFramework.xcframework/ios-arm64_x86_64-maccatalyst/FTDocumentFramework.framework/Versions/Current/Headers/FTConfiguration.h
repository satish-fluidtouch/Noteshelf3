//
//  FTConfiguration.h
//  FTDocumentFramework
//
//  Created by Amar on 18/12/15.
//  Copyright © 2015 Fluid Touch. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FTGoogleAnalyticsProtocol <NSObject>

+(void)logGoogleEventWithScreen:(NSString *)screenID
                     GACategory:(NSString *)category
                       GAaction:(NSString *)action
                        GAlabel:(NSString *)label
                        GAvalue:(NSNumber *)value;

@end

CG_EXTERN Class<FTGoogleAnalyticsProtocol> gaClass;
