//
//  FTTwoTouchBaseGestureRecognizer.h
//  Noteshelf
//
//  Created by Developer on 7/18/13.
//
//

#import <UIKit/UIKit.h>

extern float distanceBetweenPoints2(CGPoint a, CGPoint b);

@interface FTTwoTouchBaseGestureRecognizer : UIGestureRecognizer{
    
@public
    
    CGPoint startLocation1, startLocation2;
    CGPoint changedLocation1, changedLocation2;
    
    NSTimeInterval firstTouchTime;
    NSTimeInterval secondTouchTime;
    NSTimeInterval currentTime;
    
    CGFloat distanceBetweenFingers;
}

@property (assign)NSInteger maxNumberOfTouches; //default is 2 . 0 will have no limit
-(BOOL)evaluateGesture;

@end
