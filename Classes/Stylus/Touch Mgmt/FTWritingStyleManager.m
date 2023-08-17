//
//  FTWritingStyleManager.m
//  Noteshelf
//
//  Created by Amar Udupa on 9/5/14.
//
//

#import "FTWritingStyleManager.h"


@implementation FTWritingStyleManager

+(CGFloat)angleForCurrentWiringStyle:(BOOL)isLandscape
                          isInverted:(BOOL)isInverted
{
    CGFloat angleToReturn = 0;
    FTWritingStyle style = [[NSUserDefaults standardUserDefaults] integerForKey:WRITING_STYLE_SELECTED];
    
    switch (style) {
        case FTWritingStyleRightBottom:
        {
            angleToReturn = 0.0f;//315.0f; In order to maintain the old version writing style, the angle is changed from 45 degree to 0 degree.
        }
            break;
        case FTWritingStyleRightCenter:
        {
            angleToReturn = 270.0f;
        }
            break;
        case FTWritingStyleRightTop:
        {
            angleToReturn = 225.0f;
        }
            break;
        case FTWritingStyleLeftBottom:
        {
            angleToReturn = 45.0f;
        }
            break;
        case FTWritingStyleLeftCenter:
        {
            angleToReturn = 90.0f;
        }
            break;
        case FTWritingStyleLeftTop:
        {
            angleToReturn = 135.0f;
        }
            break;
    }
    return isLandscape ? (isInverted ? (angleToReturn + 90.0) : (angleToReturn + 270.0)) : angleToReturn;
}

+(CGPoint)newReferencePoint:(CGPoint)currentRefPoint
                   newPoint:(CGPoint)newPoint
               forLandscape:(BOOL)isLandscape
                 isInverted:(BOOL)isInverted
{
    CGFloat angleDegrees = [self angleForCurrentWiringStyle:isLandscape isInverted:isInverted];
    CGFloat angle = (angleDegrees >= 360) ? (angleDegrees-360):angleDegrees;
    
    BOOL invertLogic = NO;
    if (angle >= 90 && angle < 270)
    {
        invertLogic = YES;
    }
    
    CGFloat slope = tanf(angle * M_PI/180);
    
    CGFloat b1 = currentRefPoint.y - (slope * currentRefPoint.x);
    CGFloat b2 = newPoint.y - (slope * newPoint.x);
    CGFloat distance = (b2-b1)/sqrtf((slope*slope) + 1);
    
    if (
        (!invertLogic && distance < 0) ||
        (invertLogic && distance > 0)
        )
    {
        return newPoint;
    }
    
    return currentRefPoint;
}


+(BOOL)isPointAboveLineForRefPoint:(CGPoint)refPoint
                      currentPoint:(CGPoint)curPoint
                    forLandscape:(BOOL)isLandscape
                        isInverted:(BOOL)isInverted
{
    CGFloat angleDegrees = [self angleForCurrentWiringStyle:isLandscape isInverted:isInverted];
    CGFloat angle = (angleDegrees >= 360) ? (angleDegrees-360):angleDegrees;
    
    BOOL invertLogic = NO;
    if (angle >= 90 && angle < 270)
    {
        invertLogic = YES;
    }
    
    CGFloat slope = tanf(angle * M_PI/180);
    DEBUGLOG(@"%.2f", angle);
    
    //y = slope * (x - refX) + refY
    CGFloat y = slope * (curPoint.x - refPoint.x) + refPoint.y;
    
    if (
        (!invertLogic && curPoint.y < y) ||
        (invertLogic && curPoint.y > y)
        )
    {
        return YES;
    }
    
    return NO;
}

/*
 Never used
 
+(CGFloat)parallelDistanceFromPoint:(CGPoint)point1
                            toPoint:(CGPoint)point2
                       forLandscape:(BOOL)isLandscape
{
    CGFloat angleDegrees = [self angleForCurrentWiringStyle:isLandscape];
    CGFloat angle = (angleDegrees >= 360) ? (360 - angleDegrees):angleDegrees;
    
    BOOL invertLogic = NO;
    if (angle >= 90 && angle < 270)
    {
        invertLogic = YES;
    }
    CGFloat slope = tanf(angle * M_PI/180);
    
    CGFloat b1 = point1.y - (slope * point1.x);
    CGFloat b2 = point2.y - (slope * point2.x);
    CGFloat distance = (b2-b1)/sqrtf((slope*slope) + 1);
    
    return invertLogic ? distance * -1 : distance;
}
*/

@end
