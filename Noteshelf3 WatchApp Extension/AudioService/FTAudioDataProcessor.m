//
//  FTAudioDataProcessor.m
//  NS2Watch Extension
//
//  Created by Simhachalam on 09/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTAudioDataProcessor.h"
#import "Noteshelf3_WatchApp_Extension-Swift.h"
#import <Accelerate/Accelerate.h>

const UInt32 kMaxFrames = 4096;

const Float32 kAdjust0DB = 1.5849e-13;

const NSInteger kFrameInterval = 1; // Alter this to draw more or less often

const NSInteger kFramesPerSecond = 20; // Alter this to draw more or less often

@interface FTAudioDataProcessor () {
    FFTSetup fftSetup;
    
    COMPLEX_SPLIT complexSplit;
    
    int log2n, n, nOver2;
    
    float sampleRate;
    
    size_t bufferCapacity, index;
    
    // buffers
    float *speeds, *times, *tSqrts, *vts, *deltaHeights, *dataBuffer, *heightsByFrequency;
}

//@property (strong, nonatomic) CADisplayLink *displaylink;

@property (strong, nonatomic) FTVisualizationSettings *settings;
@property (strong, nonatomic) NSMutableArray *heightsByTime;

//Audio Engine
@property (nonatomic, strong) NSTimer *updateTimer;
@property (assign, nonatomic) FTVisualizerPlotType plotType;

@end

@implementation FTAudioDataProcessor

+ (instancetype) serviceWith : (FTVisualizationSettings*) audioSettings
{
    FTAudioDataProcessor *sharedService= [[super alloc] initUniqueInstanceWith: audioSettings];
    return sharedService;
}

- (instancetype) initUniqueInstanceWith : (FTVisualizationSettings*) audioSettings
{
    if (self = [super init])
    {
        self.settings = audioSettings;
        [self setNumOfBins: audioSettings.numOfBins];
        self.plotType = FTVisualizerPlotTypeBuffer;
        [self setup];
    }
    return self;
}

- (void)setup {
    //Configure Data buffer and setup FFT
    dataBuffer = (float *)malloc(kMaxFrames * sizeof(float));
    
    log2n = log2f(kMaxFrames);
    n = 1 << log2n;
    assert(n == kMaxFrames);
    
    nOver2 = kMaxFrames / 2;
    bufferCapacity = kMaxFrames;
    index = 0;
    
    complexSplit.realp = (float *)malloc(nOver2 * sizeof(float));
    complexSplit.imagp = (float *)malloc(nOver2 * sizeof(float));
    
    fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    
    //Create and configure audio session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    sampleRate = audioSession.sampleRate;
    
}

- (float*) frequencyHeights {
    return heightsByFrequency;
}

- (NSMutableArray*) timeHeights {
    return self.heightsByTime;
}

- (void)dealloc {
    [self freeBuffersIfNeeded];
}

#pragma mark - Properties

- (void) setNumOfBins:(NSInteger) binsNumber {
    
    //Set new value for numOfBins property
    _numOfBins = MAX(1, binsNumber);
    self.settings.numOfBins = binsNumber;
    
    [self freeBuffersIfNeeded];
    
    //Create buffers
    heightsByFrequency = (float *)calloc(sizeof(float), self.numOfBins);
    speeds = (float *)calloc(sizeof(float), self.numOfBins);
    times = (float *)calloc(sizeof(float), self.numOfBins);
    tSqrts = (float *)calloc(sizeof(float), self.numOfBins);
    vts = (float *)calloc(sizeof(float), self.numOfBins);
    deltaHeights = (float *)calloc(sizeof(float), self.numOfBins);
    
    //Create Heights by time array
    self.heightsByTime = [NSMutableArray arrayWithCapacity: self.numOfBins];
    for (int i = 0; i < self.numOfBins; i++) {
        self.heightsByTime[i] = [NSNumber numberWithFloat:0];
    }
}

- (void)startProcessingAudioData:(BOOL)isToResume{
    
    if(!self.engine){
        self.engine = [[AVAudioEngine alloc] init];
    }
    if(self.audioTapNode == nil){
        self.audioTapNode = self.engine.inputNode;
    }
    if(!isToResume){
        [self.audioTapNode installTapOnBus:0 bufferSize:4096 format:[self.audioTapNode outputFormatForBus:0] block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
            if(buffer){
                [self updateBuffer:*buffer.floatChannelData withBufferSize:4096];
                //NSLog(@"buffer.frameLength:: %d", buffer.frameLength);
            }
        }];
    }
    if(!self.engine.isRunning){
        [self.engine startAndReturnError:nil];
    }
    if(self.updateTimer){
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateHeights) userInfo:nil repeats:true];
    
    if([self.target respondsToSelector:@selector(didStartProcessingData)]){
        [self.target didStartProcessingData];
    }
}
- (void)stopProcessingAudioData{
    [self.engine pause];
    if(self.updateTimer){
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
    if([self.target respondsToSelector:@selector(didStopProcessingData)]){
        [self.target didStopProcessingData];
    }
}

#pragma mark - Timer Callback
- (void)updateHeights {
    
    //Delay from last frame
    float delay = 0.1;
    
    // increment time
    vDSP_vsadd(times, 1, &delay, times, 1, self.numOfBins);
    
    // clamp time
    static const float timeMin = 1.5, timeMax = 10;
    vDSP_vclip(times, 1, &timeMin, &timeMax, times, 1, self.numOfBins);
    
    // increment speed
    float g = self.settings.gravity * delay;
    vDSP_vsma(times, 1, &g, speeds, 1, speeds, 1, self.numOfBins);
    
    // increment height
    vDSP_vsq(times, 1, tSqrts, 1, self.numOfBins);
    vDSP_vmul(speeds, 1, times, 1, vts, 1, self.numOfBins);
    float aOver2 = g / 2;
    vDSP_vsma(tSqrts, 1, &aOver2, vts, 1, deltaHeights, 1, self.numOfBins);
    vDSP_vneg(deltaHeights, 1, deltaHeights, 1, self.numOfBins);
    vDSP_vadd(heightsByFrequency, 1, deltaHeights, 1, heightsByFrequency, 1, self.numOfBins);

    if([self.target respondsToSelector:@selector(updateVisualizerWithData:)]){
        [self.target updateVisualizerWithData:self];
    }
}

#pragma mark - Update Buffers
- (void)setSampleData:(float *)data length:(int)length {
    // fill the buffer with our sampled data. If we fill our buffer, run the FFT
    int inNumberFrames = length;
    int read = (int)(bufferCapacity - index);
    
    if (read > inNumberFrames) {
        memcpy((float *)dataBuffer + index, data, inNumberFrames * sizeof(float));
        index += inNumberFrames;
    } else {
        // if we enter this conditional, our buffer will be filled and we should perform the FFT
        memcpy((float *)dataBuffer + index, data, read * sizeof(float));
        
        // reset the index.
        index = 0;
        
        vDSP_ctoz((COMPLEX *)dataBuffer, 2, &complexSplit, 1, nOver2);
        vDSP_fft_zrip(fftSetup, &complexSplit, 1, log2n, FFT_FORWARD);
        vDSP_ztoc(&complexSplit, 1, (COMPLEX *)dataBuffer, 2, nOver2);
        
        // convert to dB
        Float32 one = 1, zero = 0;
        vDSP_vsq(dataBuffer, 1, dataBuffer, 1, inNumberFrames);
        vDSP_vsadd(dataBuffer, 1, &kAdjust0DB, dataBuffer, 1, inNumberFrames);
        vDSP_vdbcon(dataBuffer, 1, &one, dataBuffer, 1, inNumberFrames, 0);
        vDSP_vthr(dataBuffer, 1, &zero, dataBuffer, 1, inNumberFrames);
        
        // aux
        float mul = (sampleRate / bufferCapacity) / 2;
        int minFrequencyIndex = self.settings.minFrequency / mul;
        int maxFrequencyIndex = self.settings.maxFrequency / mul;
        int numDataPointsPerColumn =
        (maxFrequencyIndex - minFrequencyIndex) / self.numOfBins;
        float maxHeight = 0;
        
        for (NSUInteger i = 0; i < self.numOfBins; i++) {
            // calculate new column height
            float avg = 0;
            vDSP_meanv(dataBuffer + minFrequencyIndex +
                       i * numDataPointsPerColumn,
                       1, &avg, numDataPointsPerColumn);
            
            
            CGFloat columnHeight = MIN(avg * self.settings.gain, self.settings.maxBinHeight);
            
            maxHeight = MAX(maxHeight, columnHeight);
            // set column height, speed and time if needed
            if (columnHeight > heightsByFrequency[i]) {
                heightsByFrequency[i] = columnHeight;
                speeds[i] = 0;
                times[i] = 0;
            }
        }
        
        [self.heightsByTime addObject: [NSNumber numberWithFloat:maxHeight]];
        
        if (self.heightsByTime.count > self.numOfBins) {
            [self.heightsByTime removeObjectAtIndex:0];
        }
    }
}

- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize {
    #if TARGET_IPHONE_SIMULATOR
    
    #else
        [self setSampleData:buffer length:bufferSize];
    #endif
}


- (void)freeBuffersIfNeeded {
    if (heightsByFrequency) {
        free(heightsByFrequency);
    }
    if (speeds) {
        free(speeds);
    }
    if (times) {
        free(times);
    }
    if (tSqrts) {
        free(tSqrts);
    }
    if (vts) {
        free(vts);
    }
    if (deltaHeights) {
        free(deltaHeights);
    }
}

@synthesize currentFrequencyHeights;

@synthesize currentTimeHeights;

@synthesize numberOfBins;

@end
