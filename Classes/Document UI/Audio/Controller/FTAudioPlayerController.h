//
//  FTAudioPlayerController.h
//  FTWhink
//
//  Created by Chethan on 19/2/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTAudioUtils.h"

@class FTAudioPlayerController,FTAudioAnnotation,FTAudioRecordingModel;

@protocol FTAudioPlayerControllerProtocol <NSObject>

typedef enum : NSInteger {
    KSlowRate=0,
    KNormalRate,
    KFastRate,
    KDoubleRate
}playbackRate;

@optional
- (void)audioPlayerDidClose:(FTAudioPlayerController *)controller;
- (void)audioPlayer:(FTAudioPlayerController *)controller navigateToAnnotation:(FTAudioAnnotation *)audioAnnotation;
- (void)audioPlayer:(FTAudioPlayerController *)controller goToRecordings:(FTAudioAnnotation *)audioAnnotation;
- (void)audioPlayer:(FTAudioPlayerController *)controller deleteAnnotation:(FTAudioAnnotation *)audioAnnotation;
- (void)audioPlayer:(FTAudioPlayerController*)controller didChangeTitle:(NSString *)title forAnnotation:(FTAudioAnnotation*)annotation;
- (void)audioPlayerDidExpand:(FTAudioPlayerController *)controller;
- (void)audioPlayerDidCollapse:(FTAudioPlayerController *)controller;
@required

@end

@interface FTAudioPlayerController : UIViewController
{
    
}

@property (nonatomic,weak) id<FTAudioPlayerControllerProtocol> delegate;
@property (nonatomic,strong) FTAudioRecordingModel *recordingModel;
@property (nonatomic,strong) FTAudioAnnotation *annotation;
@property(nonatomic,assign)CGFloat rate;
@property (nonatomic,readonly) bool isExpanded;
@property (nonatomic,assign) playbackRate playbackRate;

- (void)recordAudio;
- (void)applyRate;
- (void)playAudio;
- (void)pauseAudio;
- (void)removeController;
-(void)stopPlayOrRecording;
- (void)resetControllerForState:(AudioSessionState)audioState;
- (void)animateView:(CGFloat)delay state:(AudioSessionState)state;
- (void)fadeAnimation:(AudioSessionState)state;

#if TARGET_OS_MACCATALYST
- (UIMenu *)getContextMenu;
#endif

@end
