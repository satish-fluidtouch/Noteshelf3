//
//  FTBaseStylusPenController.h
//  Noteshelf
//
//  Created by Amar Udupa on 13/5/14.
//
//

#import <Foundation/Foundation.h>
#import "FTStylusPenProtocol.h"

typedef NS_ENUM(NSInteger, FTStrokeStatus)
{
    FTStrokeStatusDoNothing,
    FTStrokeStatusCancel,
    FTStrokeStatusValid,
};

@class FTTouch;

@interface FTBaseStylusPenController : NSObject
{
    FTTouch *_currentTouch;
}

@property (assign) CGPoint palmRejectionRefPoint;
@property (assign) NSTimeInterval currentStrokeBeginTime;
@property (assign) NSTimeInterval previousStrokeEndTime;
@property (assign) CGPoint previousStrokeLastVertex;
@property (assign) CGPoint currentStrokeFirstVertex;

@property (strong) FTTouch *currentTouch;

@property (weak) UIView *registeredView;

@property (weak) id<FTStylusPenDelegate> delegate;

@property (strong) NSString *viewID;

@property (assign) BOOL smartPenTouchReceived;

#pragma mark override
-(NSInteger)thresholdTouchRadius;

-(void)registerView:(UIView*)writingView
           delegate:(id<FTStylusPenDelegate>)inDelegate;

-(BOOL)unregisterView:(UIView*)view;

-(void)prePorcessTouchEvent:(UITouch*)touch position:(CGPoint)position;

-(void)finalizeTouchesEndedForTouch:(UITouch*)activeTouch currentPosition:(CGPoint)curPos;

-(void)updateTouchPropertiesIfNeeded;

-(BOOL)stylusPenWristProtectionEnabled;

-(void)touchesEndPostProcess;

#pragma mark Point Process

- (void)processTouchesBegan:(NSSet *)touches event:(UIEvent*)event;
- (void)processTouchesMoved:(NSSet *)touches event:(UIEvent*)event;
- (void)processTouchesEnded:(NSSet *)touches event:(UIEvent*)event;
- (void)processTouchesCancelled:(NSSet *)touches event:(UIEvent*)event;

@end
