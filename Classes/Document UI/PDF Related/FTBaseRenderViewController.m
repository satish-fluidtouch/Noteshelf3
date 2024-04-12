//
//  FTBaseRenderViewController.m
//  Noteshelf
//
//  Created by Amar Udupa on 18/3/13.
//
//

#import "FTBaseRenderViewController.h"
#import "DataServices.h"
#import "Noteshelf-Swift.h"

@interface FTBaseRenderViewController ()

@end

@implementation FTBaseRenderViewController

@synthesize previousDeskMode = _previousDeskMode;
@synthesize currentDeskMode = _currentDeskMode;
@synthesize readOnlyModeisOn = _readOnlyModeisOn;
@synthesize shelfItemManagedObject = _shelfItemManagedObject;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)loadView
{
    //override if needed
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark saveChanges
-(void)saveChangesOnCompletion:(void (^)(BOOL success) )completion
           shouldCloseDocument:(BOOL)shouldClose
       shouldGenerateThumbnail:(BOOL)generateThumbnail
{
    
}

#pragma mark common methods

-(void)switchMode:(RKDeskMode)mode sourceView:(UIView *)sourceView
{
    //override if needed.
    if (mode!=self.currentDeskMode)
    {
        [self closeRackForMode:self.currentDeskMode];
        [self changeMode:mode];
    }
    else
    {
        [self openRackForMode:mode sourceView:sourceView];
    }

    self.previousDeskMode = self.currentDeskMode;
    self.currentDeskMode = mode;
    [self validateMenuItems];
}

-(void)changeMode:(RKDeskMode)mode
{
    //override if needed.
}

-(void)closeRackForMode:(RKDeskMode)mode
{
    //override if needed.
}

-(void)openRackForMode:(RKDeskMode)mode sourceView:(UIView *)sourceView
{
    NSUserActivity *activity = self.view.window.windowScene.userActivity;
    switch (mode) {
        case kDeskModePen:
        {
            FTRackData *penRack = [[FTRackData alloc] initWithType:FTRackTypePen userActivity:activity];
            [FTPenRackViewController setRackTypeWithPenTypeRack:penRack];

            [FTPenRackViewController showPopOverWithPresentingController:self sourceView:sourceView sourceRect: sourceView.bounds arrowDirections: UIPopoverArrowDirectionAny];
        }
            break;
        case kDeskModeMarker:
        {
            FTRackData *highlighterRack = [[FTRackData alloc] initWithType:FTRackTypeHighlighter userActivity:activity];
            [FTPenRackViewController setRackTypeWithPenTypeRack:highlighterRack];

            [FTPenRackViewController showPopOverWithPresentingController:self sourceView:sourceView sourceRect: sourceView.bounds arrowDirections: UIPopoverArrowDirectionAny];
        }
            break;
        case kDeskModeEraser:
        {
            UIViewController *controller = [FTEraserRackViewController showPopOverWithPresentingController:self sourceView:sourceView sourceRect: sourceView.bounds arrowDirections: UIPopoverArrowDirectionAny];
            ((FTEraserRackViewController *)controller).eraserDelegate = self;
        }
            break;
   
        case kDeskModePhoto:
        {
            [self switchMode:kDeskModePen sourceView:sourceView];
        }
            break;
        case kDeskModeShape:
        {
            FTRackData *shapesRack = [[FTRackData alloc] initWithType:FTRackTypeShape userActivity:activity];
            [FTShapesRackViewController setRackTypeWithPenTypeRack:shapesRack];

            [FTShapesRackViewController showPopOverWithPresentingController:self sourceView:sourceView sourceRect: sourceView.bounds arrowDirections: UIPopoverArrowDirectionAny];
        }
            break;
        case kDeskModeClipboard: // Lasso
        {
            UIViewController *controller = [FTLassoRackViewController showPopOverWithPresentingController:self sourceView:sourceView sourceRect: sourceView.bounds arrowDirections: UIPopoverArrowDirectionAny];
            ((FTLassoRackViewController *)controller).delegate = self;
        }
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Stickers

-(void)applyOrientationForStickersRack:(UIInterfaceOrientation)interfaceOrientation
{
    DEBUGLOG(@"Class %@ method %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
}

-(void) stickerSelected:(UIImage *)stickerImage  emojiID:(NSUInteger)emojiID 
{
    DEBUGLOG(@"Class %@ method %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
}

-(void) placeStickerInRect:(CGRect)targetRect
              stickerImage:(UIImage *)stickerImage
                   emojiID:(NSUInteger)emojiID
{
    
}

-(void)validateMenuItems
{
    
}

@end
