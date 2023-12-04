//
//  DNAudioModel.h
//  All My Days
//
//  Created by Chethan on 21/10/14.
//
//

#import <Foundation/Foundation.h>
#import "FTAudioUtils.h"

@class FTAudioRecordingModel, FTAudioTrackModel, FTAudioAnnotation;

@interface FTAudioRecordingModel : NSObject

@property(nonatomic,strong) NSString *fileName;
@property(nonatomic,weak) id<FTAudioAnnotationProtocol> representedObject;

- (id)initWithFileName:(NSString *)modelFileName;
- (id)initWithDict:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (void)addAudioTrack:(FTAudioTrackModel *)track;
- (void)removeAudioTrack:(FTAudioTrackModel *)track;
- (NSArray *)audioTracks;

//Returns array of AVURLAsset for playback.
- (NSArray *)tracksAssets;

- (double)audioDuration;
- (double)audioDurationWithoutCheckingFileExistance;
- (FTAudioTrackModel *)modelForDuration:(double)duration;

- (double)startSeekTimeForTrack:(FTAudioTrackModel *)model;

- (BOOL)isCurrentAudioRecording;
- (BOOL)isCurrentAudioPlaying;
- (BOOL)isAudioConfiguredInSession;
- (AudioSessionState)currentAudioSessionState;
-(void)combineTracksFor: (FTAudioAnnotation *) audioItem
            updateBlock: (void(^)(float progress))updateBlock
           onCompletion: (void(^)(NSURL *fileURL,NSError *error))completionBlock;

@end
