//
//  FTAnnotaionUtilities.m
//  FTWhink
//
//  Created by Chethan on 9/2/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTAnnotationUtilities.h"

@implementation FTAnnotationUtilities


+ (UIFont *)audioSessionTitleFont
{
    return [UIFont fontWithName:@"Avenir Medium" size:16];
}

+ (UIFont *)audioSessionDateTimeFont
{
    return [UIFont fontWithName:@"Avenir Medium" size:14];
}

+ (UIFont *)audioSliderTimeFont
{
    return [UIFont fontWithName:@"Avenir Medium" size:12];
}

+ (NSString *)shortTimeFormatted:(NSUInteger)totalSeconds
{
    NSInteger
    seconds = 0,minutes = 0,hours=0;
    NSString *formatString = @"";
    
    hours = totalSeconds / 3600;
    if(hours > 0){
        seconds = totalSeconds % 60;
        minutes = (totalSeconds / 60) % 60;
        hours = totalSeconds / 3600;
        
        formatString = [NSString stringWithFormat:@"%02ld:%02ld",(long)hours,(long)minutes];
    }
    else{
        seconds = totalSeconds % 60;
        minutes = (totalSeconds / 60);
        formatString = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
    }
    
    return formatString;
}

+ (NSString *)timeFormatted:(NSUInteger)totalSeconds
{
    NSInteger
    seconds = 0,minutes = 0,hours=0;
    NSString *formatString = @"";

    hours = totalSeconds / 3600;
    if(hours > 0){
        seconds = totalSeconds % 60;
        minutes = (totalSeconds / 60) % 60;
        hours = totalSeconds / 3600;
        
        formatString = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",(long)hours, (long)minutes, (long)seconds];
    }
    else{
        seconds = totalSeconds % 60;
        minutes = (totalSeconds / 60);
        formatString = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
    }
    
    return formatString;
}

double roundOffValue(double value)
{
    value = ceil(value);
    return value;
}
@end
