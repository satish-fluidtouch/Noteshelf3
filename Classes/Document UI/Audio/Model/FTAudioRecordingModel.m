//
//  DNAudioModel.m
//  All My Days
//
//  Created by Chethan on 21/10/14.
//
//

#import "FTAudioRecordingModel.h"
#import "FTAudioTrackModel.h"
#import "FTAudioSession.h"
#import "FTAudioSessionManager.h"
#import <AVFoundation/AVFoundation.h>

@interface FTAudioRecordingModel ()
@property(nonatomic,strong) NSMutableArray *audioTracks;
@end


@implementation FTAudioRecordingModel
@synthesize fileName;



#pragma mark- init methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.audioTracks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithFileName:(NSString *)modelFileName
{
    self = [super init];
    if (self) {
         self.fileName  = modelFileName;
        self.audioTracks = [[NSMutableArray alloc] init];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self=[super init];
    if (self) {
        self.fileName = [coder decodeObjectForKey:@"fileName"];
        self.audioTracks = [coder decodeObjectForKey:@"audioTracks"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.fileName forKey:@"fileName"];
    [coder encodeObject:self.audioTracks forKey:@"audioTracks"];
}

#pragma mark- tracks add/remove

-(void)addAudioTrack:(FTAudioTrackModel *)audioTrack
{
    audioTrack.recordingModel = self;
    [self willChangeValueForKey:@"audioTracks"];
    [_audioTracks addObject:audioTrack];
    [self didChangeValueForKey:@"audioTracks"];
}

-(void)removeAudioTrack:(FTAudioTrackModel *)track
{
    [self willChangeValueForKey:@"audioTracks"];
    [_audioTracks removeObject:track];
    [self didChangeValueForKey:@"audioTracks"];
}

#pragma mark- tracks assets

-(NSArray *)tracksAssets
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    [self.audioTracks enumerateObjectsUsingBlock:^(FTAudioTrackModel *audioTrack, NSUInteger idx, BOOL *stop) {
        //If file exist create audio asset.
        if([self isFileExists:audioTrack]){
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:audioTrack.audioFileURL options:nil];
            [items addObject:asset];
        }
    }];
    
    return items;
}

#pragma mark- Tracks

-(NSArray *)audioTracksModel
{
    return  _audioTracks;
}


#pragma mark- Audio duration

-(double)audioDuration
{
    double duration = 0;
    __block double totalDuration = 0;
    [self.audioTracks enumerateObjectsUsingBlock:^(FTAudioTrackModel *audioTrack, NSUInteger idx, BOOL *stop) {
        if([self isFileExists:audioTrack]){
            double startTimeInterval = audioTrack.startTimeInterval;
            double endTimeInterval = audioTrack.endTimeInterval;
            double assetDuration = endTimeInterval - startTimeInterval;
            totalDuration+=assetDuration;
        }
    }];
    duration = totalDuration;
    return ceilf(duration);
}

// This is implemdnted for Content tab, where the Audio annotations will not have any associated PDF page.
- (double)audioDurationWithoutCheckingFileExistance
{
    double duration = 0;
    __block double totalDuration = 0;
    [self.audioTracks enumerateObjectsUsingBlock:^(FTAudioTrackModel *audioTrack, NSUInteger idx, BOOL *stop) {
        double startTimeInterval = audioTrack.startTimeInterval;
        double endTimeInterval = audioTrack.endTimeInterval;
        double assetDuration = endTimeInterval - startTimeInterval;
        totalDuration+=assetDuration;
    }];
    duration = totalDuration;
    return ceilf(duration);
}


-(BOOL)isFileExists:(FTAudioTrackModel *)audioTrack
{
    BOOL isExist = NO;

    if(audioTrack.audioFileURL && [[NSFileManager defaultManager] fileExistsAtPath:audioTrack.audioFileURL.path isDirectory:nil]){
        isExist = YES;
    }
    return isExist;
}

-(FTAudioTrackModel *)modelForDuration:(double)duration
{
    __block FTAudioTrackModel *model = nil;
    __block double totalDuration = 0;
    [self.audioTracks enumerateObjectsUsingBlock:^(FTAudioTrackModel *audioTrack, NSUInteger idx, BOOL *stop) {
        double startTimeInterval = audioTrack.startTimeInterval;
        double endTimeInterval = audioTrack.endTimeInterval;
        double assetDuration = endTimeInterval - startTimeInterval;
        totalDuration +=assetDuration;

        if(duration <= totalDuration){
            model = audioTrack;
            *stop = YES;
        }
    }];
    return model;
}

-(double)startSeekTimeForTrack:(FTAudioTrackModel *)model
{
    __block double startSeekTime = 0;
    [self.audioTracks enumerateObjectsUsingBlock:^(FTAudioTrackModel *audioTrack, NSUInteger idx, BOOL *stop) {
        if(audioTrack == model){
            *stop = YES;
        }
        else{
            double startTimeInterval = audioTrack.startTimeInterval;
            double endTimeInterval = audioTrack.endTimeInterval;
            double assetDuration = endTimeInterval - startTimeInterval;
            startSeekTime += assetDuration;
        }
    }];
    return startSeekTime;
}

-(NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *recordingModel = [[NSMutableDictionary alloc] init];
    
    [recordingModel setObject:self.fileName forKey:@"fileName"];
    
    NSMutableArray *tracks = [[NSMutableArray alloc] init];
    [self.audioTracks enumerateObjectsUsingBlock:^(FTAudioTrackModel *model, NSUInteger idx, BOOL *stop) {
        [tracks addObject:[model dictionaryRepresentation]];
    }];
    
    [recordingModel setObject:tracks forKey:@"audioTracks"];
    
    return recordingModel;
}

-(id)initWithDict:(NSDictionary *)dict
{
    self = [super init];
   
    if(self){
        self.fileName  = dict[@"fileName"];
        self.audioTracks = [[NSMutableArray alloc] init];

        NSArray *tracks =dict[@"audioTracks"];
        [tracks enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop) {
            FTAudioTrackModel *model = [FTAudioTrackModel  audioTrackModelForDictionary:dict];
            [self addAudioTrack:model];
        }];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    FTAudioRecordingModel *recordingModel = [[[self class] allocWithZone:zone] init];
    if(recordingModel)
    {
        NSMutableArray *audioTracks = [NSMutableArray array];
        [_audioTracks enumerateObjectsUsingBlock:^(FTAudioTrackModel *trackModel, NSUInteger idx, BOOL *stop) {
            FTAudioTrackModel *model = [trackModel copy];
            model.recordingModel = recordingModel;
            [audioTracks addObject:model];
        }];
        recordingModel.audioTracks = audioTracks;
    }
    return recordingModel;
}

-(AudioSessionState)currentAudioSessionState
{
    AudioSessionState state  = AudioStateNone;
    if([self isAudioConfiguredInSession]){
        FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
        state = session.audioSessionState;
    }
    return state;
}

- (BOOL)isAudioConfiguredInSession
{
    BOOL current = NO;
    FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
    NSString *sessionID = session.sessionID;
    if([sessionID isEqualToString:self.fileName]){
        current = YES;
    }
    return current;
}

- (BOOL)isCurrentAudioPlaying
{
    BOOL isPlaying = NO;
    
    if([self isAudioConfiguredInSession]){
        FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
        if(AudioStatePlaying == session.audioSessionState){
            isPlaying = YES;
        }
    }
    return isPlaying;
}

- (BOOL)isCurrentAudioRecording
{
    BOOL isRecording = NO;
    
    if([self isAudioConfiguredInSession]){
        FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
        if(AudioStateRecording == session.audioSessionState){
            isRecording = YES;
        }
    }
    return isRecording;
}

-(void)combineTracksOnUpdate:(void(^)(float progress))updateBlock
                onCompletion:(void(^)(NSURL *fileURL,NSError *error))completionBlock
{
    NSString *tempDirectory = NSTemporaryDirectory();
    
    NSArray *tracks = self.tracksAssets;
    if (tracks.count == 0)
    {
        completionBlock(nil,[NSError errorWithDomain:@"Audio Export" code:1001 userInfo:nil]);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        AVMutableComposition *composition = [AVMutableComposition composition];
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        float totalCount = tracks.count;
        float counter = 0;
    
        __block double assetDuration = 0;
        for (AVURLAsset *eachAudio in tracks)
        {
            AVAssetTrack * audioTrack = [[eachAudio tracksWithMediaType:AVMediaTypeAudio] firstObject];
            if(nil != audioTrack) {
                [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, eachAudio.duration) ofTrack:audioTrack atTime:CMTimeMakeWithSeconds(assetDuration,NSEC_PER_SEC) error:nil];
                assetDuration+=CMTimeGetSeconds(eachAudio.duration);
            }
            counter++;
            dispatch_async(dispatch_get_main_queue(), ^{
                updateBlock(counter/totalCount);
            });
        }

        AVAssetExportSession *exportSession = [AVAssetExportSession
                                               exportSessionWithAsset:composition
                                               presetName:AVAssetExportPresetAppleM4A];
        if (nil == exportSession)
        {
            completionBlock(nil,[NSError errorWithDomain:@"Audio Export" code:1001 userInfo:nil]);
            return;
        }
        
        NSString *soundOneNew = [tempDirectory stringByAppendingPathComponent:@"noteshelf_recording.m4a"];
        [[NSFileManager defaultManager] removeItemAtPath:soundOneNew error:nil];
        //NSLog(@"Output file path - %@",soundOneNew);
        
        // configure export session  output with all our parameters
        exportSession.outputURL = [NSURL fileURLWithPath:soundOneNew]; // output path
        exportSession.outputFileType = AVFileTypeAppleM4A; // output file type
        
        // perform the export
        [exportSession exportAsynchronouslyWithCompletionHandler:^
         {
             if (AVAssetExportSessionStatusCompleted == exportSession.status)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     updateBlock(1.0f);
                     completionBlock([NSURL fileURLWithPath:soundOneNew],nil);
                 });
             }
             else if (AVAssetExportSessionStatusFailed == exportSession.status)
             {
                 // a failure may happen because of an event out of your control
                 // for example, an interruption like a phone call comming in
                 // make sure and handle this case appropriately
                 dispatch_async(dispatch_get_main_queue(), ^{
                     completionBlock(nil,exportSession.error);
                 });
             }
         }];
    });
}

@end
