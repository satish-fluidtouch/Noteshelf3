//
//  FTTouch.h
//  Noteshelf
//
//  Created by Amar Udupa on 13/5/14.
//
//

#import <Foundation/Foundation.h>
@import FTRenderKit;

@interface FTTouch : NSObject<FTTouchProcess>

- (instancetype)initWithTouchRecieverView:(UIView*)view;

@property (strong) id activeTouch;

@property (assign) CGPoint currentPostion;

@property (assign) CGFloat pressure;

@property (assign) BOOL isSecondaryTouch;

@property (assign) StylusType stylusType;

@property (nonatomic,readonly)UITouch *activeUItouch;

@property (readonly) NSTimeInterval timeStamp;

@property (strong) UIEvent *event;

-(CGPoint)locationInView;

-(CGPoint)previousLocationInView;

@end
