//
//  FTTwoTouchBaseGestureRecognizer.m
//  Noteshelf
//
//  Created by Developer on 7/18/13.
//
//

#import <UIKit/UIGestureRecognizerSubclass.h>
#import "FTTwoTouchBaseGestureRecognizer.h"

#define ALLOWED_TOUCH_INTERVAL 0.2

@interface FTTwoTouchBaseGestureRecognizer()

@property (nonatomic, strong) NSInvocation *activieInvocation;

@end

@implementation FTTwoTouchBaseGestureRecognizer

@synthesize activieInvocation;


-(id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if(self)
    {
        NSMethodSignature *signature = [target methodSignatureForSelector:action];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:target];
        [invocation setSelector:action];
        
        for (NSInteger i = 2; i<signature.numberOfArguments; i++) {
            [invocation setArgument:&self atIndex:i];
        }
        self.activieInvocation = invocation;
        self.maxNumberOfTouches = 2;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [super touchesBegan:touches withEvent:event];
    if([self.delegate respondsToSelector:@selector(gestureRecognizerShouldBegin:)]) {
        if(![self.delegate gestureRecognizerShouldBegin:self]) {
            self.state = UIGestureRecognizerStateRecognized;
            return;
        }
    }
    if([self.delegate respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)]) {
        if(![self.delegate gestureRecognizer:self shouldReceiveTouch:touches.anyObject]) {
            self.state = UIGestureRecognizerStateRecognized;
            return;
        }
    }

    if (self.numberOfTouches > 2 || [self hasApplePencilTouch:touches]) {
        self.state = UIGestureRecognizerStateRecognized;
        return;
    }
    
    if(self.numberOfTouches == 0) {
        return;
    }

    if (!firstTouchTime) {
        firstTouchTime = [NSDate timeIntervalSinceReferenceDate];
    }
    
    if (self.numberOfTouches == 2) {
        
        if (!secondTouchTime) secondTouchTime = [NSDate timeIntervalSinceReferenceDate];
        startLocation1 = [self locationOfTouch:0 inView:nil];
        startLocation2 = [self locationOfTouch:1 inView:nil];
    }
    else if(self.maxNumberOfTouches == 0) {
        startLocation1 = [self locationOfTouch:0 inView:nil];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [super touchesMoved:touches withEvent:event];
    
    currentTime = [NSDate timeIntervalSinceReferenceDate];
    
    //Still only 1 touch moving
    if (self.numberOfTouches < 2 && self.maxNumberOfTouches != 0)
    {
        //Fail if the second touch did not arrive even after ALLOWED_TOUCH_INTERVAL
        if (currentTime - firstTouchTime > ALLOWED_TOUCH_INTERVAL) {
            self.state = UIGestureRecognizerStateRecognized;
            return;
        }
        return;
    }
    
    if ([self hasApplePencilTouch:touches])
    {
        self.state = UIGestureRecognizerStateRecognized;
        return;
    }
    
    if(self.numberOfTouches == 0) {
        return;
    }
    changedLocation1 = [self locationOfTouch:0 inView:nil];
    CGFloat p1Angle = angleBetweenPoints(startLocation1, changedLocation1);

    if(self.numberOfTouches == 2) {
        changedLocation2 = [self locationOfTouch:1 inView:nil];
        CGFloat p2Angle = angleBetweenPoints(startLocation2, changedLocation2);
        if (p1Angle == 0 || p2Angle == 0) {
            return;
        }
    }
    else {
        if(self.numberOfTouches >= 2) {
            
        }
        if (p1Angle == 0) {
            return;
        }
    }

    if([self evaluateGesture] == YES){
        
        self.state = UIGestureRecognizerStateFailed;
        [self.activieInvocation invoke];
        return;
    }
}

-(BOOL)evaluateGesture{
    //Subclass should override
    return NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    self.state = UIGestureRecognizerStateRecognized;
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    self.state = UIGestureRecognizerStateRecognized;
}

-(void)reset {
    [super reset];
    firstTouchTime = 0;
    secondTouchTime = 0;
}

-(BOOL)hasApplePencilTouch:(NSSet <UITouch*>*)touches
{
    __block BOOL hasApplePencilTouch = NO;
    if(![touches.anyObject respondsToSelector:@selector(type)])
        return hasApplePencilTouch;
    
    [touches enumerateObjectsUsingBlock:^(UITouch * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.type != UITouchTypeDirect)
        {
            hasApplePencilTouch = YES;
            *stop = YES;
        }
    }];
    return hasApplePencilTouch;
}
@end
