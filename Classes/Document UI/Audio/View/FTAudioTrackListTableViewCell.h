//
//  FTAudioTrackListTableViewCell.h
//  Noteshelf
//
//  Created by Chandan on 18/8/15.
//
//

#import <UIKit/UIKit.h>
#import "FTAudioTrackModel.h"
#import "FTAudioSession.h"

@class FTStyledLabel;

@interface FTAudioTrackListTableViewCell : UITableViewCell
{
    
}
-(void)updateUI:(CGFloat)duration state:(AudioSessionState)state;
@property(nonatomic,strong)FTAudioTrackModel *model;

@property (weak, nonatomic) IBOutlet FTStyledLabel *titleLabel;
@property (weak, nonatomic) IBOutlet FTStyledLabel *subTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *playPauseImageView;

@end
