//
//  FTAudioUtils.h
//  Noteshelf
//
//  Created by Amar on 25/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

#ifndef FTAudioUtils_h
#define FTAudioUtils_h

CG_EXTERN NSString *const FTAudioAnnotationDidGetDeletedNotification;

typedef NS_ENUM(NSInteger, AudioSessionState)
{
    AudioStateNone=0,
    AudioStateRecording,
    AudioStatePlaying
};

typedef NS_ENUM(NSInteger, FTProcessEventType)
{
    FTProcessEventTypeSingleTap,
    FTProcessEventTypeSingleTapSelection,
    FTProcessEventTypeLongPress,
    FTProcessEventTypeDoubleTap,//Currently we removed the usage in Text Annotation addition, plan for the removal at other places like in Mac double tap to open the notebook.
    FTProcessEventTypeNone
};

typedef NS_ENUM(NSInteger, FTAnnotationState)
{
    FTAnnotationStateNone = 0,
    FTAnnotationStateSelect = 1UL << 0,
    FTAnnotationStateEdit   = 1UL << 1,
    FTAnnotationStateShowMenu = 1UL << 2,
    FTAnnotationStateHideMenu = 1UL << 3,
    FTAnnotationStateDeselect = 1UL << 4
} ;

CG_EXTERN CGFloat audioRecordSize;

#define kAudioRecIconSize CGSizeMake(audioRecordSize, audioRecordSize)

#endif /* FTAudioUtils_h */

@protocol FTPageProtocol;

@class FTAudioRecordingModel;
@protocol FTAudioAnnotationProtocol <NSObject>

@property (nonatomic,strong) FTAudioRecordingModel * _Nonnull recordingModel;
@property (nonatomic,assign) CGRect boundingRect;
@property (nonatomic,assign,readonly) BOOL isHidden;
@property (nonatomic,strong) NSString *_Nonnull uuid;

-(nullable NSURL*)audioFileURL:(nonnull NSString*)track;
-(nullable id<FTPageProtocol>)associatedNotebookPage;

@end
