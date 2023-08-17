//
//  FTNormalTouchController.m
//  Noteshelf
//
//  Created by Amar Udupa on 13/5/14.
//
//

#import "FTNormalTouchController.h"
#import <objc/runtime.h>
#import "FTWritingStyleManager.h"
#import "FTTouch.h"

@import FTRenderKit;

@interface FTNormalTouchController ()

@end

@implementation FTNormalTouchController

@synthesize registeredView = _registeredView;
@synthesize viewID = _viewID;
@synthesize delegate = _stylusDelegate;

-(void)registerView:(UIView*)writingView delegate:(id<FTStylusPenDelegate>)inDelegate
{
    //NSLog(@"class %@",[self class]);
    self.viewID = [NSString stringWithFormat:@"%p",writingView];
    self.registeredView = writingView;
    self.delegate = inDelegate;
}

-(BOOL)unregisterView:(UIView*)view
{
    if([self.viewID isEqualToString:[NSString stringWithFormat:@"%p",view]]) {
        return YES;
    }
    return NO;
}

-(void)prePorcessTouchEvent:(UITouch*)touch position:(CGPoint)position
{
    if (self.currentTouch.activeUItouch.type == UITouchTypePencil)
    {
        self.smartPenTouchReceived = YES;
    }
}

-(void)touchesEndPostProcess
{
    self.smartPenTouchReceived = NO;
}

-(void)updateTouchPropertiesIfNeeded
{
    if (self.currentTouch.activeUItouch.type == UITouchTypePencil)
    {
        self.currentTouch.stylusType = kStylusApplePencil;
        
        if(self.currentTouch.activeUItouch.phase != UITouchPhaseEnded)
        {
            [super updateTouchPropertiesIfNeeded];
            BOOL isPressureSensitivity = [[NSUserDefaults standardUserDefaults] boolForKey:@"APPLE_PENCIL_SETTINGS_PRESSURE"];
            if(isPressureSensitivity) {
                if ([self.delegate penType] == FTPenTypePencil) {
                    self.currentTouch.pressure = self.currentTouch.activeUItouch.force * 0.8; //0.5
                } else if ([self.delegate penType] == FTPenTypePen || [self.delegate penType] == FTPenTypeCaligraphy) {
                    self.currentTouch.pressure = self.currentTouch.activeUItouch.force * 0.4 * 1.5;
                }
                else {
                    self.currentTouch.pressure = self.currentTouch.activeUItouch.force * 0.4;
                }
            }
        }
    }
    else
    {
        [super updateTouchPropertiesIfNeeded];
        self.currentTouch.stylusType = kStylusFinger;
    }
}

#pragma mark touch handling
- (void)processTouchesBegan:(NSSet *)touches event:(UIEvent *)event {
    UITouch *applePencilTouch = [self applePencilTouch:touches];
    if([self.delegate isApplePencilEnabled] || (nil != applePencilTouch)) {
        if(nil != applePencilTouch) {
            [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"isUsingApplePencil"];
            if(![self.delegate isApplePencilEnabled]) {
                [self.delegate enableApplePencil];
            }
            [super processTouchesBegan:[NSSet setWithObject:applePencilTouch] event:event];
        }
        UITouch *activeTouch = [self activeTouch:touches];
        if (nil != activeTouch && nil == applePencilTouch && [self.delegate shouldProcessTouch: activeTouch]) {
            [super processTouchesBegan:touches event:event];
        }
    }
    else {
        [super processTouchesBegan:touches event:event];
    }
}

- (void)processTouchesMoved:(NSSet *)touches event:(UIEvent *)event {
    [super processTouchesMoved:touches event:event];
}

- (void)processTouchesEnded:(NSSet *)touches event:(UIEvent *)event {
    [super processTouchesEnded:touches event:event];
}

- (void)processTouchesCancelled:(NSSet *)touches event:(UIEvent *)event {
    [super processTouchesCancelled:touches event:event];
}

-(UITouch*)activeTouch:(NSSet*)touches
{
    __block UITouch *touch = nil;
    [touches enumerateObjectsUsingBlock:^(UITouch*  _Nonnull obj, BOOL * _Nonnull stop) {
        touch = obj;
        *stop = YES;
    }];
    return touch;
}

-(UITouch*)applePencilTouch:(NSSet*)touches
{
    __block UITouch *touch = nil;
    [touches enumerateObjectsUsingBlock:^(UITouch*  _Nonnull obj, BOOL * _Nonnull stop) {
        if(obj.type == UITouchTypePencil)
        {
            touch = obj;
            *stop = YES;
        }
    }];
    return touch;
}

@end
