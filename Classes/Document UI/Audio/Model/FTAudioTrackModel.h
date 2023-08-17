//
//  FTAudioTrackModel.h
//  All My Days
//
//  Created by Chethan on 28/11/14.
//
//

#import <Foundation/Foundation.h>

@class FTAudioRecordingModel;

@interface FTAudioTrackModel : NSObject

@property (nonatomic,assign) double startTimeInterval;
@property (nonatomic,assign) double endTimeInterval;
@property (nonatomic,strong,readonly) NSString *audioFileName;

@property (weak) FTAudioRecordingModel *recordingModel;
- (nonnull instancetype)initWithFilePath:(NSString*)path;
+ (FTAudioTrackModel *)audioTrackModelForDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;
- (double)duration;
- (NSURL*)audioFileURL;
@end
