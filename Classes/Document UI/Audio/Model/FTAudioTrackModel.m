//
//  FTAudioTrackModel.m
//  All My Days
//
//  Created by Chethan on 28/11/14.
//
//

#import "FTAudioTrackModel.h"
#import "FTAudioRecordingModel.h"
#import "Noteshelf-Swift.h"

@import FTCommon;

@interface FTAudioTrackModel ()

@property (nonatomic,strong) NSString *audioFileName;

@end

@implementation FTAudioTrackModel

@synthesize audioFileName,startTimeInterval,endTimeInterval;
@synthesize recordingModel;

- (nonnull instancetype)initWithFilePath:(NSString*)path {
    self = [super init];
    if (self) {
        self.audioFileName = [FTUtils getNewAudioTrackName:path.pathExtension];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.audioFileName = [FTUtils getNewAudioTrackName:@"m4a"];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self) {
        self.audioFileName = [coder decodeObjectForKey:@"audioName"];
        self.startTimeInterval = [coder decodeDoubleForKey:@"startTimeInterval"];
        self.endTimeInterval = [coder decodeDoubleForKey:@"endTimeInterval"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.audioFileName forKey:@"audioName"];
    [coder encodeDouble:self.startTimeInterval forKey:@"startTimeInterval"];
    [coder encodeDouble:self.endTimeInterval forKey:@"endTimeInterval"];
}

- (NSDictionary *)dictionaryRepresentation
{
    NSDictionary *dict = @{
                           @"audioName":self.audioFileName,
                           @"startTimeInterval":[NSNumber numberWithDouble:self.startTimeInterval],
                           @"endTimeInterval":[NSNumber numberWithDouble:self.endTimeInterval],
                           };
    return dict;
}

+ (FTAudioTrackModel *)audioTrackModelForDictionary:(NSDictionary *)dict
{
    FTAudioTrackModel *model = [[FTAudioTrackModel alloc] init];
    
    model.audioFileName = [dict objectForKey:@"audioName"];
    model.startTimeInterval = [[dict objectForKey:@"startTimeInterval"] doubleValue];
    model.endTimeInterval = [[dict objectForKey:@"endTimeInterval"] doubleValue];
    
    return model;
}

-(double)duration
{
    double trackDuration = self.endTimeInterval - self.startTimeInterval;
    return trackDuration;
}

- (id)copyWithZone:(NSZone *)zone
{
    FTAudioTrackModel *trackModel = [[[self class] allocWithZone:zone] init];
    if(trackModel)
    {
        trackModel.audioFileName = [FTUtils getNewAudioTrackName:self.audioFileName.pathExtension];
        trackModel.startTimeInterval = self.startTimeInterval;
        trackModel.endTimeInterval = self.endTimeInterval;
    }
    return trackModel;
}

-(NSURL*)audioFileURL
{
    return [self.recordingModel.representedObject audioFileURL:self.audioFileName];
}
@end
