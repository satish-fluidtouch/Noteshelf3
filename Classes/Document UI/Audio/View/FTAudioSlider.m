//
//  FTAudioSlider.m
//  FTWhink
//
//  Created by Chethan on 24/2/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTAudioSlider.h"

@implementation FTAudioSlider

//Since current audio slider handle as alpha component in the surrounding, adjusting the thumbRect when the handle reaches start and end point.
- (CGRect)thumbRectForBounds:(CGRect)bounds
                   trackRect:(CGRect)rect
                       value:(float)value
{
    CGRect result = [super thumbRectForBounds:bounds trackRect:rect value:value];
    if(self.minimumValue==value)
        result = CGRectOffset(result, -8, 0);
    else if(self.maximumValue== value)
        result = CGRectOffset(result, 8, 0) ;
    return result;
}

@end
