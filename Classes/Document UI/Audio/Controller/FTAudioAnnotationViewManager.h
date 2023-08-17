//
//  FTAudioPlayerManager.h
//  Noteshelf
//
//  Created by Chandan on 13/8/15.
//
//

#import <Foundation/Foundation.h>
#import "FTAudioAnnotationConstants.h"
#import "FTAudioUtils.h"

@class FTAudioAnnotationViewController;

@interface FTAudioAnnotationViewManager : NSObject
{
    
}
@property(nonatomic,weak)id delegate;
@property (nonatomic,readonly,getter=selectedViewControllers)NSMutableArray *annotatonViewControllers;

+(instancetype)sharedManager;
-(CGFloat)currentPlayingRate;

-(void)showAudioControlForAnnoatation:(id<FTAudioAnnotationProtocol>)annotation
                           audioState:(AudioSessionState)state;

-(void)addViewForAudioAnnotation:(id<FTAudioAnnotationProtocol>)annotation
                            view:(UIView*)view
                      controller:(UIViewController*)controller
                           scale:(CGFloat)scale
                       eventType:(FTProcessEventType)eventType;

-(void)update:(CGFloat)scale;

-(void)removeViewForAudioAnnotation:(id<FTAudioAnnotationProtocol>)annotation;
-(void)cleanUP;
-(void)deSelectAllAnnotations:(BOOL)forceFully;
-(BOOL)isPlayerVisible;
-(BOOL)isExpanded;
-(void)updateOrientation:(UIInterfaceOrientation)interfaceOrientation alwaysInPortrait:(BOOL)alwaysInPortrait isInverted:(BOOL)isInverted;
-(void)deleteAnnotation:(id<FTAudioAnnotationProtocol>)audioAnnotation;

@end

@protocol FTAudioAnnotationViewManagerDelegates <NSObject>

-(void)annotationDidDeselect:(id<FTAudioAnnotationProtocol>)annotation;
-(void)annotationDidSelect:(id<FTAudioAnnotationProtocol>)annotation;
-(void)annotationDidDelete:(id<FTAudioAnnotationProtocol>)annotation;
-(void)annotation:(id<FTAudioAnnotationProtocol>)annotation didMoveToRect:(CGRect)newBoundingRect;
- (void)annotationView:(FTAudioAnnotationViewController*)annotationViewController
              exportAs:(id<FTAudioAnnotationProtocol>)annotation;

@end
