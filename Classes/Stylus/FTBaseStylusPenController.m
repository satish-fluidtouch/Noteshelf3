//
//  FTBaseStylusPenController.m
//  Noteshelf
//
//  Created by Amar Udupa on 13/5/14.
//
//

#import "FTBaseStylusPenController.h"
#import "PressurePenEngine.h"
#import "FTStylusPenControllers.h"
#import "FTWritingStyleManager.h"
#import "FTTouch.h"

extern float distanceBetweenPoints2(CGPoint a, CGPoint b);

@interface FTBaseStylusPenController ()

@end

@implementation FTBaseStylusPenController

@synthesize currentTouch = _currentTouch;
@synthesize viewID = _viewID;

#if STYLUS_PEN_CONTROLLER_DIAGNOSIS

static int instanceCounter = 0;

- (instancetype)init
{
    self = [super init];
    if (self) {
        instanceCounter++;
        NSLog(@"created: %d",instanceCounter);
    }
    return self;
}

- (void)dealloc
{
    instanceCounter--;
    NSLog(@"dealloc: %d",instanceCounter);
}
#endif

#pragma mark method to override
-(void)registerView:(UIView*)writingView delegate:(id<FTStylusPenDelegate>)inDelegate
{
    NSAssert(FALSE, @"%@ should override %s method",NSStringFromClass([self class]),__PRETTY_FUNCTION__);
}

-(BOOL)unregisterView:(UIView*)view
{
    NSAssert(FALSE, @"%@ should override %s method",NSStringFromClass([self class]),__PRETTY_FUNCTION__);
    return NO;
}

-(void)prePorcessTouchEvent:(UITouch*)touch position:(CGPoint)position
{
    //override if needed
}

-(void)touchesEndPostProcess
{
    //override if needed
}

-(void)updateTouchPropertiesIfNeeded
{
    //override if needed
    self.currentTouch.pressure = -1;
}

-(BOOL)stylusPenWristProtectionEnabled
{
    //override if needed
    return NO;
}

-(NSInteger)thresholdTouchRadius
{
    return 60;
}

#pragma mark touch process
// TODO: (AK) check time taken for this
- (void)processTouchesBegan:(NSSet *)touches event:(UIEvent*)event
{
    NSMutableSet *filteredTouches = [NSMutableSet set];
#if TEST_MAJOR_RADIUS
    [touches enumerateObjectsUsingBlock:^(UITouch *  _Nonnull obj, BOOL * _Nonnull stop) {
        if((obj.majorRadius <= [self thresholdTouchRadius]) || (obj.type == UITouchTypePencil)) {
            [filteredTouches addObject:obj];
        }
    }];
    if(filteredTouches.count == 0) {
        return;
    }
#else
    [filteredTouches addObjectsFromArray:touches.allObjects];
#endif
    NSEnumerator *e = [filteredTouches objectEnumerator];
	UITouch *tempTouch;
	
	UITouch *touch = [e nextObject];
    
	CGPoint curPos = [touch locationInView:[touch view]];
        
    BOOL isLandscape = false;
    if([self.delegate respondsToSelector:@selector(isNotebookInLandscapeOrientation)]) {
        isLandscape = [self.delegate isNotebookInLandscapeOrientation];
    }
    BOOL isInverted = false;
    if([self.delegate respondsToSelector:@selector(isNotebookInverted)]) {
        isLandscape = [self.delegate isNotebookInverted];
    }
    
	while ((tempTouch = [e nextObject]))
    {
		CGPoint tempPos = [tempTouch locationInView:[tempTouch view]];
		
        CGPoint newRefPoint = [FTWritingStyleManager newReferencePoint:curPos newPoint:tempPos forLandscape:isLandscape isInverted:isInverted];
        
        if (CGPointEqualToPoint(newRefPoint, tempPos))
        {
            curPos = tempPos;
            touch = tempTouch;
        }
    }
    [self prePorcessTouchEvent:touch position:curPos];
    
    if (!_currentTouch)
    {
        _currentTouch = [[FTTouch alloc] initWithTouchRecieverView:(UIView*)self.registeredView];
        _currentTouch.event = event;
        _currentTouch.currentPostion = curPos;
        self.palmRejectionRefPoint = curPos;
        
        _currentTouch.activeTouch = touch;
        self.currentStrokeBeginTime=[touch timestamp];
        self.currentStrokeFirstVertex=curPos;

        [self updateTouchPropertiesIfNeeded];
        if([self.delegate respondsToSelector:@selector(disableGestures)])
            [self.delegate disableGestures];
        
        [self.delegate stylusPenTouchBegan:_currentTouch];
		return;
	}
    {
        if ([FTWritingStyleManager isPointAboveLineForRefPoint:self.palmRejectionRefPoint currentPoint:curPos forLandscape:isLandscape isInverted:isInverted]
            || ((touch.type == UITouchTypePencil) && self.currentTouch.stylusType == kStylusFinger)) {
            [self updateTouchPropertiesIfNeeded];
            //Cancel the stroke in this case and start a fresh one
            [self.delegate stylusPenTouchCancelled:_currentTouch];
            
            _currentTouch.currentPostion = [touch locationInView:[touch view]];
            
            _currentTouch.event = event;
            _currentTouch.activeTouch = touch;
            self.currentStrokeBeginTime=[touch timestamp];
            self.currentStrokeFirstVertex=_currentTouch.currentPostion;
            self.palmRejectionRefPoint = _currentTouch.currentPostion;
            
            if([self.delegate respondsToSelector:@selector(disableGestures)])
                [self.delegate disableGestures];
            [self.delegate stylusPenTouchBegan:_currentTouch];
        }
        
	}
}

- (void)processTouchesMoved:(NSSet *)touches event:(UIEvent*)event
{
    if (!_currentTouch) return;
	
	if ([_currentTouch.activeTouch phase] != UITouchPhaseMoved){
		return;
	}

#if TEST_MAJOR_RADIUS
    if((_currentTouch.activeUItouch.type != UITouchTypePencil) && ([_currentTouch.activeTouch majorRadius] > [self thresholdTouchRadius])) {
        [self finalizedCancelledTouchForEvent:event];
        return;
    }
#endif
    UITouch *activeTouch = _currentTouch.activeTouch;
    BOOL isLandscape = false;
    if([self.delegate respondsToSelector:@selector(isNotebookInLandscapeOrientation)]) {
        isLandscape = [self.delegate isNotebookInLandscapeOrientation];
    }
    BOOL isInverted = false;
    if([self.delegate respondsToSelector:@selector(isNotebookInverted)]) {
        isLandscape = [self.delegate isNotebookInverted];
    }
    
	CGPoint curPos = _currentTouch.currentPostion = [activeTouch locationInView:[activeTouch view]];
    
    _currentTouch.event = event;

    [self prePorcessTouchEvent:activeTouch position:curPos];

	self.palmRejectionRefPoint = [FTWritingStyleManager newReferencePoint:self.palmRejectionRefPoint newPoint:curPos forLandscape:isLandscape isInverted:isInverted];
    [self updateTouchPropertiesIfNeeded];
    [self.delegate stylusPenTouchMoved:_currentTouch];
}

- (void)processTouchesEnded:(NSSet *)touches event:(UIEvent*)event
{
    if (!_currentTouch) {
        return;
    }
	
	if ([_currentTouch.activeTouch phase] != UITouchPhaseEnded)
    {
        return;
    }
    
    UITouch *activeTouch = _currentTouch.activeTouch;
    
    CGPoint curPos = _currentTouch.currentPostion = [activeTouch locationInView:[activeTouch view]];
    
    _currentTouch.event = event;

    [self prePorcessTouchEvent:activeTouch position:curPos];
    
    [self finalizeTouchesEndedForTouch:activeTouch currentPosition:curPos];

    _currentTouch = nil;
}

- (void)processTouchesCancelled:(NSSet *)touches event:(UIEvent*)event
{
    if (!_currentTouch) return;
	
	if (!([touches containsObject:_currentTouch.activeTouch] && [_currentTouch.activeTouch phase] == UITouchPhaseCancelled) )
		return;
    [self finalizedCancelledTouchForEvent:event];
}

-(void)finalizedCancelledTouchForEvent:(UIEvent*)event
{
    UITouch *activeTouch = _currentTouch.activeTouch;
    
    _currentTouch.currentPostion = [activeTouch locationInView:[activeTouch view]];
    
    _currentTouch.event = event;

    [self updateTouchPropertiesIfNeeded];
    
    [self.delegate stylusPenTouchCancelled:_currentTouch];
    
    if([self.delegate respondsToSelector:@selector(enableGestures)])
        [self.delegate enableGestures];
    
    _currentTouch = nil;
}

-(void)finalizeTouchesEndedForTouch:(UITouch*)activeTouch currentPosition:(CGPoint)curPos
{
    BOOL shouldCancelStroke = NO;

    if([self stylusPenWristProtectionEnabled]) {
        if(!self.smartPenTouchReceived) {
            if(! (
                  (self.currentStrokeBeginTime-self.previousStrokeEndTime) < SMART_PEN_MAX_TIME_INTERVAL &&
                  distanceBetweenPoints2(self.previousStrokeLastVertex,self.currentStrokeFirstVertex) < SMART_PEN_MAX_DISTANCE)
               ) {
                shouldCancelStroke = YES;
            }
        }
    }
    else {
        //Before deciding this as a valid stroke, check if it passes our criteria of wrist protection
        //If the time between the previous stroke's last vertex and current stroke's first vertex is less than our specified value and the distance between them is more than our specified value, we consider it as generated by palm and hence cancel it
        CGSize currentStrokeSize = [self.delegate sizeOfCurrentStroke];
        
        BOOL isLandscape = false;
        if([self.delegate respondsToSelector:@selector(isNotebookInLandscapeOrientation)]) {
            isLandscape = [self.delegate isNotebookInLandscapeOrientation];
        }
        BOOL isInverted = false;
        if([self.delegate respondsToSelector:@selector(isNotebookInverted)]) {
            isLandscape = [self.delegate isNotebookInverted];
        }
        
        CGPoint chosenPoint = [FTWritingStyleManager newReferencePoint:self.previousStrokeLastVertex
                                                              newPoint:self.currentStrokeFirstVertex
                                                          forLandscape:isLandscape isInverted:isInverted];
        if(CGPointEqualToPoint(chosenPoint, self.previousStrokeLastVertex) && (self.currentStrokeBeginTime - self.previousStrokeEndTime) < 0.3 &&
           distanceBetweenPoints2(self.previousStrokeLastVertex,self.currentStrokeFirstVertex) >200
           && (currentStrokeSize.width<WRIST_PROTECTION_STROKE_MAX_SIZE
               && currentStrokeSize.height<WRIST_PROTECTION_STROKE_MAX_SIZE)
           ) {
            shouldCancelStroke = YES;
        }
    }
    
    if(shouldCancelStroke && activeTouch.type == UITouchTypePencil) {
        shouldCancelStroke = NO;
    }
    
    if(shouldCancelStroke) {
        [self updateTouchPropertiesIfNeeded];
        [self.delegate stylusPenTouchCancelled:_currentTouch];
        if([self.delegate respondsToSelector:@selector(enableGestures)])
            [self.delegate enableGestures];
    }
    else {
        [self updateTouchPropertiesIfNeeded];
        self.previousStrokeLastVertex=curPos;
        self.previousStrokeEndTime=[activeTouch timestamp];
        
        [self touchesEndPostProcess];
        
        [self.delegate stylusPenTouchEnded:_currentTouch];
        if([self.delegate respondsToSelector:@selector(enableGestures)])
            [self.delegate enableGestures];
    }
}

@end
