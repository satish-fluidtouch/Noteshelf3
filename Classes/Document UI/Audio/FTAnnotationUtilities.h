//
//  FTAnnotaionUtilities.h
//  FTWhink
//
//  Created by Chethan on 9/2/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTAnnotationUtilities : NSObject

+ (UIFont *)audioSessionTitleFont;
+ (UIFont *)audioSessionDateTimeFont;
+ (UIFont *)audioSliderTimeFont;

+ (NSString *)timeFormatted:(NSUInteger)totalSeconds;
+ (NSString *)shortTimeFormatted:(NSUInteger)totalSeconds;

double roundOffValue(double value);

@end

