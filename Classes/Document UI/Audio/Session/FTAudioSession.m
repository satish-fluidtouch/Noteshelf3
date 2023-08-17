//
//  FTAudioSession.m
//  All My Days
//
//  Created by Chethan on 13/11/14.
//
//

#import "FTAudioSession.h"
#import "FTAudioRecordingModel.h"
#import "FTAudioTrackModel.h"

#define Default_SeekSlider_Length 1

NSString *const FTAudioSessionEventChangeNotification = @"FTAudioSessionDidChangeStateNotification";
NSString *const FTAudioSessionDidIntruptNotification = @"FTAudioSessionDidIntruptNotification";
NSString *const FTAudioSessionProgressNotification = @"FTAudioSessionProgressNotification";
NSString *const FTAudioSessionRecorderMeterDidChangeNotification = @"FTAudioSessionRecorderMeterDidChangeNotification";

NSString *const FTAudioSessionEventNotificationKey=@"FTAudioSessionEvent";
NSString *const FTAudioSessionStateNotificationKey = @"FTAudioSessionState";

NSString *const FTAudioSessionCurrentTimeNotificationKey = @"FTAudioSessionCurrentTime";
NSString *const FTAudioSessionDurationNotificationKey = @"FTAudioSessionTotalDuration";
NSString *const FTAudioSessionAudioRecordingNotificationKey=@"FTAudioSessionAudioRecording";
NSString *const FTAudioSessionMeterValueNotificationKey=@"FTAudioSessionMeterValue";

NSString *const FTAppDidEnterZoomMode = @"FTAppDidEnterZoomMode";
NSString *const FTAppDidEXitZoomMode = @"FTAppDidEXitZoomMode";

@interface FTAudioSession()<AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (strong,readwrite) FTAudioRecordingModel *audioRecording;
@property (strong) AVAudioRecorder *audioRecorder;
@property (assign) NSTimeInterval recordStartTime;
@property (strong) AVPlayer *audioPlayer;

@property (assign) AudioSessionState currentAudioState;
@property (strong) FTAudioTrackModel *currentAudioTrack;

@property (strong) NSTimer *seekTimer;
@property (strong) id playerTimeObserver;

@property (strong) NSTimer *recorderMeterTimer;
@property (assign)  float mRestoreAfterScrubbingRate;

@property (strong)  CADisplayLink *displaylink;

@property (nonatomic,assign) float seekSliderLength;

@property (assign) NSInteger windowHash;

@end


@implementation FTAudioSession
@synthesize audioRecording = _audioRecording;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onAudioSessionInterruptionEvent:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(routeChange:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:nil];
        
        self.mRestoreAfterScrubbingRate = 1;
        self.seekSliderLength = Default_SeekSlider_Length;
    }
    return self;
}

-(void)setAudioRecordingModel:(FTAudioRecordingModel* __nonnull)audioRecording
                    forWindow:(UIWindow* __nullable)window {
    if(self.audioRecording != audioRecording) {
        self.audioRecording = audioRecording;
    }
    if(self.windowHash != window.hash) {
        self.windowHash = window.hash;
        [self resetPlayback];
    }
}

-(FTAudioRecordingModel*)audioRecording
{
    return _audioRecording;
}

-(void) setAudioRecording:(FTAudioRecordingModel *)audioRecoding {
    if(_audioRecording != audioRecoding) {
        if(self.currentAudioState == AudioStatePlaying) {
            [self pausePlayback];
        }
        else if(self.currentAudioState == AudioStateRecording) {
            [self stopRecording];
        }
        [self resetPlayback];
        _audioRecording = audioRecoding;
    }
}

- (void) configureAVAudioSessionForState:(AudioSessionState)state
{
    //get your app's audioSession singleton object
    AVAudioSession* session = [AVAudioSession sharedInstance];
    NSError* error;
    
    if(state == AudioStateRecording || state == AudioStatePlaying)
    {
        //error handling
        BOOL success;
        
        //set the audioSession category.
        if(state == AudioStateRecording)
        {
            //Needs to be Record or PlayAndRecord to use audioRouteOverride:
            success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                                     error:&error];
        }
        else
        {
            success = [session setCategory:AVAudioSessionCategoryPlayback
                               withOptions: AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP|
                       AVAudioSessionCategoryOptionAllowAirPlay|AVAudioSessionCategoryOptionDefaultToSpeaker
                                     error:&error];
        }

        //activate the audio session
        success = [session setActive:YES error:&error];
    }
    else{
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone
                                   error:&error];
    }
}

#pragma mark- Accessors

-(AudioSessionState)audioSessionState
{
    return  self.currentAudioState;
}

-(NSString *)sessionID
{
    return self.audioRecording.fileName;
}

#pragma mark- Helpers

-(void)addPeriodicTimeObserverForPlayback
{
    if(self.playerTimeObserver)
        return;
    
    __weak FTAudioSession *audioSession = self;
    
    double tolerance =0;
    
    CMTime playerDuration = [self playbackDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        tolerance = 0.1f;
    }
    else
    {
        if(1 == self.seekSliderLength){
            tolerance = 0.1f;
        }
        else{
            double duration = CMTimeGetSeconds(playerDuration);
            CGFloat width = self.seekSliderLength;
            tolerance = 0.5f * duration / width;
        }
    }
    __weak AVPlayer *audioPlayer = audioSession.audioPlayer;
    self.playerTimeObserver =[self.audioPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC)
                                                                            queue:nil
                                                                       usingBlock:^(CMTime time) {
                                                                           if(nil != audioPlayer) {
                                                                               double currenTime = CMTimeGetSeconds([audioPlayer currentTime]);
                                                                               double totalDuration =CMTimeGetSeconds(audioPlayer.currentItem.duration);
                                                                               
                                                                               [audioSession postStatusNotificationOfCurrentTime:currenTime totalDuration:totalDuration];
                                                                           }
                                                                       }];
}

- (CMTime)playbackDuration
{
    AVPlayerItem *playerItem = [self.audioPlayer currentItem];
    if (playerItem.status != AVPlayerItemStatusFailed)
    {
        return([playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}


-(void)removePeriodicTimeObserverForPlayback
{
    if(self.playerTimeObserver){
        [self.audioPlayer removeTimeObserver:self.playerTimeObserver];
        self.playerTimeObserver = nil;
    }
}


-(void)postSessionEventNotification:(FTAudioSessionEvent)sessionState
{
    NSAssert(self.audioRecording, @"audioRecoding should not be nil");
    [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioSessionEventChangeNotification
                                                        object:self.audioRecording
                                                      userInfo:@{
                                                          FTAudioSessionAudioRecordingNotificationKey:self.audioRecording,
                                                          FTAudioSessionEventNotificationKey:@(sessionState),
                                                          FTRefreshWindowKey:@(self.windowHash)
                                                      }];
}


-(void)postStatusNotificationOfCurrentTime:(double)currentTime totalDuration:(double)duration
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[NSNumber numberWithInteger:self.currentAudioState] forKey:FTAudioSessionStateNotificationKey];
        [dict setObject:[NSNumber numberWithDouble:currentTime] forKey:FTAudioSessionCurrentTimeNotificationKey];
        [dict setObject:[NSNumber numberWithDouble:duration] forKey:FTAudioSessionDurationNotificationKey];
        [dict setObject:@(self.windowHash) forKey:FTRefreshWindowKey];
        
        if(self.audioRecording)
            [dict setObject:self.audioRecording forKey:FTAudioSessionAudioRecordingNotificationKey];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioSessionProgressNotification
                                                            object:self.audioRecording
                                                          userInfo:dict];
    });
}



#pragma mark - Merging of Audio

-(AVPlayerItem *)getMergedAudioItem
{
    NSArray *assets = [self.audioRecording tracksAssets];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
    __block double assetDuration = 0;
    [assets enumerateObjectsUsingBlock:^(AVURLAsset *urlAsset, NSUInteger idx, BOOL *stop) {
        
        AVAssetTrack * tracktoInsert = [[urlAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        if(nil != tracktoInsert) {
            NSError *error = nil;
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, urlAsset.duration)
                                ofTrack:tracktoInsert
                                 atTime: CMTimeMakeWithSeconds(assetDuration,NSEC_PER_SEC)
                                  error:&error];
            assetDuration+=CMTimeGetSeconds(urlAsset.duration);
        }
    }];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:composition];
    return item;
}

#pragma mark- Playback methods

-(CMTime)currentPlaybackTime
{
    return [self.audioPlayer currentTime];
}

-(BOOL)isPlaybackPaused
{
    BOOL pauseSate = NO;
    
    if(self.audioPlayer){
        double currentTime = CMTimeGetSeconds(self.audioPlayer.currentItem.currentTime);
        if(currentTime > 0 && self.audioPlayer.rate == 0){
            pauseSate=YES;
        }
    }
    return pauseSate;
}

-(double)getCurrentPlaybackTime
{
    double currentTime = CMTimeGetSeconds(self.audioPlayer.currentItem.currentTime);
    return currentTime;
}

-(void)resetPlayback
{
    if(self.audioPlayer){
        if(AudioStatePlaying == self.currentAudioState)
            [self stopPlayback];
        
        [self removeAudioPlayer];
        
        self.mRestoreAfterScrubbingRate = 1;
    }
}

-(void)resetSession {
    if (self.currentAudioState == AudioStatePlaying) {
        [self stopPlayback];
    }
    else if (self.currentAudioState == AudioStateRecording) {
        [self stopRecording];
    }
    [self resetPlayback];
}

#pragma mark- Recording

-(AVAudioRecorder *)audioRecorderForURL:(NSURL *)inURL
{
    AVAudioRecorder *audioRecorder =nil;
    
    if(inURL){
        
        [self configureAVAudioSessionForState:AudioStateRecording];
        
        // Define the recorder setting
        NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        [recordSetting setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
        audioRecorder = [[AVAudioRecorder alloc] initWithURL:inURL settings:recordSetting error:nil];
        
        audioRecorder.delegate = self;
        audioRecorder.meteringEnabled = YES;
        [audioRecorder prepareToRecord];
    }
    return audioRecorder;
}


#pragma mark- Action methods

-(void)startRecording
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioSessionAskedToAddPlayerNotification
                                                        object:self.audioRecording
                                                      userInfo:@{
                                                          FTAudioSessionEventNotificationKey:@(AudioStateRecording),
                                                          FTRefreshWindowKey:@(self.windowHash)
                                                      }];
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(granted){
                [self doAudioRecording];
            }
            else{
                [self postSessionEventNotification:FTAudioSessionRecordingPermissionDenied];
            }
        });
    }];
}

-(void)doAudioRecording
{
    FTAudioTrackModel *audioTrack = [[FTAudioTrackModel alloc] init];
    self.currentAudioTrack = audioTrack;
    
    FTAudioRecordingModel *model = [[FTAudioRecordingModel alloc] init];
    model.representedObject = self.audioRecording.representedObject;
    [model addAudioTrack:self.currentAudioTrack];
    
    self.currentAudioTrack = model.audioTracks.firstObject;
    
    self.audioRecorder = [self audioRecorderForURL:audioTrack.audioFileURL];
    self.currentAudioState = AudioStateRecording;
    [self.audioRecorder record];
    
    audioTrack.startTimeInterval = [NSDate timeIntervalSinceReferenceDate];
    
    double totalDuration = [self.audioRecording audioDuration];
    [self postStatusNotificationOfCurrentTime:totalDuration totalDuration:-1];
    [self startSeekTimer];
    [self postSessionEventNotification:FTAudioSessionDidStartRecording];
}

-(void)stopRecording
{
    if(self.currentAudioTrack){
        self.currentAudioTrack.endTimeInterval = [NSDate timeIntervalSinceReferenceDate];
        [self.audioRecorder stop];
        [self.audioRecording addAudioTrack:self.currentAudioTrack];
        
        [self stopSeekTimer];
        self.currentAudioState = AudioStateNone;
        [self postSessionEventNotification:FTAudioSessionDidStopRecording];
        [self configureAVAudioSessionForState:AudioStateNone];
    }
}

-(void)startPlayback
{
    
    [self configureAVAudioSessionForState:AudioStatePlaying];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    
    if([self isPlaybackPaused]){
        
        [self.audioPlayer play];
        self.audioPlayer.rate = self.mRestoreAfterScrubbingRate;
        self.currentAudioState = AudioStatePlaying;
        [self postSessionEventNotification:FTAudioSessionDidStartPlayback];
        [self addPeriodicTimeObserverForPlayback];
        
        //notify when audio get finish.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:self.audioPlayer.currentItem];
    }
    else{
        [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioSessionAskedToAddPlayerNotification
                                                            object:self.audioRecording
                                                          userInfo:@{
                                                              FTAudioSessionEventNotificationKey:@(AudioStatePlaying),
                                                              FTRefreshWindowKey:@(self.windowHash)
                                                          }];
        if(self.playerTimeObserver)
            [self removePeriodicTimeObserverForPlayback];
        
        [self removeAudioPlayer];
        AVPlayerItem *item = [self getMergedAudioItem];
        self.audioPlayer = [AVPlayer playerWithPlayerItem:item];
        [item addObserver:self forKeyPath:@"status" options:0 context:nil];
        [self.audioPlayer play];
        
        //notify when audio get finish.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:item];
    }
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.audioPlayer.currentItem && [keyPath isEqualToString:@"status"]) {
        int totalDuration = CMTimeGetSeconds([self.audioPlayer currentTime]);
        self.currentAudioState = AudioStatePlaying;
        [self postStatusNotificationOfCurrentTime:0 totalDuration:totalDuration];
        
        [self postSessionEventNotification:FTAudioSessionDidStartPlayback];
        [self addPeriodicTimeObserverForPlayback];
    }
}

-(void)stopPlayback
{
    [self stopSeekTimer];
    [self.audioPlayer pause];
    [self removeAudioPlayer];
     self.currentAudioState = AudioStateNone;
    [self postSessionEventNotification:FTAudioSessionDidStopPlayback];
}


-(void)removeAudioPlayer
{
    @try {
        [self.audioPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    } @catch (NSException *exception) {
    } @finally {
    }
    [self removePeriodicTimeObserverForPlayback];
    self.audioPlayer = nil;
}

-(void)pausePlayback
{
    [self.audioPlayer pause];
    self.currentAudioState = AudioStateNone;
    [self postSessionEventNotification:FTAudioSessionDidPausePlayback];
    [self removePeriodicTimeObserverForPlayback];
}


-(void)seekTime:(CMTime)time
{
    [self.audioPlayer seekToTime:time];
}


-(void)ratePlayback:(float)rate
{
    self.mRestoreAfterScrubbingRate = rate;
    
    [self.audioPlayer setRate:rate];
}

-(float)playbackRate;
{
    return self.audioPlayer.rate;
}


#pragma mark- AVQueuePlayer notification

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentAudioState = AudioStateNone;
        [self postSessionEventNotification:FTAudioSessionDidFinishPlayback];
        [self.audioPlayer seekToTime:CMTimeMakeWithSeconds(0,NSEC_PER_SEC)];
        [self.audioPlayer pause];
    });
}


#pragma mark - Audio session notifications

-(void) interruptAudioSession {

    if(AudioStateRecording == self.currentAudioState){

        [self stopRecording];

        [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioSessionDidIntruptNotification
                                                            object:self.audioRecording
                                                          userInfo:@{FTAudioSessionAudioRecordingNotificationKey:self.audioRecording,FTAudioSessionEventNotificationKey:@(FTAudioSessionRecordingDidIntrupt)}];
    }
    else if(AudioStatePlaying == self.currentAudioState){

        [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioSessionDidIntruptNotification
                                                            object:self.audioRecording
                                                          userInfo:@{FTAudioSessionAudioRecordingNotificationKey:self.audioRecording,FTAudioSessionEventNotificationKey:@(FTAudioSessionPlaybackDidIntrupt)}];
    }

}

- (void) onAudioSessionInterruptionEvent: (NSNotification *) notification
{
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        
        //Check to see if it was a Begin interruption
        if ([[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] isEqualToNumber:[NSNumber numberWithInt:AVAudioSessionInterruptionTypeBegan]]) {
            [self interruptAudioSession];
        } else if([[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] isEqualToNumber:[NSNumber numberWithInt:AVAudioSessionInterruptionTypeEnded]]){
            
            [[AVAudioSession sharedInstance] setActive: YES error: nil];

            if(AudioStatePlaying == self.currentAudioState){
                [self postSessionEventNotification:FTAudioSessionDidStartPlayback];
                [self.audioPlayer play];
            }
        }
    }
}


- (void)routeChange:(NSNotification*)notification
{
    
    NSDictionary *interuptionDict = notification.userInfo;
    AVAudioSessionRouteDescription *route = [interuptionDict objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonUnknown:
            break;
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // a headset was added or removed
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            
            // a headset was added or removed
            if(self.currentAudioState == AudioStatePlaying && [self hasHeadphonePortForAudioOut:route])
            {
                [self pausePlayback];
            }
            
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            break;
            
        case AVAudioSessionRouteChangeReasonOverride:
            break;
            
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            break;
            
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            break;
            
        default:
            break;
    }
}
#pragma mark- SeekTimer for recording

-(void)startSeekTimer
{
    [self stopSeekTimer];
    
    self.recordStartTime = self.audioRecorder.deviceCurrentTime;

    [self updateSeekTime:self.seekTimer];
    
    self.seekTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateSeekTime:) userInfo:nil repeats:YES];
    self.displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
    [self.displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
}

-(void)stopSeekTimer
{
    [self.seekTimer invalidate];
    self.seekTimer = nil;
    
    [self.displaylink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.displaylink = nil;
    
}

- (void)updateSeekTime:(NSTimer *)timer
{
    if(AudioStateRecording ==  self.currentAudioState){
        double totalDuration = [self.audioRecording audioDuration];
        double recordingTime =  totalDuration + (self.audioRecorder.deviceCurrentTime - self.recordStartTime);
        [self postStatusNotificationOfCurrentTime:recordingTime totalDuration:-1];
    }
}

-(void)updateMeters
{
    [self.audioRecorder updateMeters];
    
    /*
     float value = abs([self.audioRecorder averagePowerForChannel:0]);
     
     float   level;                // The linear 0.0 .. 1.0 value we need.
     float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
     float   decibels    = [self.audioRecorder averagePowerForChannel:0];
     
     if (decibels < minDecibels)
     {
     level = 0.0f;
     }
     else if (decibels >= 0.0f)
     {
     level = 1.0f;
     }
     else
     {
     float   root            = 2.0f;
     float   minAmp          = powf(10.0f, 0.05f * minDecibels);
     float   inverseAmpRange = 1.0f / (1.0f - minAmp);
     float   amp             = powf(10.0f, 0.05f * decibels);
     float   adjAmp          = (amp - minAmp) * inverseAmpRange;
     
     level = powf(adjAmp, 1.0f / root);
     }
     */
    
    CGFloat normalizedValue = pow (10, [self.audioRecorder averagePowerForChannel:0] / 20);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioSessionRecorderMeterDidChangeNotification
                                                        object:self.audioRecording
                                                      userInfo:@{
                                                          FTAudioSessionAudioRecordingNotificationKey:self.audioRecording,
                                                          FTAudioSessionMeterValueNotificationKey:[NSNumber numberWithFloat:(normalizedValue)],
                                                          FTRefreshWindowKey:@(self.windowHash)
                                                      }];
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
}

-(BOOL)hasHeadphonePortForAudioOut:(AVAudioSessionRouteDescription*)portDescription
{
    NSArray *outputPorts = portDescription.outputs;
    for (AVAudioSessionPortDescription *eachPort in outputPorts)
    {
        if ([eachPort.portType isEqualToString:AVAudioSessionPortHeadphones])
        {
            return YES;
        }
    }
    return NO;
}

@end
