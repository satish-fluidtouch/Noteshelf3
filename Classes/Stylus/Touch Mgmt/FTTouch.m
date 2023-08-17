//
//  FTTouch.m
//  Noteshelf
//
//  Created by Amar Udupa on 13/5/14.
//
//

#import "FTTouch.h"

@interface FTTouch ()

@property (weak) UIView *touchReceiverView;

@end

@implementation FTTouch

- (instancetype)initWithTouchRecieverView:(UIView*)view
{
    self = [super init];
    if (self) {
        self.pressure = -1;
        self.touchReceiverView = view;
    }
    return self;
}

-(UIView *)touchView
{
    if([self.activeTouch respondsToSelector:@selector(view)]) {
        UIView *view = [self.activeTouch view];
        if (!view) {
            view = self.touchReceiverView;
        }
        return view;
    }
    return nil;
}

- (CGPoint)locationInView:(UIView * _Nullable)view {
    CGPoint point = [self.activeUItouch locationInView:view];
    return point;
}

- (NSArray<id<FTTouchProcess>> * _Nullable)coalescedTouches {
    NSMutableArray *touches = [NSMutableArray array];
    NSArray *coalescedTouches = nil;
    coalescedTouches = [self.event coalescedTouchesForTouch:self.activeUItouch];

    for(id eachStroke in coalescedTouches) {
        FTTouch *touch = [[FTTouch alloc] init];
        touch.activeTouch = eachStroke;
        touch.touchReceiverView = self.touchReceiverView;
        [touches addObject:touch];
    }
    return touches;
}

- (NSArray<id<FTTouchProcess>> * _Nullable)predictiveTouches {
    NSMutableArray *touches = [NSMutableArray array];
    NSArray *predictiveTouches = nil;
    predictiveTouches = [self.event predictedTouchesForTouch:self.activeUItouch];
    for(id eachStroke in predictiveTouches) {
        FTTouch *touch = [[FTTouch alloc] init];
        touch.activeTouch = eachStroke;
        touch.touchReceiverView = self.touchReceiverView;
        [touches addObject:touch];
    }
    return touches;
}

-(UITouch *)activeUItouch
{
    return self.activeTouch;
}

-(NSTimeInterval)timeStamp
{
    UITouch *touch = self.activeTouch;
    NSTimeInterval timeStamp = touch.timestamp;
    return timeStamp;
}

-(CGPoint)locationInView
{
    return [self.activeUItouch locationInView:self.touchView];
}

-(CGPoint)previousLocationInView
{
    return [self.activeUItouch previousLocationInView:self.touchView];
}

@end
