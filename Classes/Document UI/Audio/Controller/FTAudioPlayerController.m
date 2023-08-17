//
//  FTAudioPlayerController.m
//  FTWhink
//
//  Created by Chethan on 19/2/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTAudioPlayerController.h"
#import "FTAudioSession.h"
#import "FTAudioSessionManager.h"
#import "FTAnnotationUtilities.h"
#import "FTAudioRecordingModel.h"
#import "Noteshelf-Swift.h"

@import FTRenderKit;

NSString *const FTAudioAnnotationDidGetDeletedNotification = @"FTAudioAnnotationDidGetDeletedNotification";

typedef enum : NSInteger {
    KSlowRate=0,
    KNormalRate,
    KFastRate,
    KDoubleRate
}playbackRate;

@interface FTAudioPlayerView : UIView

@property (weak) IBOutlet UIView *contentView;

@end

@implementation FTAudioPlayerView

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self) {
        return nil;
    }
    return view;
}

@end
@interface FTAudioPlayerController ()
{
    BOOL inZoomMode;
    UIUserInterfaceSizeClass previousVericalSizeClass;
}
@property (weak, nonatomic) IBOutlet FTCustomLabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxDurationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *expandImageView;
@property (weak, nonatomic) IBOutlet UIButton *rateButton;
@property (nonatomic,assign) playbackRate playbackRate;
@property (weak, nonatomic) IBOutlet UIView *closeButtonView;

@property (nonatomic,weak)   FTAudioSession *audioSession;
@property (assign) BOOL isPaused;
@property (nonatomic,assign)AudioSessionState currentState;

@property (nonatomic,readwrite) bool isExpanded;

@property (nonatomic,weak) IBOutlet UIButton *firstButton;
@property (nonatomic,weak) IBOutlet UIButton *secondButton;

//Deliberatiely making these strongs beacasue after changing their isActive status they are being set to nil.
@property (nonatomic,strong) IBOutlet NSLayoutConstraint *playerViewLeadingToSuperView;
@property (weak, nonatomic) IBOutlet UIView *expandView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *playerViewTrailingToSuperView;
@property (nonatomic,strong) IBOutlet NSLayoutConstraint *compressableViewWidth;
@property (weak, nonatomic) IBOutlet UIStackView *normalStackView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chevronToSuperViewLeading;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIStackView *recordingStackView;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (nonatomic,weak) IBOutlet FTInfiniteWave *infiniteBar;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@end

@implementation FTAudioPlayerController

-(IBAction)discolsureIndicatorAction:(id)sender {
    [self animateAudioControllerView:self.isExpanded isAnimated:YES];
    [self handleSuperViewFrameUpdates:self.isExpanded];
}

- (IBAction)didTapCloseButton:(id)sender {
     [self stopPlayOrRecording];
     if(self.delegate && [self.delegate respondsToSelector:@selector(audioPlayerDidClose:)]){
         [self.delegate performSelector:@selector(audioPlayerDidClose:) withObject:self];
     }
}


- (IBAction)didTapCollapseButton:(id)sender {
    [self animateAudioControllerView:self.isExpanded isAnimated:YES];
    [self handleSuperViewFrameUpdates:self.isExpanded];
}

-(void)handleSuperViewFrameUpdates:(bool)isExpanded {
    if (isExpanded) {
        if([self.delegate respondsToSelector:@selector(audioPlayerDidExpand:)]) {
            [self.delegate audioPlayerDidExpand:self];
        }
    }
    else {
        if([self.delegate respondsToSelector:@selector(audioPlayerDidCollapse:)]) {
            [self.delegate audioPlayerDidCollapse:self];
        }
    }
}

-(void)animateAudioControllerView:(bool)isExpanded isAnimated: (BOOL)shouldAnimate{
    CGFloat duration = 0.4;
    self.playerViewLeadingToSuperView.constant = 8;
    self.playerViewTrailingToSuperView.constant = 8;
    [self.durationLabel setHidden:false];
    if (isExpanded == true) {
        self.isExpanded = false;
        [NSLayoutConstraint deactivateConstraints:[NSArray arrayWithObject:self.playerViewLeadingToSuperView]];
        [self.infiniteBar stop];
        self.infiniteBar.hidden = true;
        [self.recordingStackView setHidden:true];
        [self.closeButtonView setHidden:true];
        if (shouldAnimate) {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
                [self.expandImageView setImage:[UIImage systemImageNamed:@"chevron.backward.2"]];
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished){
                [self.contentView setNeedsDisplay];
            }];

        } else {
            [self.expandImageView setImage:[UIImage systemImageNamed:@"chevron.backward.2"]];
            [self.view layoutIfNeeded];
            [self.contentView setNeedsDisplay];
        }
        [self configureMoreButton:self.moreButton];
    }
    else {
        self.isExpanded = true;
        [NSLayoutConstraint activateConstraints:[NSArray arrayWithObject:self.playerViewLeadingToSuperView]];
        [self.recordingStackView setHidden:false];
        if (self.isRegularClass && self.isExpanded) {
            [self.closeButtonView setHidden:false];
            [self.rateButton setHidden:false];
        } else {
            [self.closeButtonView setHidden:true];
            [self.rateButton setHidden:true];
            [self.durationLabel setHidden:true];
        }
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void) {
            [self.expandImageView setImage:[UIImage systemImageNamed:@"chevron.forward.2"]];
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished){
            [self startInfiniteWaveIfNeeded];
            [self.contentView setNeedsDisplay];
        }];
        [self configureMoreButton:self.moreButton];
    }
}

#pragma mark - life cycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    #if TARGET_OS_MACCATALYST
        UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self.view addInteraction:interaction];
    #endif
    
    self.currentState = AudioStateNone;
    [self configureUI];
    [self animateAudioControllerView:self.isExpanded isAnimated:NO];
    [self resetPlayBack];
    UIViewController *rootViewController = [[UIApplication sharedApplication].delegate window].rootViewController;
    previousVericalSizeClass = rootViewController.traitCollection.verticalSizeClass;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterZoomMode:) name:FTAppDidEnterZoomMode object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidExitZoomMode:) name:FTAppDidEXitZoomMode object:nil];
    [self configureMoreButton:self.moreButton];
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateViewConstraints {
    if (self.isExpanded) {
        [self.closeButtonView setHidden: !self.isRegularClass];
        [self.rateButton setHidden: !self.isRegularClass];
        [self.durationLabel setHidden: !self.isRegularClass];
    }
    [self configureMoreButton:self.moreButton];
    [self handleSuperViewFrameUpdates:YES];
    [super updateViewConstraints];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self.view setNeedsUpdateConstraints];
}
#pragma mark - update

-(void)configureUI
{
    self.isExpanded = true;//Default its in expanded state.
    self.durationLabel.text = @"00:00";
    #if !TARGET_OS_MACCATALYST
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"knob"] forState:UIControlStateNormal];
    #endif
    self.contentView.layer.cornerRadius = 12;
}

-(void)setRecordingModel:(FTAudioRecordingModel *)recordingModel
{
    [self removeAudioSessionNotifications];
    _recordingModel = recordingModel;
    [self resetPlayBack];
    [self observeAudioSessionNotifications];
}

- (void)resetPlayBack
{
    double duration = [self.recordingModel audioDuration];
    self.progressSlider.value = 0.0f;
    self.progressSlider.minimumValue = 0.0f;
    self.progressSlider.maximumValue = duration;

    NSDictionary *defaultRate = [self getDefaultRate];
    [self.rateButton setTitle:defaultRate[@"Title"] forState:UIControlStateNormal];
    self.playbackRate = KNormalRate;
}


-(void)updateControlsForState:(AudioSessionState)state model:(FTAudioRecordingModel *)model
{
    self.currentState = state;
    switch (state) {
        case AudioStateRecording:{
            [self.rateButton setEnabled:NO];
            self.progressSlider.hidden = true;
            [self startInfiniteWaveIfNeeded];
            self.contentView.backgroundColor = [[[UIColor alloc] initWithHexString:@"FFE6E4"] colorWithAlphaComponent:1.0];
        }
            break;
        case AudioStatePlaying:{
            [self.rateButton setEnabled:YES];
            self.infiniteBar.hidden = true;
            self.progressSlider.hidden = false;
            self.contentView.backgroundColor = [UIColor clearColor];
        }
            break;
            
        case AudioStateNone:{
            [self.rateButton setEnabled:YES];
            self.infiniteBar.hidden = true;
            self.progressSlider.hidden = false;
            self.contentView.backgroundColor = [UIColor clearColor];
        }
            break;
    }
    if(model){
        CGFloat duration = [model audioDuration];
        NSString *durationString = [FTAnnotationUtilities timeFormatted:duration];
        [self updateDuration:durationString forState:self.currentState];
        self.progressSlider.minimumValue = 0.0f;
        self.progressSlider.maximumValue = duration;
    }
    [self changeImageForState:state];
}

-(void)updateDuration:(NSString *)string forState:(AudioSessionState)state
{
    self.durationLabel.text = string;
}

- (void)updateUIForCurrentTime:(double)currentTime
{
    self.progressSlider.value = currentTime;
}

-(CGFloat)rate
{
    return [[self sessionValueForRate:self.playbackRate] floatValue];
}

#pragma mark - public methods

-(void)pauseAudio {
    [self.audioSession pausePlayback];
    [self changeImageForState:AudioStateNone];
}

-(void)resume {
    
    CGFloat rate = [[self sessionValueForRate:self.playbackRate] floatValue];
    [self.audioSession ratePlayback:rate];

    [self changeImageForState:AudioStatePlaying];
}

-(void)stopPlayback {
    [self resetPlayBack];
    [self changeImageForState:AudioStateNone];
}

-(void)startRecording {
    if(self.currentState == AudioStatePlaying) {
        [self stopPlayback];
    }
    [self resetPlayBack];
    [self startInfiniteWaveIfNeeded];
    self.progressSlider.hidden = true;
    
    [self changeImageForState:AudioStateRecording];
}

-(void)stopRecording {
    [self resetPlayBack];
    [self.infiniteBar stop];
    self.infiniteBar.hidden = true;
    self.progressSlider.hidden = false;
    
    self.currentState = AudioStateNone;
    
    [self changeImageForState:AudioStateNone];
}

-(void)changeImageForState:(AudioSessionState)audioState {
    switch (audioState) {
        case AudioStateRecording:
            [self.secondButton setImage :[UIImage systemImageNamed:@"stop.fill"] forState:UIControlStateNormal];
            [self.firstButton setEnabled:false];
            break;
        case AudioStatePlaying:
            [self.secondButton setImage :[UIImage systemImageNamed:@"pause.fill"] forState:UIControlStateNormal];
            [self.firstButton setEnabled:false];
            break;
        case AudioStateNone:
            [self.secondButton setImage :[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
            [self.firstButton setEnabled:true];
            break;
    }
}

//Need to be reviewed regarding naming of the funcitons.
-(IBAction)firstButtonAction {
    BOOL isSamewindow = YES;
    if(self.audioSession.windowHash != self.view.window.hash) {
        [self.audioSession resetSession];
        isSamewindow = NO;
    }
    if(!isSamewindow || self.recordingModel != self.audioSession.audioRecording) {
        [self.audioSession setAudioRecordingModel:self.recordingModel forWindow:self.view.window];
    }
    if(AudioStatePlaying == self.currentState){
        [self.audioSession stopPlayback];
    }
    else if(AudioStateNone == self.currentState) {
        __block __weak FTAudioPlayerController *weakSelf = self;
        [FTPermissionManager isMicrophoneAvailableOnViewController:self onCompletion:^(BOOL success) {
            if(success) {
                [weakSelf.audioSession startRecording];
            }
        }];
    }
    else if(AudioStateRecording == self.currentState) {
        [self.audioSession stopRecording];
    }
}

-(IBAction)secondButtonAction {

    BOOL isSamewindow = YES;
    if(self.audioSession.windowHash != self.view.window.hash) {
        [self.audioSession resetSession];
        isSamewindow = NO;
    }
    if(!isSamewindow || (self.recordingModel != self.audioSession.audioRecording)) {
        [self.audioSession setAudioRecordingModel:self.recordingModel forWindow:self.view.window];
    }
    if(AudioStatePlaying == self.currentState){
        [self pauseAudio];
    }
    else if(AudioStateNone == self.currentState) {
        [self.audioSession startPlayback];
    } else if(AudioStateRecording == self.currentState) {
        [self.audioSession stopRecording];
    }
    [self scrub:self.progressSlider];
}

-(void)recordAudioMenuItemAction {
    BOOL isSamewindow = YES;
    if(self.audioSession.windowHash != self.view.window.hash) {
        [self.audioSession resetSession];
        isSamewindow = NO;
    }
    if(!isSamewindow || self.recordingModel != self.audioSession.audioRecording) {
        [self.audioSession setAudioRecordingModel:self.recordingModel forWindow:self.view.window];
    }
    if(self.currentState == AudioStatePlaying) {
        [self.audioSession stopPlayback];
    }
    __block __weak FTAudioPlayerController *weakSelf = self;
    [FTPermissionManager isMicrophoneAvailableOnViewController:self onCompletion:^(BOOL success) {
        if(success) {
            [weakSelf.audioSession startRecording];
        }
    }];
}

//old
-(void)recordAudio
{
    [self startRecording];
}

-(void)applyRate {
    NSDictionary *rateInfo = [self getNextPlayBackRateInfo];
    self.playbackRate = [rateInfo[@"AudioRateType"] integerValue];
    [self.audioSession ratePlayback:[rateInfo[@"AudioRate"] floatValue]];
    [self.rateButton setTitle:rateInfo[@"Title"] forState:UIControlStateNormal];
    if(self.currentState == AudioStateNone) {
        [self.audioSession startPlayback];
    }
}

-(void)playAudioMenuItemAction
{
    [self.audioSession startPlayback];
}

-(void)playAudio
{
    [self resume];
}


- (void)stopRecord
{
    [self.audioSession stopRecording];
}

-(void)resetControllerForState:(AudioSessionState)audioState
{
    [self resetPlayBack];
    if(self.recordingModel.fileName == self.audioSession.sessionID) {
        [self.audioSession resetSession];
    }
    self.audioSession = nil;
    self.durationLabel.text = @"00:00";
    [self updateControlsForState:audioState model:nil];
}

-(void)animateView:(CGFloat)delay state:(AudioSessionState)state
{
    if(AudioStateRecording == state){
        [self recordAudio];
    }
    else{
        [self playAudio];
    }
}

-(void)fadeAnimation:(AudioSessionState)state
{
    [self audioSession];
    [self.audioSession setAudioRecordingModel:self.recordingModel forWindow:self.view.window];
    if(AudioStateRecording == state){
        [self recordAudio];
    }
    else{
        [self playAudio];
    }
}

#pragma mark - Helpers

-(void)stopPlayOrRecording
{
    if(self.currentState == AudioStateRecording){
        [self.audioSession stopRecording];
    }
    else if(self.currentState == AudioStatePlaying){
        [self.audioSession stopPlayback];
    }
}

- (void)startInfiniteWaveIfNeeded {
    if(self.currentState == AudioStateRecording) {
        self.infiniteBar.hidden = false;
        if([AVAudioSession sharedInstance].recordPermission == AVAudioSessionRecordPermissionGranted) {
            [self.infiniteBar start];
        }
    }
    else {
        self.infiniteBar.hidden = true;
    }
}


#pragma mark - Audio Related

-(FTAudioSession *)audioSession
{
    return [[FTAudioSessionManager sharedSession] activeSession];
}

#pragma mark - Action methods


- (void)removeController
{
    [self close:nil];
}

- (IBAction)close:(id)sender
{
    if ([sender isKindOfClass:[UISwipeGestureRecognizer class]]
        && self.isExpanded) {
        return;
    }
    [self stopPlayOrRecording];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(audioPlayerDidClose:)]){
        [self.delegate performSelector:@selector(audioPlayerDidClose:) withObject:self];
    }
}

- (BOOL)isRecording
{
    BOOL isRecording = NO;
    
    FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
    NSString *sessionID = session.sessionID;
    
    if([sessionID isEqualToString:self.recordingModel.fileName]){
        if(AudioStateRecording == session.audioSessionState){
            isRecording = YES;
        }
    }
    return isRecording;
}

- (BOOL)isPlaying
{
    BOOL isPlaying = NO;
    
    FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
    NSString *sessionID = session.sessionID;
    
    if([sessionID isEqualToString:self.recordingModel.fileName]){
        if(AudioStatePlaying == session.audioSessionState){
            isPlaying = YES;
        }
    }
    return isPlaying;
}

#pragma mark - FTAudioSession Notification

-(void)removeAudioSessionNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTAudioSessionEventChangeNotification object:self.recordingModel];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTAudioSessionDidIntruptNotification object:self.recordingModel];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTAudioSessionProgressNotification object:self.recordingModel];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTAudioAnnotationDidGetDeletedNotification object:self.recordingModel];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTAudioSessionRecorderMeterDidChangeNotification object:self.recordingModel];

}

-(void)observeAudioSessionNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionDidChange:) name:FTAudioSessionEventChangeNotification object:self.recordingModel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionDidInterrupt:) name:FTAudioSessionDidIntruptNotification object:self.recordingModel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionDidProgress:) name:FTAudioSessionProgressNotification object:self.recordingModel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioTrackDidDeleted:) name:FTAudioAnnotationDidGetDeletedNotification object:self.recordingModel];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionMeterDidChange:) name:FTAudioSessionRecorderMeterDidChangeNotification object:self.recordingModel];
}

#pragma mark Notification methods

-(void)audioSessionMeterDidChange:(NSNotification *)notification
{
    if(![self isSameWindow:notification]) {
        return;
    }
    NSDictionary *usefInfo = notification.userInfo;
    FTAudioRecordingModel *model = usefInfo[FTAudioSessionAudioRecordingNotificationKey];
    NSString *sessionId = model.fileName;
    DEBUGLOG(sessionId);
}

-(BOOL)isSameWindow:(NSNotification*)notification {
    NSDictionary *userinfo = notification.userInfo;
    NSUInteger windowHash = [[userinfo objectForKey:FTRefreshWindowKey] unsignedIntegerValue];
    NSInteger currentWindowHash = self.view.window.hash;
    
    if(windowHash != currentWindowHash) {
        return false;
    }
    return true;
}

-(void)audioSessionDidChange:(NSNotification *)notification
{
    if(![self isSameWindow:notification]) {
        return;
    }
    NSDictionary *userinfo = notification.userInfo;
    
    FTAudioSessionEvent state = [[userinfo valueForKey:FTAudioSessionEventNotificationKey] integerValue];
    FTAudioRecordingModel *audioModel = [userinfo valueForKey:FTAudioSessionAudioRecordingNotificationKey];
    
     if(FTAudioSessionDidStopRecording == state || FTAudioSessionRecordingPermissionDenied ==state ){
        
        if(FTAudioSessionDidStopRecording == state){
            [self stopRecording];
            [self updateControlsForState:AudioStateNone model:audioModel];
        }
        else
        {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"AudioRecord_Permission_Message", @"AudioRecord_Permission_Message") preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil];
            [alertController addAction:action];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    
    else if(FTAudioSessionDidStartRecording == state ){
        [self startInfiniteWaveIfNeeded];
        [self updateControlsForState:AudioStateRecording model:audioModel];
    }
    else if(FTAudioSessionDidPausePlayback == state || FTAudioSessionDidStopPlayback == state || FTAudioSessionDidFinishPlayback == state){
        if(FTAudioSessionDidStopPlayback == state || FTAudioSessionDidFinishPlayback == state) {
            [self stopPlayback];
        }
        [self updateControlsForState:AudioStateNone model:audioModel];
    }
    else if(FTAudioSessionDidStartPlayback == state){
        [self updateControlsForState:AudioStatePlaying model:audioModel];
    } else {
        [self updateControlsForState:AudioStateNone model:audioModel];
    }
}

-(void)audioSessionDidProgress:(NSNotification *)notification
{
    if(![self isSameWindow:notification]) {
        return;
    }
    NSDictionary *userInfo = notification.userInfo;
    FTAudioRecordingModel *audioModel = [userInfo valueForKey:FTAudioSessionAudioRecordingNotificationKey];

    if([audioModel.fileName isEqualToString:self.recordingModel.fileName]){
        AudioSessionState state = [userInfo[FTAudioSessionStateNotificationKey] integerValue];
        double currentSeekTime = ceil([userInfo[FTAudioSessionCurrentTimeNotificationKey] doubleValue]);
        NSString *durationString = [FTAnnotationUtilities timeFormatted:currentSeekTime];
        [self updateDuration:durationString forState:state];
        if(AudioStatePlaying == state && !self.progressSlider.isTracking){
            [self updateDuration:durationString forState:AudioStatePlaying];
            self.progressSlider.value = ceil(currentSeekTime);
            [self syncScrubber];
        }
    }
}

-(void)audioSessionDidInterrupt:(NSNotification *)notification
{
    if(self.currentState == AudioStatePlaying){
        [self pauseAudio];
    } else if(self.currentState == AudioStateRecording) {
        [self stopRecording];
        [self updateControlsForState:AudioStateNone model:self.recordingModel];
    }
}

-(void)audioTrackDidDeleted:(NSNotification *)notification
{
    FTAudioRecordingModel *recordingModel = notification.object;
    if(
       (nil == self.recordingModel.representedObject)
       || [self.recordingModel.representedObject.uuid isEqualToString:recordingModel.representedObject.uuid]
       ) {
        [self removeController];
    }
}

#pragma mark - Slider

///* The user is dragging the movie controller thumb to scrub through the movie. */
- (IBAction)beginScrubbing:(id)sender
{
    self.isPaused =([self.audioSession playbackRate]) ? NO : YES;

    if(!self.isPaused){
        [self pauseAudio];
    }
}

///* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender
{
    if ([sender isKindOfClass:[UISlider class]]){
        
        UISlider* slider = sender;
        
        FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
        
        CMTime playerDuration = [session playbackDuration];
        
        double time = 0;
        
        if (!CMTIME_IS_INVALID(playerDuration)) {
            
            double duration = CMTimeGetSeconds(playerDuration);
            if (isfinite(duration)){
                
                float minValue = [slider minimumValue];
                float maxValue = [slider maximumValue];
                float value = [slider value];
                time = duration * (value - minValue) / (maxValue - minValue);
                [session seekTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];

                NSString *durationString = [FTAnnotationUtilities timeFormatted:time];
                [self updateDuration:durationString forState:AudioStatePlaying];
            }
        }
    }
}

///* The user has released the movie thumb control to stop scrubbing through the movie. */
- (IBAction)endScrubbing:(id)sender
{
    if(!self.isPaused){
        [self.audioSession startPlayback];
        [self resume];
    }
}

///* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
    FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
    
    CMTime playerDuration = [session playbackDuration];
    if (CMTIME_IS_INVALID(playerDuration)){
        self.progressSlider.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)){
        float minValue = [self.progressSlider minimumValue];
        float maxValue = [self.progressSlider maximumValue];
        double time = CMTimeGetSeconds([session currentPlaybackTime]);
        
        double currentSeekTime = (maxValue - minValue) * time / duration + minValue;
        
        [self.progressSlider setValue:currentSeekTime];
    }
}

#pragma mark - Playback Rate

- (IBAction)applyRate:(id)sender
{
    [self applyRate];
}

- (NSDictionary *)getDefaultRate
{
    NSDictionary *dict = @{@"AudioRateType":[NSNumber numberWithInt:KNormalRate],
                           @"AudioRate":@1.0f,@"Title":@"1x"};
    return dict;
}

-(NSNumber*)sessionValueForRate:(playbackRate)rate
{
    NSNumber *speed;
    switch (rate) {
        case KSlowRate:{
            speed = @0.7f;
        }
            break;
        case KNormalRate:{
            speed = @1.0f;
        }
            break;
        case KFastRate:{
            speed = @1.5f;
        }
            break;
        case KDoubleRate:{
            speed = @2.0f;
        }
            break;
            
        default:
            speed = @1.0f;
            break;
    }
    return speed;
}

- (NSDictionary *)getNextPlayBackRateInfo
{
    NSNumber *speed = @1.0f;
    playbackRate rate = KNormalRate;
    NSString *buttonTitle = @"1x";
    
    switch ((int)self.playbackRate) {
        case KSlowRate:
            rate = KNormalRate;
            speed = [self sessionValueForRate:rate];
            buttonTitle = @"1x";
            break;
            
        case KNormalRate:
            rate = KFastRate;
            speed = [self sessionValueForRate:rate];
            buttonTitle = @"1.5x";
            break;
            
        case KFastRate:
            rate = KDoubleRate;
            speed = [self sessionValueForRate:rate];
            buttonTitle = @"2x";
            break;
            
        case KDoubleRate:
            rate = KSlowRate;
            speed = [self sessionValueForRate:rate];
            buttonTitle = @"0.7x";
            break;
            
        default:
            break;
    }
    
    NSDictionary *dict = @{@"AudioRateType":[NSNumber numberWithInt:rate],
                           @"AudioRate":speed,@"Title":buttonTitle};
    return dict;
}


-(void)appDidEnterZoomMode:(NSNotification*)notification
{
    inZoomMode = YES;
}

-(void)appDidExitZoomMode:(NSNotification*)notification
{
    inZoomMode = NO;
}

-(IBAction)compactModeControlAction:(id)sender {
    UITapGestureRecognizer *tapGesuture = (UITapGestureRecognizer *)sender;
    if([tapGesuture.view isKindOfClass:[FTStyledLabel class]]) {
        if(self.isExpanded == NO) {
            [self showAlertForWhatActionNeedToBePerformed];
        }
    }
    else if([tapGesuture.view isKindOfClass:[UIImageView class]]) {
        if(self.isExpanded == NO) {
            [self showAlertForWhatActionNeedToBePerformed];
        }
    }
}

#pragma mark - UIResponder
- (BOOL)canBecomeFirstResponder {
    return true;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (self.isFirstResponder
            && (action == @selector(recordAudioMenuItemAction)
                || action == @selector(playAudioMenuItemAction)
                || action == @selector(stopRecord)
                || action == @selector(pauseAudio)
                || action == @selector(discolsureIndicatorAction:)
                || action == @selector(close:)));
}

#pragma mark - CompactMenu
-(void)showAlertForWhatActionNeedToBePerformed {
    [self becomeFirstResponder];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showMenu];
    });
}

- (void)showMenu
{
#if !TARGET_OS_MACCATALYST
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    [self setupMenuItems];
    [theMenu update];
    [theMenu showMenuFromView:self.view rect:self.contentView.frame];
#endif
}

- (void)setupMenuItems
{
    NSMutableArray *menuItems = [[NSMutableArray alloc] init];
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    
    UIMenuItem *recordMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Record", @"Record") action:@selector(recordAudioMenuItemAction)];
    UIMenuItem *playMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Play", @"Play") action:@selector(playAudioMenuItemAction)];
    UIMenuItem *stopMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"StopRecord", @"Stop Recording") action:@selector(stopRecord)];
    UIMenuItem *pauseMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Pause", @"Pause") action:@selector(pauseAudio)];
    UIMenuItem *closeMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Close") action:@selector(close:)];
    UIMenuItem *expandMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"More", @"More...") action:@selector(discolsureIndicatorAction:)];

    switch (self.currentState) {
        case AudioStateRecording:{
            [menuItems addObject:stopMenuItem];
        }
            break;
        case AudioStatePlaying:{
            [menuItems addObject:recordMenuItem];
            [menuItems addObject:pauseMenuItem];
        }
            break;
            
        case AudioStateNone:{
            [menuItems addObject:recordMenuItem];
            [menuItems addObject:playMenuItem];
        }
            break;
    }
    [menuItems addObject:closeMenuItem];
    [menuItems addObject:expandMenuItem];
    theMenu.menuItems = menuItems;
}

- (IBAction)closeCompactModeView:(UISwipeGestureRecognizer *)sender {
    if(!self.isExpanded) {
        [UIView animateWithDuration:0.3 animations:^{
            self.view.frame = CGRectOffset(self.view.frame, self.view.frame.size.width, 0);
        } completion:^(BOOL finished) {
            [self close:nil];
        }];
    }
}

#if TARGET_OS_MACCATALYST
- (UIMenu *)getContextMenu {
    NSMutableArray *menuItems = [NSMutableArray array];
    BOOL shouldShowMenu = (self.isExpanded == NO);
    if (shouldShowMenu) {
        __block __weak FTAudioPlayerController *weakSelf = self;
        UIAction *record = [UIAction actionWithTitle:NSLocalizedString(@"Record", @"Record") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf recordAudioMenuItemAction];
        }];

        UIAction *play = [UIAction actionWithTitle:NSLocalizedString(@"Play", @"Play") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf playAudioMenuItemAction];
        }];
        
        UIAction *stopRecord = [UIAction actionWithTitle:NSLocalizedString(@"StopRecord", @"Stop Recording") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf stopRecord];
        }];

        UIAction *pause = [UIAction actionWithTitle:NSLocalizedString(@"Pause", @"Pause") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf pauseAudio];
        }];

        UIAction *close = [UIAction actionWithTitle:NSLocalizedString(@"Close", @"Close") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf close:nil];
        }];

        UIAction *more = [UIAction actionWithTitle:NSLocalizedString(@"More", @"More...") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf discolsureIndicatorAction:nil];
        }];

        switch (self.currentState) {
            case AudioStateRecording:{
                [menuItems addObject:stopRecord];
            }
                break;
            case AudioStatePlaying:{
                [menuItems addObject:record];
                [menuItems addObject:pause];
            }
                break;
                
            case AudioStateNone:{
                [menuItems addObject:record];
                [menuItems addObject:play];
            }
                break;
        }
        [menuItems addObject:close];
        [menuItems addObject:more];
    }
    return [UIMenu menuWithTitle:@"" children:menuItems];
}
#endif

@end
