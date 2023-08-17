//
//  FTAudioSession.h
//  All My Days
//
//  Created by Chethan on 13/11/14.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FTAudioUtils.h"

@class FTAudioRecordingModel;

typedef enum FTAudioSessionEvent : NSUInteger {
    FTAudioSessionEventNone=0,
    FTAudioSessionRecordingPermissionDenied,
    FTAudioSessionDidStartRecording,
    FTAudioSessionDidStopRecording,
    FTAudioSessionRecordingDidIntrupt,
    FTAudioSessionDidStartPlayback,
    FTAudioSessionDidPausePlayback,
    FTAudioSessionDidStopPlayback,
    FTAudioSessionDidFinishPlayback,
    FTAudioSessionPlaybackDidIntrupt
}FTAudioSessionEvent;

//Notification keys
CG_EXTERN NSString *const FTAudioSessionEventNotificationKey;
CG_EXTERN NSString *const FTAudioSessionStateNotificationKey;
CG_EXTERN NSString *const FTAudioSessionCurrentTimeNotificationKey;
CG_EXTERN NSString *const FTAudioSessionDurationNotificationKey;
CG_EXTERN NSString *const FTAudioSessionAudioRecordingNotificationKey;
CG_EXTERN NSString *const FTAudioSessionMeterValueNotificationKey;

//Notification Name
CG_EXTERN NSString *const FTAudioSessionRecorderMeterDidChangeNotification;
CG_EXTERN NSString *const FTAudioSessionEventChangeNotification;
CG_EXTERN NSString *const FTAudioSessionDidIntruptNotification;
CG_EXTERN NSString *const FTAudioSessionProgressNotification;

CG_EXTERN NSString *const FTAppDidEnterZoomMode;
CG_EXTERN NSString *const FTAppDidEXitZoomMode;

@interface FTAudioSession : NSObject
{

}

@property (strong,readonly) FTAudioRecordingModel *audioRecording;

-(AudioSessionState)audioSessionState;
-(NSString *)sessionID;

-(void)setAudioRecordingModel:(FTAudioRecordingModel* __nonnull)audioRecording
                    forWindow:(UIWindow* __nullable)window;
-(void)startRecording;
-(void)stopRecording;
-(void)startPlayback;
-(void)pausePlayback;
-(void)stopPlayback;
-(float)playbackRate;

-(void)seekTime:(CMTime)time;
-(void)ratePlayback:(float)rate;

-(CMTime)playbackDuration;
-(CMTime)currentPlaybackTime;

//Reset the player.
-(void)resetSession;
-(NSInteger)windowHash;

@end
