//
//  FTAudioListTableViewCell.m
//  Noteshelf
//
//  Created by Chandan on 17/8/15.
//
//

#import "FTAudioListTableViewCell.h"
#import "Noteshelf-Swift.h"

#define AUDIO_RED_COLOR [UIColor colorNamed:@"buttonTitleColorDestructive"]
#define AUDIO_GRAY_COLOR [UIColor colorNamed:@"lightTitleColor_50"]
#define AUDIO_AQUA_COLOR [UIColor colorNamed:@"blueDodger"]

@interface FTAudioListTableViewCell()

@property (weak, nonatomic) IBOutlet FTStyledLabel *durationLabel;
@property (weak, nonatomic) IBOutlet FTStyledLabel *creationDate;

@end

@implementation FTAudioListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.backgroundColor = [UIColor clearColor];
    self.creationDate.style = FTLabelStyleStyle5;
    
    self.durationLabel.textColor = [UIColor colorNamed:@"headerColor"];
    self.creationDate.textColor = AUDIO_GRAY_COLOR;
    
    [self setDuration:0];
}

-(void)setAnnotation:(FTAudioAnnotation *)annotation
{
    _annotation = annotation;
    [self updateUI:annotation.recordingModel.audioDuration state:[_annotation.recordingModel currentAudioSessionState]];
}


-(void)setDuration:(CGFloat)duration
{
    NSString *timeString = [FTUtils timeFormatted:duration];
    id<FTPageProtocol> page =  _annotation.associatedPage;
    NSInteger pageNumber = [page pageIndex];
    self.durationLabel.styleText = [NSString stringWithFormat:@"%@ · %@. %ld",timeString, @"p", (long)pageNumber+1];
}

-(void)updateUI:(CGFloat)duration state:(AudioSessionState)state
{
    if(duration > 0){
        [self setDuration:duration];
    }

    NSString *date = @"";
    if(_annotation.modifiedTimeInterval)
        date = dateStringForItem([NSDate dateWithTimeIntervalSinceReferenceDate:_annotation.modifiedTimeInterval]);
    else
        date = dateStringForItem([NSDate dateWithTimeIntervalSinceReferenceDate:_annotation.createdTimeInterval]);
    self.creationDate.kernValue = -0.32;
    self.creationDate.styleText = date;
    
    if(state == AudioStatePlaying){
        self.durationLabel.textColor = AUDIO_AQUA_COLOR;
        [self.playPauseButton setImage:[UIImage imageNamed:@"popoverPause"] forState:UIControlStateNormal];
    }
    else if(state == AudioStateRecording){
        self.durationLabel.textColor = AUDIO_RED_COLOR;
    }
    else
    {
        self.durationLabel.textColor = [UIColor colorNamed:@"headerColor"];
        self.creationDate.textColor = AUDIO_GRAY_COLOR;
        [self.playPauseButton setImage:[UIImage imageNamed:@"popoverPlay"] forState:UIControlStateNormal];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
}

-(IBAction)playPauseButtonAction:(id)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(playPauseButtonAction:)]){
        [self.delegate playPauseButtonAction:self];
    }
}
@end
