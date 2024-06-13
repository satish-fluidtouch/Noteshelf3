//
//  NSObject+FTAudioDataProcessor.h
//  Noteshelf3
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

@protocol FTVisualizationDataProtocol, FTVisualizationTarget;
@class FTVisualizationSettings;

@interface FTAudioDataProcessor: NSObject<FTVisualizationDataProtocol>
+ (instancetype) alloc __attribute__((unavailable("alloc not available, call manager instead")));
- (instancetype) init __attribute__((unavailable("init not available, call manager instead")));
+ (instancetype) new __attribute__((unavailable("new not available, call manager instead")));

@property (nonatomic, weak) id<FTVisualizationTarget> target;
@property (nonatomic) NSInteger numOfBins;
@property (nonatomic, strong) AVAudioNode *audioTapNode;
@property (strong, nonatomic) AVAudioEngine *engine;

+ (instancetype) serviceWith : (FTVisualizationSettings*) audioSettings;
- (float*) frequencyHeights;
- (NSMutableArray*) timeHeights;

- (void) updateBuffer: (float *)buffer
       withBufferSize: (UInt32)bufferSize;

- (void)startProcessingAudioData:(BOOL)isToResume;
- (void)stopProcessingAudioData;

@end
