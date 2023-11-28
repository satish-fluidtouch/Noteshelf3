//
//  FTAudioListViewController.m
//  Noteshelf
//
//  Created by Chandan on 17/8/15.
//
//

#import "FTAudioListViewController.h"
#import "FTAudioListTableViewCell.h"
#import "FTAudioTracksListViewController.h"
#import "FTAudioSession.h"
#import "FTAudioSessionManager.h"
#import "Noteshelf-Swift.h"

CGFloat importWatchRecordingsHeight = 94.0f;
CGFloat audioRecordSize = 56;

@interface FTAudioListViewController () <UITableViewDataSource,UITableViewDelegate,UIPopoverPresentationControllerDelegate,FTWatchRecordedListViewControllerDelegate>

@property (weak, nonatomic) IBOutlet FTStyledLabel *audioBadgeLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet FTStyledLabel *emptyStateLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *audioBadgeLabelCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *importWatchRecordingsHeightConstraint;

@property (strong,nonatomic)NSMutableArray *audioAnnotations;
@property (weak, nonatomic) IBOutlet UIImageView *tableViewBgImageView;

@property (weak) UIViewController *presentedOnViewController;

@end

#define AUDIO_CELL_ID @"FTAudioListCellID"
#define AUDIO_CELL_ROW_HEIGHT 66

@implementation FTAudioListViewController

-(void)awakeFromNib {
    [super awakeFromNib];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.audioBadgeLabel.layer.cornerRadius = self.audioBadgeLabel.frame.size.height/2.0;
    self.audioBadgeLabel.layer.masksToBounds = YES;
    
    if(self.dataSource && [self.dataSource respondsToSelector:@selector(audioAnnotationsForController:)]){
        self.audioAnnotations = [NSMutableArray arrayWithArray:[self.dataSource audioAnnotationsForController:self]];
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FTAudioListTableViewCell" bundle:nil] forCellReuseIdentifier:AUDIO_CELL_ID];
    self.tableView.rowHeight = AUDIO_CELL_ROW_HEIGHT;

    self.tableViewBgImageView.backgroundColor = [UIColor colorNamed:@"shadowTintColor"];
    //[UIColor colorWithHexString:@"a0a0a0"];
//    self.tableViewBgImageView.alpha = 0.2;
    
    [self observeAudioSessionNotifications];
    
    //Show empty state message
    self.emptyStateLabel.style = FTLabelStyleDefaultStyle;
    self.emptyStateLabel.styleText = NSLocalizedString(@"AudioPopoverEmptyMessage", @"No audio recordings in this notebook.");
    self.emptyStateLabel.hidden = !(self.audioAnnotations.count == 0);
    
    if([self isRegularClass]) {
        self.preferredContentSize = CGSizeMake(320.0, 477.0);
    }
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

    self.audioBadgeLabel.hidden = true;
    self.audioBadgeLabelCenterXConstraint.constant = 0;
    self.importWatchRecordingsHeightConstraint.constant = 0;

    if([[NSUbiquitousKeyValueStore defaultStore] isWatchAppInstalled]) {
        self.importWatchRecordingsHeightConstraint.constant = importWatchRecordingsHeight;
    }
    
    [self.view layoutIfNeeded];

}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if([FTAudioSessionManager sharedSession].activeSessionState == AudioStateNone)
    {
        [self scrollToShowCurrentPageAudioAnnotations];
    }
    else
    {
        FTAudioRecordingModel *model = [FTAudioSessionManager sharedSession].activeSession.audioRecording;
        FTAudioAnnotation *audioAnnotation = [self getAnnotationForAudioRecordingModel:model];

        [self scrollToShowAudioAnnotation:audioAnnotation];
    }
    [self reloadAudioAnnotations];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"showTrackList"] && sender != nil) {
        FTAudioTracksListViewController *controller = (FTAudioTracksListViewController *)segue.destinationViewController;
        controller.delegate = self;
        controller.annotation = (FTAudioAnnotation *)sender;
    }
}

-(void)reloadAudioAnnotations
{
    if(self.dataSource && [self.dataSource respondsToSelector:@selector(audioAnnotationsForController:)]){
        self.audioAnnotations = [NSMutableArray arrayWithArray:[self.dataSource audioAnnotationsForController:self]];
    }
    [self.tableView reloadData];
}

-(void)scrollToShowAudioAnnotation:(FTAnnotation*)annotation
{
    NSUInteger index = [self.audioAnnotations indexOfObject:annotation];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];

}

-(void)scrollToShowCurrentPageAudioAnnotations
{
    id currentlyVisiblePage = [self.dataSource currentlyVisiblePage];
    __block NSUInteger currentPageAudioIndex = -1;
    [self.audioAnnotations enumerateObjectsUsingBlock:^(FTAudioAnnotation *audioAnnotation, NSUInteger idx, BOOL *stop) {
        id<FTPageProtocol> page = (id<FTPageProtocol>)audioAnnotation.associatedPage;
        if([[page uuid] isEqual:[currentlyVisiblePage uuid]])
        {
            *stop = YES;
            currentPageAudioIndex = idx;
        }
            
    }];
    if(currentPageAudioIndex != -1)
    {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:currentPageAudioIndex inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}
#pragma mark - FTAudioSession notifications

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
    if(![self isSameWindow:notification]){
        return;;
    }
    [self updateCell:notification];
}

- (void)audioSessionDidProgress:(NSNotification *)notification
{
    if(![self isSameWindow:notification]){
        return;;
    }
    [self updateCell:notification];
}

-(void)updateCell:(NSNotification *)notification
{
    NSDictionary *usefInfo = notification.userInfo;
    FTAudioRecordingModel *model = usefInfo[FTAudioSessionAudioRecordingNotificationKey];
    double currentSeekTime = ceil([usefInfo[FTAudioSessionCurrentTimeNotificationKey] doubleValue]);
    
    FTAudioAnnotation *audioAnnotation = [self getAnnotationForAudioRecordingModel:model];
    if(audioAnnotation){
        AudioSessionState state = [usefInfo[FTAudioSessionStateNotificationKey] integerValue];
        FTAudioListTableViewCell *cell= (FTAudioListTableViewCell*)[self getCellForAnnotation:audioAnnotation];
        if(AudioStateRecording == state){
            [cell updateUI:currentSeekTime state:state];
        }
        else if(AudioStatePlaying == state){
            [cell updateUI:currentSeekTime state:state];
        }
        else{
            currentSeekTime = audioAnnotation.recordingModel.audioDuration;
            [cell updateUI:currentSeekTime state:state];
        }
    }
}

-(FTAudioAnnotation*)getAnnotationForAudioRecordingModel:(FTAudioRecordingModel*)model
{
    __block FTAudioAnnotation *annotation = nil;
    [self.audioAnnotations enumerateObjectsUsingBlock:^(FTAudioAnnotation *obj, NSUInteger idx, BOOL *stop) {
        if([obj.recordingModel.fileName isEqualToString:model.fileName]){
            annotation = obj;
            *stop = YES;
        }
    }];
    return annotation;
}

-(UITableViewCell*)getCellForAnnotation:(FTAudioAnnotation*)annotation
{
    UITableViewCell *cell = nil;
    NSInteger rowIndex = [self.audioAnnotations indexOfObject:annotation];
    if(rowIndex >=0 && rowIndex < self.audioAnnotations.count){
        NSIndexPath *path = [NSIndexPath indexPathForRow:rowIndex inSection:0];
        cell = [self.tableView cellForRowAtIndexPath:path];
    }
    return cell;
}

- (void)dealloc
{
    [self removeAudioSessionNotifications];
}

#pragma mark - TableView DataSource -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.audioAnnotations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = AUDIO_CELL_ID;
    FTAudioListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[FTAudioListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    FTAudioAnnotation *annotation = [self.audioAnnotations objectAtIndex:indexPath.row];
    cell.annotation = annotation;
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return section == 0 ? CGFLOAT_MIN : 16.0;
}

-(void)createAudioTrackListViewController:(FTAudioAnnotation*)annotation
{
    [self performSegueWithIdentifier:@"showTrackList" sender:annotation];
}

-(void)showAudioTrackList:(FTAudioAnnotation*)annotation
{
    [self createAudioTrackListViewController:annotation];
}

-(void)didClickOnBackButton:(FTAudioTracksListViewController*)controller
{
    [self.navigationController popViewControllerAnimated:YES];
    [self reloadAudioAnnotations];
}

-(void)didClickOnExportButton:(FTAudioTracksListViewController*)controller
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(didClickOnExportButton:controller:)]){
        [self.delegate didClickOnExportButton:controller.annotation controller:self];
    }
}

-(void)didClickOnContinueRecordingButton:(FTAudioTracksListViewController*)controller
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
    if(AudioStatePlaying == session.audioSessionState){
        [session stopPlayback];
    }
    if(!isSamewindow || ![controller.annotation.recordingModel isAudioConfiguredInSession]){
        [self stopAudioSessionProcess];
        [session setAudioRecordingModel:controller.annotation.recordingModel forWindow:controller.view.window];
    }
    __block __weak FTAudioListViewController *weakSelf = self;
    [FTPermissionManager isMicrophoneAvailableOnViewController:self onCompletion:^(BOOL success) {
        if(success) {
            [session startRecording];
            [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

-(void)handleInfoButtonAction:(NSIndexPath *)indexPath
{
    FTAudioAnnotation *annotation = [self.audioAnnotations objectAtIndex:indexPath.row];
    [self showAudioTrackList:annotation];
}

#pragma mark - TableView cell delegates -

-(void)playPauseButtonAction:(id)sender {
    FTAudioListTableViewCell *selectedcell = (FTAudioListTableViewCell *)sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:selectedcell];
    FTAudioAnnotation *annotation = [self.audioAnnotations objectAtIndex:indexPath.row];
    if(![annotation.recordingModel isCurrentAudioRecording]){
        FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
        BOOL isSamewindow = YES;
        if(session.windowHash != self.view.window.hash) {
            [session resetSession];
            isSamewindow = NO;
        }
        if ([annotation.recordingModel isCurrentAudioPlaying]) {
            [session pausePlayback];
        } else {
            track(@"audiorecs_playbutton_tapped", nil, @"NB_AddNew");
            if(AudioStateRecording == session.audioSessionState){
                [session stopRecording];
            }
            if(!isSamewindow || ![annotation.recordingModel isAudioConfiguredInSession]){
                [self stopAudioSessionProcess];
                [session setAudioRecordingModel:annotation.recordingModel forWindow:self.view.window];
            }
            [session startPlayback];
        }
    }
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


#pragma mark - TableView Delegates -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self handleInfoButtonAction:indexPath];
    track(@"audiorecs_recording_tapped", nil, @"NB_AddNew");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        FTAudioAnnotation *annotation = [self.audioAnnotations objectAtIndex:indexPath.row];
        
        //Delete the audio annoatation
        [self.audioAnnotations removeObject:annotation];
        [[NSNotificationCenter defaultCenter] postNotificationName:FTAudioSessionAskedToRemovePlayerNotification object:annotation.recordingModel userInfo:nil];
        [self.delegate didDeleteAnnotation:annotation controller:self];
        //Delete the row
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    self.emptyStateLabel.hidden = !(self.audioAnnotations.count == 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addNewRecordingButtonAction:(id)sender
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(didClickOnAddNewRecording:)]){
        [self.delegate didClickOnAddNewRecording:self];
        track(@"audiorecs_addnew_tapped", nil, @"NB_AddNew");
    }
}
- (IBAction)importWatchRecordingsClicked:(id)sender
{
//    [FTWatchRecordedListViewController pushToRecordingsWithDelegate:self
//                                                     fromSourceView:sender
//                                                   onViewController:self
//                                                            context:FTAudioActionContextInsideNotebook];
}

#pragma mark show/dismiss popover
-(void)showPopoverOnViewController:(UIViewController*)controller fromRect:(CGRect)rect onView:(UIView*)view
{
    UIPopoverPresentationController *popoverPresenter = self.popoverPresentationController;
    popoverPresenter.sourceRect = rect;
    popoverPresenter.sourceView = view;
    popoverPresenter.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popoverPresenter.delegate = self;
    //        popoverPresenter.overrideTraitCollection = controller.traitCollection;
    self.presentedOnViewController = controller;
    [controller presentViewController:self animated:YES completion:nil];
}

-(void)dismissControllerAnimated:(BOOL)animate completion:(void (^)(void))completionBlock
{
    [self.presentedOnViewController dismissViewControllerAnimated:animate completion:completionBlock];
}

#pragma mark- FTWatchRecordedListViewControllerDelegate
-(void)recordingViewController:(FTWatchRecordedListViewController *)recordingsViewController didSelectRecording:(FTWatchRecordedAudio *)recordedAudio forAction:(enum FTAudioActionType)actionType{
    [self.delegate recordingViewController:recordingsViewController didSelectRecording:recordedAudio forAction:actionType];
}
@end
