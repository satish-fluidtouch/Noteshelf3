//
//  FTAudioListTableViewCell.h
//  Noteshelf
//
//  Created by Chandan on 17/8/15.
//
//

#import <UIKit/UIKit.h>
#import "FTAudioSession.h"

@class FTAudioAnnotation;
@interface FTAudioListTableViewCell : UITableViewCell
{
    
}
@property(nonatomic,strong)FTAudioAnnotation *annotation;
@property(nonatomic,weak)id delegate;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;

-(void)updateUI:(CGFloat)duration state:(AudioSessionState)state;
@end


@protocol FTAudioListTableViewCellDelegates <NSObject>
-(void)playPauseButtonAction:(id)sender;
@end
