//
//  FTTouchGestureRecognizer.m
//  Noteshelf
//
//  Created by Amar Udupa on 27/8/13.
//
//

#import "FTTouchGestureRecognizer.h"

@implementation FTTouchGestureRecognizer

-(BOOL)evaluateGesture
{
    if(self.numberOfTouches == 2)
        return YES;
    else
        return NO;
}
@end
