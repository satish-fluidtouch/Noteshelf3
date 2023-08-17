//
//  FTBaseRenderViewController.h
//  Noteshelf
//
//  Created by Amar Udupa on 18/3/13.
//
//

#import <UIKit/UIKit.h>

@class FTRackViewController,FTDocumentItemWrapperObject, FTRackHostViewController, FTEraserRackViewController;

@protocol StickerSelectionDelegate;

@class FTPenSet;
@class FTScreenNames;
@interface FTBaseRenderViewController : UIViewController <StickerSelectionDelegate>
{

}

@property (strong) FTDocumentItemWrapperObject *shelfItemManagedObject;
@property (nonatomic,assign) BOOL readOnlyModeisOn;
@property (assign) RKDeskMode currentDeskMode;
@property (assign) RKDeskMode previousDeskMode;

//PenRack
@property (weak) UIViewController *rackViewController;

-(void)switchMode:(RKDeskMode)mode sourceView:(UIView *)sourceView;
-(void)changeMode:(RKDeskMode)mode;
-(void)closeRackForMode:(RKDeskMode)mode;
-(void)openRackForMode:(RKDeskMode)mode sourceView:(UIView *)sourceView;

-(void)saveChangesOnCompletion:(void (^)(BOOL success) )completion
           shouldCloseDocument:(BOOL)shouldClose
       shouldGenerateThumbnail:(BOOL)generateThumbnail;

@end
