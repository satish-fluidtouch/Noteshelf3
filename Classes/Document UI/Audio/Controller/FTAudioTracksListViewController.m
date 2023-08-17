//
//  FTAudioTracksListViewController.m
//  Noteshelf
//
//  Created by Chandan on 18/8/15.
//
//

#import "FTAudioTracksListViewController.h"
#import "FTAudioTrackListTableViewCell.h"
#import "FTAudioSessionManager.h"
#import "Noteshelf-Swift.h"

@interface FTAudioTracksListViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *continueRecordingButton;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;

@property (strong, nonatomic) NSString *audioFileName;

@property (nonatomic,assign)BOOL canUpdate;

@end

#define HEADER_BACKGROUND_COLOR @"1b1b1b"
#define AUDIO_TRACK_CELL_ID @"FTAudioTrackListCellID"
#define AUDIO_CELL_ROW_HEIGHT 66

@implementation FTAudioTracksListViewController

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FTAudioTrackListTableViewCell" bundle:nil] forCellReuseIdentifier:AUDIO_TRACK_CELL_ID];
    self.tableView.rowHeight = AUDIO_CELL_ROW_HEIGHT;

    [self.continueRecordingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.continueRecordingButton setTitle:NSLocalizedString(@"ContinueRecording", "Continue Recording") forState:UIControlStateNormal];
    self.continueRecordingButton.layer.cornerRadius = 3.0;
    [self observeAudioSessionNotifications];
    [self updateRecordingButton];
    
    self.canUpdate = YES;
    [self validateExportButton];
    if([self isRegularClass]) {
        self.preferredContentSize = CGSizeMake(330.0, 477.0);
    }
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //Scroll to show the currently playing or recording track.
    if([self.annotation.recordingModel currentAudioSessionState] != AudioStateNone )
    {
        CMTime currentTime = [FTAudioSessionManager sharedSession].activeSession.currentPlaybackTime;
        double currentSeekTime = CMTimeGetSeconds(currentTime);
        
        FTAudioTrackModel *model = [self.annotation.recordingModel modelForDuration:currentSeekTime];
        FTAudioTrackListTableViewCell *cell = nil;
        cell = [self getCellForRecordingModel:model];
        NSIndexPath *indexPathToShow = [self.tableView indexPathForCell:cell];
        if(AudioStateRecording == [FTAudioSessionManager sharedSession].activeSessionState){
            if(!cell){
                indexPathToShow = [NSIndexPath indexPathForRow:self.annotation.recordingModel.audioTracks.count inSection:0];
            }
        }
        [self.tableView scrollToRowAtIndexPath:indexPathToShow atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        
        [(FTAudioTrackListTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPathToShow] updateUI:currentSeekTime state:[FTAudioSessionManager sharedSession].activeSessionState];
    }
}

-(void)validateExportButton
{
    NSInteger count = self.annotation.recordingModel.audioTracks.count;
    self.exportButton.enabled = (count != 0);
    self.exportButton.alpha = (self.exportButton.enabled) ? 1 : 0.5;
}

- (void)observeAudioSessionNotifications
{
    //Since FTAudioPlayerController handling the intruption,no need to handle the same here.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionDidChange:) name:FTAudioSessionEventChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionDidProgress:) name:FTAudioSessionProgressNotification object:nil];
}

- (void)removeAudioSessionNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark notification methods
-(BOOL)isSameWindow:(NSNotification*)notification {
    NSDictionary *userinfo = notification.userInfo;
    NSUInteger windowHash = [[userinfo objectForKey:FTRefreshWindowKey] unsignedIntegerValue];
    NSInteger currentWindowHash = self.view.window.hash;
    
    if(windowHash != currentWindowHash) {
        return false;
    }
    return true;
}

- (void)audioSessionDidChange:(NSNotification *)notification
{
    if(![self isSameWindow:notification]) {
        return;
    }
    NSDictionary *userinfo = notification.userInfo;
    FTAudioSessionEvent state = [[userinfo valueForKey:FTAudioSessionEventNotificationKey] integerValue];
    FTAudioRecordingModel *audioModel = [userinfo valueForKey:FTAudioSessionAudioRecordingNotificationKey];
    NSString *sessionId = audioModel.fileName;
    
    if([self.annotation.recordingModel.fileName isEqualToString:sessionId]){
        if(FTAudioSessionDidStartRecording == state){
            [self.tableView reloadData];
            [self scrollToBottom];
            [self validateExportButton];
        }
        else if( FTAudioSessionDidStopRecording == state){
            [self.tableView reloadData];
            [self validateExportButton];
        }
        else if(state == FTAudioSessionDidFinishPlayback) {
            [self.tableView reloadData];
            [self validateExportButton];
        }
    }

    [self updateCell:notification];
}

- (void)audioSessionDidProgress:(NSNotification *)notification
{
    if(![self isSameWindow:notification]) {
        return;
    }
    if(self.canUpdate){
        [self updateCell:notification];
    }
}

- (void)scrollToBottom
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSInteger row =  [self.tableView numberOfRowsInSection:0];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    });
}

-(void)updateCell:(NSNotification *)notification
{
    NSDictionary *usefInfo = notification.userInfo;
    double currentSeekTime = ceil([usefInfo[FTAudioSessionCurrentTimeNotificationKey] doubleValue]);
    double duration = [self.annotation.recordingModel audioDuration];

    AudioSessionState state = [usefInfo[FTAudioSessionStateNotificationKey] integerValue];
    FTAudioTrackListTableViewCell *cell = nil;
    FTAudioTrackModel *model = [self.annotation.recordingModel modelForDuration:currentSeekTime];
    //When playback paused, we should retain the previous track, because seektime is zero
    if (state == AudioStateNone
        && nil != self.audioFileName) {
        NSUInteger index =  [self.annotation.recordingModel.audioTracks indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            FTAudioTrackModel *audioTrackModel = (FTAudioTrackModel *)obj;
            if ([audioTrackModel.audioFileName isEqualToString:self.audioFileName]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        cell = (FTAudioTrackListTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    }
    else {
        self.audioFileName = model.audioFileName;
        cell = [self getCellForRecordingModel:model];
    }
    
    //If the audio associated with this cell is not the currently playing or recording, then we need not indicate the playing or recording state in the cell.
    BOOL currentlyActive = [self.annotation.recordingModel isAudioConfiguredInSession];
    if(!currentlyActive)
        state = AudioStateNone;

    if(AudioStateRecording == state){
        if(!cell){
            cell= [self getRecordingCell];
        }
        cell.selected = YES;

        [cell updateUI:(currentSeekTime-duration) state:state];
    }
    else if(AudioStatePlaying == state){
        if(cell && !cell.isSelected){
            [self.tableView selectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        [cell updateUI:currentSeekTime state:state];
    }
    else{
        [cell updateUI:cell.model.duration state:state];
    }
    
    [self updateRecordingButton];
}

-(void)updateRecordingButton
{
    if([self.annotation.recordingModel isCurrentAudioRecording]){
        self.continueRecordingButton.enabled = NO;
    }
    else{
        self.continueRecordingButton.enabled = YES;
    }
}

-(FTAudioTrackListTableViewCell*)getCellForRecordingModel:(FTAudioTrackModel*)trackModel
{
    NSUInteger index =  [self.annotation.recordingModel.audioTracks indexOfObject:trackModel];
    FTAudioTrackListTableViewCell *cell = (FTAudioTrackListTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    return cell;
}

-(FTAudioTrackListTableViewCell*)getRecordingCell
{
    FTAudioTrackListTableViewCell *cell = nil;
    NSInteger count = self.annotation.recordingModel.audioTracks.count;
    if([self.annotation.recordingModel isCurrentAudioRecording]){
        cell = (FTAudioTrackListTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:count inSection:0]];
    }
    return cell;
}


#pragma mark - Utility

- (FTAudioTrackModel *)getAudioModelForIndex:(NSInteger)index
{
    FTAudioTrackModel *model = nil;
    FTAudioRecordingModel *recordingModel = self.annotation.recordingModel;
    if(recordingModel.audioTracks.count > index){
        model = [recordingModel.audioTracks objectAtIndex:index];
    }
    return model;
}

- (IBAction)backButtonTapped:(UIButton *)sender
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(didClickOnBackButton:)]){
        [self.delegate didClickOnBackButton:self];
    }
}

-(IBAction)exportButtonAction:(id)sender
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(didClickOnExportButton:)]){
        [self.delegate didClickOnExportButton:self];
        track(@"recording_export_tapped", nil, @"NB_AddNew");
    }
}
#pragma mark - TableView DataSource -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = self.annotation.recordingModel.audioTracks.count;
    if([self.annotation.recordingModel isCurrentAudioRecording]){
        count+=1;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = AUDIO_TRACK_CELL_ID;
    FTAudioTrackListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[FTAudioTrackListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    BOOL isRecording = [self isRecordingAtIndex:indexPath.row];
    FTAudioTrackModel *model = nil;
    if(!isRecording){
        model = [self getAudioModelForIndex:indexPath.row];
    }
    cell.model = model;
    cell.titleLabel.kernValue = -0.32;
    cell.titleLabel.styleText = [NSString stringWithFormat:NSLocalizedString(@"SessionNo", @"session no"),(indexPath.row+1)];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return section == 0 ? CGFLOAT_MIN : 16.0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([self.annotation.recordingModel isCurrentAudioRecording] ? NO : YES);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        FTAudioTrackModel *model =  [self getAudioModelForIndex:indexPath.row];
        
        //Delete the audio session
        [self.annotation removeAudio:model];
        
        //Delete the row
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self validateExportButton];
    }
    
}

#pragma mark - TableView Delegates -



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    track(@"recording_session_tapped", nil, @"NB_AddNew");
    FTAudioTrackModel *model = [self getAudioModelForIndex:indexPath.row];
    if(indexPath.row == self.annotation.recordingModel.audioTracks.count){
        //Current recording index - keep quiet
    }
    else{
        
        self.canUpdate = NO;

        FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
        
        if([self.annotation.recordingModel isCurrentAudioPlaying]
           && nil != self.audioFileName
           && [model.audioFileName isEqual:self.audioFileName]) {
            [session pausePlayback];
        }
        else {
            [self playTrack];
            if(nil == self.audioFileName
               || ![model.audioFileName isEqual:self.audioFileName]) {
                double seekTime = [self.annotation.recordingModel startSeekTimeForTrack:model];
                CMTime time = CMTimeMakeWithSeconds(seekTime, NSEC_PER_SEC);
                [session seekTime:time];
                self.audioFileName = model.audioFileName;
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.canUpdate = YES;
        });

    }
    
}

- (void)playTrack
{
    FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
    BOOL isSamewindow = YES;
    if(session.windowHash != self.view.window.hash) {
        [session resetSession];
        isSamewindow = NO;
    }

    if(AudioStateRecording == session.audioSessionState){
        [session stopRecording];
    }
    
    if(!isSamewindow || ![self.annotation.recordingModel isAudioConfiguredInSession]){
        [self stopAudioSessionProcess];
        [session setAudioRecordingModel:self.annotation.recordingModel forWindow:self.view.window];
    }
    
    [session startPlayback];
}

- (void)stopAudioSessionProcess
{
    FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
    if(AudioStatePlaying == session.audioSessionState){
        [session stopPlayback];
    }
    else if(AudioStateRecording == session.audioSessionState){
        [session stopRecording];
    }
}

- (BOOL)isRecordingAtIndex:(NSInteger)index
{
    BOOL isRecording = NO;
    NSInteger count = self.annotation.recordingModel.audioTracks.count;
    if([self.annotation.recordingModel isCurrentAudioRecording] && count == index){
        isRecording = YES;
    }
    return isRecording;
}

- (IBAction)handleContinueRecordingAction:(id)sender
{
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(didClickOnContinueRecordingButton:)]){
        [self.delegate didClickOnContinueRecordingButton:self];
    }
    [self.tableView reloadData];
    [self validateExportButton];
    track(@"recording_continue_tapped", nil, @"NB_AddNew");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self removeAudioSessionNotifications];
}

@end

