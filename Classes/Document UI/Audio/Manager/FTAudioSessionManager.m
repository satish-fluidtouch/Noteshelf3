//
//  DNAudioControllerManager.m
//  All My Days
//
//  Created by Chethan on 21/10/14.
//
//

#import "FTAudioSessionManager.h"
#import "FTAudioSession.h"

static FTAudioSession *activeSession = nil;

@implementation FTAudioSessionManager

#pragma mark - Lifecycle

+ (instancetype)sharedSession
{
    static FTAudioSessionManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

-(FTAudioSession *)activeSession
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        activeSession = [[FTAudioSession alloc] init];
    });
    return activeSession;
}

-(AudioSessionState)activeSessionState
{
    return self.activeSession.audioSessionState;
}
@end
