//
//  FTPanGestureRecognizer.m
//  Noteshelf
//
//  Created by Rama Krishna on 18/6/13.
//
//

#import <UIKit/UIGestureRecognizerSubclass.h>
#import "FTPanGestureRecognizer.h"

const CGFloat edgeThresholdOffset = 30.0f;
const CGFloat minFingerMovementDistance = 30.0f;

@interface FTPanGestureRecognizer ()

@property (strong) NSInvocation *activieInvocation;

@end

@implementation FTPanGestureRecognizer
@dynamic activieInvocation;

-(BOOL)evaluateGesture{
    
    
    CGFloat p1Angle = angleBetweenPoints(startLocation1, changedLocation1);
    CGFloat p2Angle = angleBetweenPoints(startLocation2, changedLocation2);
    
    float firstFingerMovement  = distanceBetweenPoints2(changedLocation1,startLocation1);
    float secondFingerMovement = distanceBetweenPoints2(changedLocation2,startLocation2);
    
    CGFloat currentDistanceBetweenFingers=distanceBetweenPoints2(changedLocation1,changedLocation2);
    
    //Fail in touches travelling in opposite directions
//    if ( (p1Angle < 0 && p2Angle > 0) || (p1Angle > 0 && p2Angle < 0) ) {
//        self.state = UIGestureRecognizerStateRecognized;
//        return NO;
//    }
    if(self.numberOfTouches < 2) {
        if(firstFingerMovement > 20) {
            return YES;
        }
    }
    else {
        BOOL distanceCheck = (currentDistanceBetweenFingers < distanceBetweenFingers + 10.0) || (currentDistanceBetweenFingers > distanceBetweenFingers - 10.0);
        
        if(
           distanceBetweenFingers < 350
           && distanceCheck
           && fabs(p1Angle - p2Angle) < 30
           && firstFingerMovement > minFingerMovementDistance
           && secondFingerMovement > minFingerMovementDistance
           )
        {
            //DEBUGLOG(@"Pan++:\n p1Angle: %.2f,\n p2Angle: %.2f,\n absDiff: %.2f,\n firstFingerMovement: %.2f,\n secondFingerMovement: %.2f,\n distanceBetweenFingers: %.2f,\n currentDistanceBetweenFingers: %.2f, ", p1Angle, p2Angle, fabs(p1Angle - p2Angle), firstFingerMovement, secondFingerMovement, distanceBetweenFingers, currentDistanceBetweenFingers);
            return YES;
        }
    }
    
    //DEBUGLOG(@"Pan--:\n p1Angle: %.2f,\n p2Angle: %.2f,\n absDiff: %.2f,\n firstFingerMovement: %.2f,\n secondFingerMovement: %.2f", p1Angle, p2Angle, fabs(p1Angle - p2Angle), firstFingerMovement, secondFingerMovement);
    
    return NO;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if([self isBottomEdgePan:touches]) {
        self.state = UIGestureRecognizerStateRecognized;
        return;
    }
    [super touchesBegan:touches withEvent:event];
}

-(void)reset
{
    [super reset];
    self.recognitionType = FTPanRecognitionTypeDefault;
}

-(BOOL)isBottomEdgePan:(NSSet*)touches
{
    BOOL isBottomEdgePan = false;
    for (UITouch *eachTouch in touches)
    {
        CGPoint loc = [eachTouch locationInView:nil];
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        
        screenRect.origin.y = screenRect.size.height-10;
        screenRect.size.height = 10;
        if(CGRectContainsPoint(screenRect, loc)) {
            isBottomEdgePan = true;
            break;
        }
    }
    return isBottomEdgePan;
}
@end
