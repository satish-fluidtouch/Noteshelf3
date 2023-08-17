//
//  FTAudioTracksListViewController.h
//  Noteshelf
//
//  Created by Chandan on 18/8/15.
//
//

#import <UIKit/UIKit.h>

@class FTAudioAnnotation,FTAudioTrackModel;
@interface FTAudioTracksListViewController : UIViewController
{
    
}
@property(nonatomic,strong)FTAudioAnnotation *annotation;
@property(nonatomic,weak)id delegate;

@end


@protocol FTAudioTracksListViewControllerDelegates <NSObject>

-(void)didClickOnBackButton:(FTAudioTracksListViewController*)controller;
-(void)didClickOnExportButton:(FTAudioTracksListViewController*)controller;
-(void)didClickOnContinueRecordingButton:(FTAudioTracksListViewController*)controller;

@end
