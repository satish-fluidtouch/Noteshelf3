//
//  DNAudioControllerManager.h
//  All My Days
//
//  Created by Chethan on 21/10/14.
//
//

#import <Foundation/Foundation.h>
#import "FTAudioUtils.h"

@class FTAudioSession;

@interface FTAudioSessionManager : NSObject

+ (instancetype)sharedSession;

-(FTAudioSession *)activeSession;
-(AudioSessionState)activeSessionState;

@end

