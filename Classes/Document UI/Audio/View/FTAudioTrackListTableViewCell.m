//
//  FTAudioTrackListTableViewCell.m
//  Noteshelf
//
//  Created by Chandan on 18/8/15.
//
//

#import "FTAudioTrackListTableViewCell.h"
#import "FTAnnotationUtilities.h"
#import "Noteshelf-Swift.h"

#define AUDIO_RED_COLOR [UIColor colorNamed:@"buttonTitleColorDestructive"]
#define AUDIO_GRAY_COLOR [UIColor colorNamed:@"lightTitleColor_50"]
#define AUDIO_AQUA_COLOR [UIColor colorNamed:@"blueDodger"]

@implementation FTAudioTrackListTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    // Initialization code
    
    self.subTitleLabel.style = FTLabelStyleStyle5;
    
    self.titleLabel.textColor = [UIColor labelColor];
    self.subTitleLabel.textColor = [UIColor colorNamed:@"lightTitleColor_60"];
    
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    self.subTitleLabel.styleText = [FTUtils timeFormatted:0];
}

-(void)setModel:(FTAudioTrackModel *)model
{
    _model = model;
    self.subTitleLabel.styleText = [FTUtils timeFormatted:roundOffValue(model.duration)];
    [self updateUI:ceil(model.duration) state:[FTAudioSessionManager sharedSession].activeSessionState];
}

-(void)updateUI:(CGFloat)duration state:(AudioSessionState)state
{
    if(state == AudioStateRecording){
        self.subTitleLabel.textColor = AUDIO_RED_COLOR;
    }
    else if(state == AudioStatePlaying)
    {
        self.subTitleLabel.textColor = AUDIO_AQUA_COLOR;
        [self.playPauseImageView setImage:[UIImage imageNamed:@"popoverPause"]];
    }
    else
    {
        self.subTitleLabel.textColor = AUDIO_GRAY_COLOR;
        [self.playPauseImageView setImage:[UIImage imageNamed:@"popoverPlay"]];
    }
    if(duration > 0){
        self.subTitleLabel.styleText = [FTUtils timeFormatted:ceil(duration)];
    }
}

-(void)refresh
{
    if(!self.selected){
        self.subTitleLabel.styleText = [FTUtils timeFormatted:ceil(self.model.duration)];
        self.subTitleLabel.textColor = AUDIO_GRAY_COLOR;
        [self.playPauseImageView setImage:[UIImage imageNamed:@"popoverPlay"]];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self refresh];
}

+(AudioSessionState)state {
    return [FTAudioSessionManager sharedSession].activeSessionState;
}
@end
