//
//  FTStylusPenManager.m
//  Noteshelf
//
//  Created by Amar Udupa on 13/5/14.
//
//

#import "FTStylusPenManager.h"
#import "PressurePenEngine.h"
#import "FTStylusPenControllers.h"
#import "Noteshelf-Swift.h"

#if !TARGET_OS_MACCATALYST
@interface FTStylusPenManager ()
#else
@interface FTStylusPenManager ()
#endif
@property (strong) NSMutableArray *stylusPenControllers;

@end

@implementation FTStylusPenManager

+(instancetype)sharedInstance
{
    static FTStylusPenManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FTStylusPenManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.stylusPenControllers = [NSMutableArray array];
    }
    return self;
}

-(FTBaseStylusPenController*)stylusPenControllerForView:(UIView*)view
{
    NSArray *filtereedArray = [self.stylusPenControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"viewID == %@",[NSString stringWithFormat:@"%p",view]]];
    return filtereedArray.firstObject;
}

-(void)registerView:(UIView*)view delegate:(id<FTStylusPenDelegate>)delegate
{
    FTBaseStylusPenController *controller = [self stylusPenControllerForView:view];
    FTBaseStylusPenController *newController = nil;
    
    if([delegate respondsToSelector:@selector(shouldAlwaysUseFingerTouch)] && [delegate shouldAlwaysUseFingerTouch]) {
        //Normal Touch related pen controller initialize
        if(![controller isKindOfClass:[FTNormalTouchController class]]) {
            newController = [[FTNormalTouchController alloc] init];
        }
    }
    else {
        if ([NSUserDefaults isApplePencilEnabled]) {
            //apple pencil
            if(![controller isKindOfClass:[FTNormalTouchController class]]) {
                newController = [[FTNormalTouchController alloc] init];
            }
        }
        else {
            //Normal Touch related pen controller initialize
            if(![controller isKindOfClass:[FTNormalTouchController class]]) {
                newController = [[FTNormalTouchController alloc] init];
            }
        }
    }
    
    if(newController) {
        if(controller) {
            BOOL success = [controller unregisterView:view];
            if(success)
            {
                [self.stylusPenControllers removeObject:controller];
                controller = nil;
            }
        }
        [newController registerView:view delegate:delegate];
        [self.stylusPenControllers addObject:newController];
    }
}

-(void)unregisterView:(UIView*)view setToDefault:(BOOL)setToDefault
{
    FTBaseStylusPenController *controller = [self stylusPenControllerForView:view];
    BOOL unregistered = [controller unregisterView:view];
    if(unregistered)
    {
        [self.stylusPenControllers removeObject:controller];
        if(setToDefault)
        {
            [self registerView:view delegate:controller.delegate];
        }
    }
}

#pragma mark Point Process

- (void)processTouchesBegan:(NSSet *)touches event:(UIEvent*)event view:(UIView*)view {
    FTBaseStylusPenController *controller = [self stylusPenControllerForView:view];
    [controller processTouchesBegan:touches event:event];
}

- (void)processTouchesMoved:(NSSet *)touches event:(UIEvent*)event view:(UIView*)view  {
    FTBaseStylusPenController *controller = [self stylusPenControllerForView:view];
    [controller processTouchesMoved:touches event:event];
}

- (void)processTouchesEnded:(NSSet *)touches event:(UIEvent*)event view:(UIView*)view  {
    FTBaseStylusPenController *controller = [self stylusPenControllerForView:view];
    [controller processTouchesEnded:touches event:event];
}

- (void)processTouchesCancelled:(NSSet *)touches event:(UIEvent*)event view:(UIView*)view  {
    FTBaseStylusPenController *controller = [self stylusPenControllerForView:view];
    [controller processTouchesCancelled:touches event:event];
}

@end
