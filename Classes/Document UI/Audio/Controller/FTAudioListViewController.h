//
//  FTAudioListViewController.h
//  Noteshelf
//
//  Created by Chandan on 17/8/15.
//
//

#import <UIKit/UIKit.h>

@class FTAudioAnnotation;

@interface FTAudioListViewController : UIViewController
{
    
}
@property(nonatomic,weak) id delegate;
@property(nonatomic,weak) id dataSource;

-(void)showPopoverOnViewController:(UIViewController*)controller fromRect:(CGRect)rect onView:(UIView*)view;
-(void)dismissControllerAnimated:(BOOL)animate completion:(void (^)(void))completionBlock;

@end


@protocol FTAudioListViewControllerDelegtes <NSObject>

-(void)didClickOnAddNewRecording:(id)controller;
-(void)didClickOnExportButton:(FTAudioAnnotation*)annotation controller:(FTAudioListViewController*)controller;
-(void)didDeleteAnnotation:(FTAudioAnnotation*)annotation controller:(FTAudioListViewController*)controller;

@end

@protocol FTAudioListViewControllerDataSourceMethods<NSObject>

-(NSArray*)audioAnnotationsForController:(FTAudioListViewController*)controller;
-(id)currentlyVisiblePage;

@end
