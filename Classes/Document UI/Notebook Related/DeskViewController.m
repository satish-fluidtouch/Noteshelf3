//
//  DeskViewController.m
//  Noteshelf
//
//  Created by Rama Krishna on 7/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>
#import <Twitter/Twitter.h>
#import "Noteshelf-Swift.h"

#import "DeskViewController.h"
#import "DesktopView.h"
#import "UIImageAdditions.h"
#import "NoteshelfAppDelegate.h"
#import "ShelfItem.h"
#import "Page.h"
#import "DrawingContent.h"
#import "DrawingThumbnail.h"
#import "DataServices.h"
#import "ApplicationDefaults.h"
#import "DeskToolbarView.h"

#import "UIColorAdditions.h"

#import "AccessoryButtonActionPicker.h"

#import <social/Social.h>

#import "SFManager.h"

#import "FTPenCollectionManager.h"
#import "FTBasePenCollection.h"
#import "FTBasePenModel.h"
#import "FTUtils.h"

#if iPEN_CREGLE_SUPPORTED
#import <CRAccessoryKit/CRAccessoryKit.h>
#endif

#import "FTStylusPenManager.h"
#import "FTENPublishManager.h"
#import "FTBaseStylusSettingsViewController.h"

#import "FTShelfTheme.h"

#import "FTShapeStroke.h"
#import "FTAnnotation.h"

#import "FTAudioListViewController.h"
#import "FTAudioAnnotationViewManager.h"
#import "FTAudioAnnotationViewController.h"

#import "FTGoogleAnalytics.h"

#import "FTZenDeskManager.h"

//clipboard operation
#import "FTClipboardImageTransformerContainerView.h"
#import "FTImagePickerController.h"

#import "FTCloudBackUpManager.h"
#import "FTFileSizeGenerator.h"
#import "FTMoreActionsViewController.h"

#import <Photos/Photos.h>

@interface DeskViewController () <UIGestureRecognizerDelegate,UIPopoverPresentationControllerDelegate,UIDocumentInteractionControllerDelegate,FTDocumentDelegate,FTSettingsDelegate>
{
    BOOL putUpAlertIfEraserMovedOverImage;
    BOOL publishPausedDueToBackground;
}
@property (weak) UILongPressGestureRecognizer *longPressGesture;
@property (weak) UITapGestureRecognizer *singleTapGesture;
@property (strong) UIDocumentInteractionController *audioShareInteractionController;
@property (assign) UIInterfaceOrientation currentOrientation;
@property (assign) BOOL forceLayout;

@property (nonatomic, assign) BOOL cameraShown;

@property (nonatomic,strong) FTShapeStroke *shapeStroke;

@property (nonatomic,strong) FTCloudDocumentConflictScreen *conflictViewController;

//Universal Settings
@property (nonatomic , strong) FTSettingsSlideInPresentationManager *transitioningDelegate;
@property (nonatomic, strong) UINavigationController *moreActionsToolsController;
@property (nonatomic, strong) FTImagePickerController *photosPopover;

@end


@implementation DeskViewController

@synthesize desktopView, deskToolbarView, toolbarImageView, coverContainerView, writingView, pageCurlView;
@synthesize onScreenPageView, offScreenPageView;
@synthesize notebook;

@synthesize previousPageImage;
@synthesize currentPageImage;
@synthesize nextPageImage;

@synthesize photosPopover;
@synthesize moreActionsToolsController;

@synthesize stickerSelectionView, stickerPlacementView, photoView, lassoView, clipboardView;

@synthesize zoomManagerView, zoomPanel;

@synthesize returningFromFinder;

@synthesize alwaysInPortrait;

@synthesize conn;

#pragma mark -
#pragma mark View Controller Methods

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	
    //NSLog(@"loadView");
    
    cacheNextPreviousPages = ([UIScreen mainScreen].scale > 1.0);
    
    viewLoaded = NO;
    firstTimeAnimation = YES;
//    alwaysInPortrait = notebook.shelfItem.isPortraitBook;
    
	UIView *mainView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    mainView.clipsToBounds = YES;
	self.view = mainView;
    
	self.view.backgroundColor = UIColorFromRGB(0x363636); //0x2b2b2b
    
	desktopView = [[DesktopView alloc] initWithFrame:CGRectMake(0, 44, 768, 1004-44) notebookShelfItem:self.notebookShelfItem];
    
	//desktopView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:desktopView];
    
    [desktopView addSubview:self.coverContainerView];
    desktopView.contentView = self.coverContainerView;
    
    onScreenPageView = [[PageView alloc] initWithFrame:CGRectMake(0, 18, 736, 924)];
	onScreenPageView.notebookTitleLabel.text = self.notebookShelfItem.title;
	[coverContainerView addSubview:onScreenPageView];
    	
	offScreenPageView = [[PageView alloc] initWithFrame:CGRectMake(0, MAX(CGRectGetHeight([UIScreen mainScreen].bounds),CGRectGetWidth([UIScreen mainScreen].bounds)), 736, 924)];
	offScreenPageView.notebookTitleLabel.text = self.notebookShelfItem.title;
	[self.view addSubview:offScreenPageView];
	
    [self refreshPageNumbers];
    
	toolbarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 60)];
	toolbarImageView.image = [FTShelfTheme currentTheme].toolbarImagePortrait;
	toolbarImageView.userInteractionEnabled = NO;
	[self.view addSubview:toolbarImageView];
	
	deskToolbarView = [[DeskToolbarView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44) delegate:self showViewMode:NO];
	//deskToolbarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:deskToolbarView];
	
	deskMode = kDeskModePen;
	deskToolbarView.penButton.selected = YES;
	
    pageCurlView.currentPageIndex = [self.notebookShelfItem.currentPageIndex integerValue];
    if(self.notebook.pages.count < pageCurlView.currentPageIndex)
    {
        [Flurry logEvent:@"Unexpected Error" withParameters:@{@"Reason" : @"Current page Index mismatch",@"UI":@"Desk View Controller"}];
        pageCurlView.currentPageIndex = self.notebook.pages.count;
    }
	[onScreenPageView setDate:[self getCreationDateForPage:pageCurlView.currentPageIndex]];
	
	//Always have 1 blank page at the end
	pageCurlView.numberOfPages = self.notebook.pages.count  + 1;
    
	[self loadInvisibleViews];
		
	deskToolbarView.debuggingButton1.hidden = YES;
	
    //Switch mode to last used mode
    if ([[DataServices sharedDataServices].appDefaultsManageObject.currentTool intValue] != kDeskModePen) {
        [self switchMode:[[DataServices sharedDataServices].appDefaultsManageObject.currentTool intValue]];
    } 
    
    if ([self.notebookShelfItem.readOnly boolValue]) {
        
        [self setReadonlyMode]; 
        
    }else{
        
        [self dismissReadonlyMode];
    }
	
    //[[FTStylusPenManager sharedInstance] registerView:self.pageCurlView delegate:(id)self.writingView];
    [[FTStylusPenManager sharedInstance] registerView:self.writingView delegate:(id)self.writingView];

    //Button to show the classic pages popover
    UIButton *pagesPopoverButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frameRect = [onScreenPageView convertRect:onScreenPageView.pageNumberLabel.frame toView:pageCurlView];
    pagesPopoverButton.frame = frameRect;
    //pagesPopoverButton.backgroundColor = [UIColor redColor];
    //pagesPopoverButton.alpha = 0.5;
    pagesPopoverButton.tag = 111;
    [pagesPopoverButton addTarget:self action:@selector(quickLookButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [pageCurlView addSubview:pagesPopoverButton];
    
	//Keyboard Notifications
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(keyboardWasShown:) 
												 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification object:nil];
	
    //currentInterfaceOrientation = self.interfaceOrientation;

    //Universal Settings
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shelfThemeChanged) name:FTShelfThemeDidChangeNotification object:nil];

    writingView.auxiliaryInputAvailable = NO;

    //Pressure Stylus related
    [PressurePenEngine sharedPressurePenEngine].delegate = self;
    [[PressurePenEngine sharedPressurePenEngine] start];
    
    
    //Do this even if Jot Touch is not used
    writingView.jotPrecisionOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"ADONIT_JOT_SETTINGS_PRECISION"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pauseOpenGLOperations)
                                                 name:FTPauseOpenGLOperations
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resumeOpenGLOperations)
                                                 name:FTResumeOpenGLOperations
                                               object:nil];

    UIView *blackBorderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
    blackBorderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    blackBorderView.backgroundColor = [UIColor blackColor];
    [self.view insertSubview:blackBorderView aboveSubview:self.desktopView];
    [self refreshActiveStylusButton];
#if iPEN_CREGLE_SUPPORTED
    if([[CRAccessoryManager sharedManager] connectedAccessories].count)
    {
        writingView.auxiliaryInputAvailable = YES;
        pageCurlView.smartPenPageTurnMode = YES;
        onScreenPageView.smartPenIndicator.hidden = NO;
    }
#endif
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongTapped:)];
    longPressGesture.delaysTouchesEnded = NO;
    longPressGesture.delegate = self;
    [self.view addGestureRecognizer:longPressGesture];
    self.longPressGesture = longPressGesture;

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureRecognized:)];
    tapGesture.delaysTouchesEnded = NO;
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    self.singleTapGesture = tapGesture;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEndAllTouches:) name:@"FTDidEndAllTouchesNotification" object:self.writingView];
    [self addObservers];
    
    FTAudioAnnotationViewManager *manager = [FTAudioAnnotationViewManager sharedManager];
    manager.delegate = self;
}


-(void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayerDidClose:) name:FTAudioPlayerControllerDidCloseNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayerDidOpen:) name:FTAudioPlayerControllerDidOpenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayerDidStopRecording:) name:FTAudioSessionEventChangeNotification object:nil];
}

-(void)setNotebook:(FTNNotebookDocument *)innotebook
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FTDocumentDidMoved" object:notebook];
    notebook = innotebook;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentDidMoved:) name:@"FTDocumentDidMoved" object:nil];
}

-(void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id) object
                        change: (NSDictionary *) change context: (void *) context{
    
    if ([keyPath isEqualToString:@"hidden"]) {
        BOOL newValue = [[change objectForKey: NSKeyValueChangeNewKey] boolValue];
        if (newValue == YES) {
            onScreenPageView.pageNumberLabel.hidden = NO;
            offScreenPageView.pageNumberLabel.hidden = NO;
        }else{
            onScreenPageView.pageNumberLabel.hidden = YES;
            offScreenPageView.pageNumberLabel.hidden = YES;
        }
    }
}

-(BOOL)isAnyPenConnected
{
    if (  [[PressurePenEngine sharedPressurePenEngine] pogoWristProtectionEnabled]
        || [[PressurePenEngine sharedPressurePenEngine] intuosWristProtectionEnabled]
        || [[PressurePenEngine sharedPressurePenEngine] adonitWristProtectionEnabled]
        || [[PressurePenEngine sharedPressurePenEngine] pencilWristProtectionEnabled]
        || [[PressurePenEngine sharedPressurePenEngine] applePencilEnabled]
        )
    {
        return  true;
    }
    return false;
}

-(void)refreshAuxNavigatorDisplayForOrientation:(UIInterfaceOrientation)interfaceOrientation{
    
    if (self.alwaysInPortrait && UIInterfaceOrientationIsLandscape(interfaceOrientation) && !zoomPanel) {
        
    }else{
        
        if ([self.notebookShelfItem.readOnly boolValue])
        {
        }else{
            
            if (zoomPanel) {
            }else{
                if (
                    [self.notebookShelfItem.wristProtectionOn boolValue]
                    || [self isAnyPenConnected]
                    )
                {
                }else{
                }
            }
            
        }
        
    }
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    //NSLog(@"viewWillAppear");
    
	[super viewWillAppear:animated];
    
    if (self.cameraShown || self.audioShareInteractionController) {
        [self animatePreRotation:[[UIApplication sharedApplication] statusBarOrientation]];
        self.cameraShown = NO;
        return;
    }
    
    if (viewLoaded == YES) {
        [self configureRenderView];
    }else{
        [self getWritingPositionForPage:pageCurlView.currentPageIndex];
        viewLoaded = YES;
    }
    
    [self refreshPageNumbers];
    [self refreshAnnotationsView];
}

-(void)configureRenderView
{
    pageCurlView.currentPageIndex = [self.notebookShelfItem.currentPageIndex integerValue];
    
    [onScreenPageView setDate:[self getCreationDateForPage:pageCurlView.currentPageIndex]];
    //Always have 1 blank page at the end
    pageCurlView.numberOfPages = self.notebook.pages.count + 1;
    self.currentPageImage = [self getImageForPage:pageCurlView.currentPageIndex];
    
    if (cacheNextPreviousPages) {
        [self cachePreviousPageImageWithIndex:pageCurlView.currentPageIndex-1];
        [self cacheNextPageImageWithIndex:pageCurlView.currentPageIndex+1];
    }
    
    [self updatePageCurlImage];
    
    if (deskMode == kDeskModeText) {
    }else{
        [self putTextForPage:pageCurlView.currentPageIndex];
    }
    
    [writingView putUIImage:self.currentPageImage];
    [self getWritingPositionForPage:pageCurlView.currentPageIndex];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.notebook.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    
    //NSLog(@"View Will Appear");
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    [self animatePreRotation:[[UIApplication sharedApplication] statusBarOrientation]];
    if (zoomManagerView)
        [self setZoomAreaPosition:[self getZoomAreaPositionForPage:pageCurlView.currentPageIndex]];
    
    [CATransaction commit];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //NSLog(@"View Will Disapperar");
}

-(BOOL)prefersStatusBarHidden
{
    if ([[FTAudioAnnotationViewManager sharedManager] isPlayerVisible])
    {
        return YES;
    }
    
    //in case if the welcome tour is shown then give preference for that until it is dismissed
    UIViewController *presentedViewController = self;
    if([presentedViewController.presentedViewController isKindOfClass:[FTWEMainScreenVC class]]) {
        return [presentedViewController.presentedViewController prefersStatusBarHidden];
    }

    return [super prefersStatusBarHidden];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
    return UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotate{
    return YES;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self closeAudioPopover];
   	if (moreActionsToolsController != nil) {
        [self dismissMoreActionsToolsControllerAnimate:YES];
    }

    if (self.photosPopover != nil && self.photosPopover.sourceType != UIImagePickerControllerSourceTypeCamera) {
        [self.photosPopover dismissViewControllerAnimated:NO completion:nil];
        self.photosPopover = nil;
    }

    [self closeAddRackViewOnCompletion:nil];
    if(!(self.stickerSelectionView.panelState == kStickersPanelHide))
    {
        [stickerSelectionView animateStickersView:kStickersPanelHide];
    }

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (!self.alwaysInPortrait)
        {
            zoomPanel.alpha = 0.0f;
        }
        if(!firstTimeAnimation)
            [self animatePreRotation:[[UIApplication sharedApplication] statusBarOrientation]];
       
        if (deskToolbarView.zoomButton.selected)
        {
            [self zoomPanelAdjustToOrientationChange:[[UIApplication sharedApplication] statusBarOrientation]];
        }

    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self finalizeSizeClassChange];
    }];
}


-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if (([[UIApplication sharedApplication] statusBarOrientation] != self.currentOrientation) || self.forceLayout)
    {
        self.currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [self animatePreRotation:[[UIApplication sharedApplication] statusBarOrientation]];
        self.forceLayout = NO;
    }
}

-(void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [self finalizeSizeClassChange];
}

- (void)finalizeSizeClassChange
{
    //NSLog(@"didRotateFromInterfaceOrientation");
    
    if (!self.alwaysInPortrait)
    {
        if (deskToolbarView.zoomButton.selected) {
            [self zoomPanelAdjustToOrientationChange:[[UIApplication sharedApplication] statusBarOrientation]];
        }
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        zoomPanel.alpha = 1.0f;
        [UIView commitAnimations];
    }

    if ([APP_DELEGATE visibleActionSheet]) {
        [[APP_DELEGATE visibleActionSheet] dismissWithClickedButtonIndex:[APP_DELEGATE visibleActionSheet].cancelButtonIndex animated:YES];
    }
    
    if (self.photosPopover != nil && self.photosPopover.sourceType != UIImagePickerControllerSourceTypeCamera) {
        [self.photosPopover dismissViewControllerAnimated:NO completion:nil];
        self.photosPopover = nil;
    }
    
    if(self.exportPopoverController != nil) {
        [self.exportPopoverController.presentedViewController dismissViewControllerAnimated:false completion:nil];
        self.exportPopoverController = nil;
    }

    [self closeAudioPopover];

	if (moreActionsToolsController != nil) {
        [self dismissMoreActionsToolsControllerAnimate:YES];
	}
	
    
	if (zoomPanel) {
        [zoomPanel dismissPopovers];
	}
    
}

- (void)animatePreRotation:(UIInterfaceOrientation)interfaceOrientation
{
    if (self.alwaysInPortrait)
    {
        [self refreshAuxNavigatorDisplayForOrientation:interfaceOrientation];
        
        [self applyOrientationForPenRack:interfaceOrientation];
        [self applyOrientationForEraserRack:interfaceOrientation];
        [self applyOrientationForStickersRack:interfaceOrientation];
        [self applyOrientationForAudioAnnotation:interfaceOrientation];
        [self applyOrientationForAddAnnotationView:interfaceOrientation];
        
        [deskToolbarView renderForOrientation:UIInterfaceOrientationPortrait];

        if (self.alwaysInPortrait) {
            firstTimeAnimation = NO;
            return;
        }
    }
    else
    {
        [self applyOrientationForPenRack:interfaceOrientation];
        [self applyOrientationForEraserRack:interfaceOrientation];
        [self applyOrientationForAddAnnotationView:interfaceOrientation];
    }
    
    [self refreshAuxNavigatorDisplayForOrientation:interfaceOrientation];
    
    [self writingPositionChanged];
    
    [self applyOrientationForStickersRack:interfaceOrientation];
    [self applyOrientationForPhotoPlacementView:interfaceOrientation];
    [self applyOrientationForClipboardView:interfaceOrientation];
    
    UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:interfaceOrientation forShelfItem:self.notebookShelfItem];
    [self applyOrientationForAudioAnnotation:layoutOrientation];

    [deskToolbarView renderForOrientation:interfaceOrientation];
	
    currentInterfaceOrientation = interfaceOrientation;
    firstTimeAnimation = NO;
    
    self.returningFromFinder = NO;
    //Amar 4-Mar-13:to here
    //NSLog(@"animatePreRotation done");
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    NSArray *pages = self.notebook.pages;
    for (FTNNotebookPage *eachPage in pages) {
        if(eachPage.pageIndex.integerValue < self.pageCurlView.currentPageIndex - 1 && eachPage.pageIndex.integerValue > self.pageCurlView.currentPageIndex + 1){
            [eachPage unloadContents];
        }
    }
	memoryWarning = YES;
}

#pragma mark Keyboard Notification methods

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    
	if (keyboardShown) return;
	
	NSDictionary *userInfo = [aNotification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	NSValue* aValue2 = [userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardRect2 = [aValue2 CGRectValue];
    keyboardRect2 = [self.view convertRect:keyboardRect2 fromView:nil];
    
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
	
    
    //Using the difference of Y instead of the height will enable proper use of hardware keyboard
    desktopView.accessoryHeight = keyboardRect2.origin.y - keyboardRect.origin.y;
    
	//NSLog(@"keyboardRect.size.height: %d and y is:%d", (int)desktopView.accessoryHeight, (int)(keyboardRect2.origin.y - keyboardRect.origin.y));
    
    keyboardShown = YES;
    
}


// Called when the UIKeyboardDidHideNotification is sent
- (void)keyboardWillHide:(NSNotification*)aNotification{	
	
	if (!keyboardShown) return;
	
	desktopView.accessoryHeight = 0.0;
	
    keyboardShown = NO;
}

#pragma mark -
#pragma mark Pause / Resume OpenGL

-(void)pauseOpenGLOperations{

}

-(void)resumeOpenGLOperations
{
    if (publishPausedDueToBackground && !writingView.renderCyclePaused)
    {
        [self.writingView publishCanvas];
    }
    publishPausedDueToBackground = NO;
    [self showPage:pageCurlView.currentPageIndex refreshCurrentPage:writingView.renderCyclePaused retainUndoBuffer:YES];
}


#pragma mark -
#pragma mark Invisible Views (for memory optimization)

-(void)loadInvisibleViews{
	
	writingView = [[WritingSurfaceView alloc] initWithFrame:CGRectMake(0, 18, 736, 864) delegate:self];
    
    [self updatePageCurlImage];

	[coverContainerView addSubview:writingView];
	
	//Set the defaults size and color of the brush
	[self setCurrentPenWritingMode];
	[self getWritingPositionForPage:pageCurlView.currentPageIndex];
	
	if ([self.notebookShelfItem.wristProtectionOn boolValue]) {
		writingView.wristProtectionOn = YES;
	}
	
	self.currentPageImage = [self getImageForPage:pageCurlView.currentPageIndex];
	
    [self putTextForPage:pageCurlView.currentPageIndex];
    [writingView putUIImage:self.currentPageImage];

    if (cacheNextPreviousPages) {
		[self cachePreviousPageImageWithIndex:pageCurlView.currentPageIndex-1];
        [self cacheNextPageImageWithIndex:pageCurlView.currentPageIndex+1];
	}
	
    [deskToolbarView updateUndoButton];
}

#pragma mark -
#pragma mark PressurePenEngine Delegate Methods

-(void)pressurePenAvailable:(NSString *)stylusName{
    
    NSString *wacomDeviceName = [[[PressurePenEngine sharedPressurePenEngine] connectedWacomDevice] getName];
    if(self.writingView.zoomGLView)
    {
        [[FTStylusPenManager sharedInstance] registerView:self.writingView.zoomGLView delegate:(id)self.writingView.zoomGLView];
    }
    else
    {
        //[[FTStylusPenManager sharedInstance] registerView:self.pageCurlView delegate:(id)self.writingView];
        [[FTStylusPenManager sharedInstance] registerView:self.writingView delegate:(id)self.writingView];
    }
    
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    
    if([stylusName hasPrefix:@"Jot"])
    {
        if( [[PressurePenEngine sharedPressurePenEngine] adonitWristProtectionEnabled])
            pageCurlView.pressurePenPageTurnMode=YES;
        else
            pageCurlView.pressurePenPageTurnMode=NO;

    }
    else if([stylusName hasPrefix:@"Pogo"])
    {
        if( [[PressurePenEngine sharedPressurePenEngine] pogoWristProtectionEnabled])
            pageCurlView.pressurePenPageTurnMode=YES;
        else
            pageCurlView.pressurePenPageTurnMode=NO;
        
    }
    else if([stylusName hasPrefix:@"Pencil"])
    {
        if( [[PressurePenEngine sharedPressurePenEngine] pencilWristProtectionEnabled])
            pageCurlView.pressurePenPageTurnMode=YES;
        else
            pageCurlView.pressurePenPageTurnMode=NO;
        
    }
    else if(wacomDeviceName)
    {
        if( [[PressurePenEngine sharedPressurePenEngine] intuosWristProtectionEnabled])
            pageCurlView.pressurePenPageTurnMode=YES;
        else
            pageCurlView.pressurePenPageTurnMode=NO;
        
    }
    else if([stylusName hasPrefix:@"Apple Pencil"])
    {
        pageCurlView.pressurePenPageTurnMode=YES;
    }
    else
        self.pageCurlView.pressurePenPageTurnMode=NO;
    
    [self refreshActiveStylusButton];
}

-(void)pressurePenNotAvailable:(NSString *)stylusName{

    if(self.writingView.zoomGLView)
    {
        [[FTStylusPenManager sharedInstance] unregisterView:self.writingView.zoomGLView setToDefault:YES];
    }
    else
    {
        [[FTStylusPenManager sharedInstance] unregisterView:self.writingView setToDefault:YES];
        //[[FTStylusPenManager sharedInstance] unregisterView:self.pageCurlView setToDefault:YES];
    }
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    
    
    pageCurlView.pressurePenPageTurnMode=NO;
    [self refreshActiveStylusButton];
}

-(void)pressurePenConnected:(NSString *)stylusName{

    [FTZenDeskManager setLastConnectedStylus:stylusName];
    NSString *wacomDeviceName = [[[PressurePenEngine sharedPressurePenEngine] connectedWacomDevice] getName];
    
    //Check if we are in zoom mode
    BOOL shouldShowConnectedMessage = YES;
    if(self.writingView.zoomGLView)
    {
        [[FTStylusPenManager sharedInstance] registerView:self.writingView.zoomGLView delegate:(id)self.writingView.zoomGLView];
    }
    else
    {
        //[[FTStylusPenManager sharedInstance] registerView:self.pageCurlView delegate:(id)self.writingView];
        [[FTStylusPenManager sharedInstance] registerView:self.writingView delegate:(id)self.writingView];
    }
    
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    


    if([stylusName hasPrefix:@"Pogo"])
    {
       if( [[PressurePenEngine sharedPressurePenEngine] pogoWristProtectionEnabled])
           pageCurlView.pressurePenPageTurnMode=YES;
        else
            pageCurlView.pressurePenPageTurnMode=NO;

    }
    else if([stylusName hasPrefix:@"Jot"])
    {
        if([JotStylusManager sharedInstance].stylusFriendlyName)
            stylusName = [JotStylusManager sharedInstance].stylusFriendlyName;
        
        if( [[PressurePenEngine sharedPressurePenEngine] adonitWristProtectionEnabled])
        {
            pageCurlView.pressurePenPageTurnMode=YES;
            if(deskToolbarView.wristProtectionButton.selected)
                [self wristProtectionToggle:NO];
        }
        else
            pageCurlView.pressurePenPageTurnMode=NO;
        
    }
    else if(wacomDeviceName)
    {
        if( [[PressurePenEngine sharedPressurePenEngine] intuosWristProtectionEnabled])
            pageCurlView.pressurePenPageTurnMode=YES;
        else
            pageCurlView.pressurePenPageTurnMode=NO;
    }
    else if([stylusName hasPrefix:@"Pencil"])
    {
        if( [[PressurePenEngine sharedPressurePenEngine] pencilWristProtectionEnabled])
        {
            pageCurlView.pressurePenPageTurnMode=YES;
            if(deskToolbarView.wristProtectionButton.selected)
                [self wristProtectionToggle:NO];
        }
        else
            pageCurlView.pressurePenPageTurnMode=NO;
        
        if([FTUniversalSettingsSplitViewController isOpen])
            shouldShowConnectedMessage = NO;
        
    }
    else
        pageCurlView.pressurePenPageTurnMode=NO;
    
    if(applicationEnteredBackground || [stylusName hasPrefix:@"Hex3"] || [FTUniversalSettingsSplitViewController isOpen])
        shouldShowConnectedMessage = NO;

    
    if(shouldShowConnectedMessage)
    {
        [[self.view viewWithTag:SMART_MESSAGE_TAG] removeFromSuperview];
        
        SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"StylusNameConnected", @"%@ Connected"), stylusName]
                                                                               style:kSmartMessageJustText];
        smartMessageView.tag = SMART_MESSAGE_TAG;
        self.view.userInteractionEnabled = NO;
        [self.view addSubview:smartMessageView];
        [smartMessageView dismissAfterInterval:1.0 delegate:self];

    }
    
    [self refreshActiveStylusButton];
}

-(void)pressurePenDisconnected:(NSString *)stylusName{

    if(self.writingView.zoomGLView)
    {
        [[FTStylusPenManager sharedInstance] unregisterView:self.writingView.zoomGLView setToDefault:YES];
    }
    else
    {
        [[FTStylusPenManager sharedInstance] unregisterView:self.writingView setToDefault:YES];
        //[[FTStylusPenManager sharedInstance] unregisterView:self.pageCurlView setToDefault:YES];
    }
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    pageCurlView.pressurePenPageTurnMode=NO;
    BOOL shouldShowDisConnectedMessage = YES;
    //For Pencil since we have the kiss to pair view in popover we need not show connected message
    if([stylusName hasPrefix:@"Pencil"] && [FTUniversalSettingsSplitViewController isOpen])
        shouldShowDisConnectedMessage = NO;
    
    if(applicationEnteredBackground || [stylusName hasPrefix:@"Hex3"] || [FTUniversalSettingsSplitViewController isOpen])
        shouldShowDisConnectedMessage = NO;
    
    if([stylusName hasPrefix:@"Jot"])
    {
        if([JotStylusManager sharedInstance].stylusFriendlyName)
            stylusName = [JotStylusManager sharedInstance].stylusFriendlyName;
    }
    
    if(shouldShowDisConnectedMessage)
    {
        [[self.view viewWithTag:SMART_MESSAGE_TAG] removeFromSuperview];
        SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"StylusNameDisconnected", @"%@ Disconnected"), stylusName]
                                                                               style:kSmartMessageJustText];
        smartMessageView.tag = SMART_MESSAGE_TAG;
        self.view.userInteractionEnabled = NO;
        [self.view addSubview:smartMessageView];
        [smartMessageView dismissAfterInterval:2.0 delegate:self];

    }
    [self refreshActiveStylusButton];
}

-(void)pressurePenEnabled:(NSString *)stylusName{

    if(self.writingView.zoomGLView)
    {
        [[FTStylusPenManager sharedInstance] registerView:self.writingView.zoomGLView delegate:(id)self.writingView.zoomGLView];
    }
    else
    {
        [[FTStylusPenManager sharedInstance] registerView:self.writingView delegate:(id)self.writingView];
    }
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];

    
    [self refreshActiveStylusButton];
}

-(void)pressurePenDisabled:(NSString *)stylusName{
    
    if(self.writingView.zoomGLView)
    {
        [[FTStylusPenManager sharedInstance] unregisterView:self.writingView.zoomGLView setToDefault:YES];
    }
    else
    {
        [[FTStylusPenManager sharedInstance] unregisterView:self.writingView setToDefault:YES];
        //[[FTStylusPenManager sharedInstance] unregisterView:self.pageCurlView setToDefault:YES];
    }
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];

    
    [self refreshActiveStylusButton];
}

-(void)pressurePenShowMessage:(NSString *)message{
    [[self.view viewWithTag:SMART_MESSAGE_TAG] removeFromSuperview];
    if(![FTUniversalSettingsSplitViewController isOpen]) {
        SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                             message:message
                                                                               style:kSmartMessageJustText];
        smartMessageView.tag = SMART_MESSAGE_TAG;
        self.view.userInteractionEnabled = NO;
        [self.view addSubview:smartMessageView];
        [smartMessageView dismissAfterInterval:2.0 delegate:self];
    }
}

-(BOOL)canUndo
{
    return [writingView canUndo];
}

-(BOOL)canRedo
{
    return [writingView canRedo];
}

-(void)pressurePenButtonAction:(RKAccessoryButtonAction)actionToPerform{
    
    NSString *buttonAction = nil;

    switch (actionToPerform) {
        case kAccessoryButtonActionUndo:
            
            if ([self canUndo]) {
                [self performSelector:@selector(undoButtonAction) ];
                buttonAction = @"Button: Undo";
            }
            break;
            
        case kAccessoryButtonActionRedo:
            
            if ([self canRedo]) {
                [self performSelector:@selector(redoButtonAction)];
                buttonAction = @"Button: Redo";
            }
            break;
        case kAccessoryButtonActionNextColor:
            
            [self incrementPenColor:1];
            buttonAction = @"Button: Pen Color Increment";
            break;
        case kAccessoryButtonActionPrevColor:
            
            [self incrementPenColor:-1];
            buttonAction = @"Button: Pen Color Decrement";
            break;
        case kAccessoryButtonActionNextPage:
            [pageCurlView jumpToNextPage];
            buttonAction = @"Button: Next Page";
            break;
        case kAccessoryButtonActionPrevPage:
            [pageCurlView jumpToPreviousPage];
            buttonAction = @"Button: Previous Page";
            break;
        default:
            break;
    }
    /*********** Log to Crashlytics **************/
    @try
    {
        if(buttonAction)
        {
            
            NSString *connectPen = [PressurePenEngine sharedPressurePenEngine].enabledPenName;

            [Flurry logEvent:@"Smart Pen Button Action" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:buttonAction, @"Action", connectPen, @"Pen", @"Notebook", @"Shelf Item", nil]];
            CLSLog(@"Notebook: Pressure Pen Button Action %@",buttonAction);
        }
        
    }
    @catch (NSException *exception) {
        [Flurry logEvent:@"Consistency Issue" withParameters:[NSDictionary dictionaryWithObjects:@[@"Smart Pen Button Action Flurry Event"] forKeys:@[@"Reason"]]];
    }
    /*********** Log to Crashlytics **************/
}

-(void)didSuggestEnablingGestures
{
    
}
-(void)didSuggestDisablingGestures
{
    
}
#pragma mark Accessory Button Related

-(void)incrementPenColor:(int)increment{
    
    [self normalizeDeskMode];
    
    if(increment == -1)
    {
        //previous pen
        FTBasePenModel *pen = [[FTPenCollectionManager sharedCollectionManager].selectedPen.collection previousPen];
        [[FTPenCollectionManager sharedCollectionManager] setSelectedPen:pen];
    }
    else
    {
        //next Pen
        FTBasePenModel *pen = [[FTPenCollectionManager sharedCollectionManager].selectedPen.collection nextPen];
        [[FTPenCollectionManager sharedCollectionManager] setSelectedPen:pen];
    }
    
    if (deskMode != kDeskModePen && deskMode != kDeskModeMarker) {
		[self switchMode:kDeskModePen];
        [deskToolbarView refreshSelectedPenColor];
	}else if(deskMode == kDeskModePen){
        [self setCurrentPenWritingMode];
        [deskToolbarView refreshSelectedPenColor];
    }
    else if(deskMode == kDeskModeMarker){
        [self setCurrentPenWritingMode];
        [deskToolbarView refreshSelectedMarkerColor];
    }
    if (zoomPanel) [self refreshZoomButtonStates];
    
}

#pragma mark -
#pragma mark Readonly Mode

-(void)setReadonlyMode{
    
    if (deskMode != kPenMode) {
        [self switchMode:kDeskModePen];
    }
    
    writingView.userInteractionEnabled = NO;
    [deskToolbarView hideEditButtons];
    
    if (zoomPanel) {
        [self dismissZoomMode];
    }
    
    pageCurlView.canTurnPage = YES;
    
    
    
    //auxNavigator.hidden = YES;
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

-(void)dismissReadonlyMode{
    writingView.userInteractionEnabled = YES;
    [deskToolbarView unhideEditButtons];
    [self refreshActiveStylusButton];
    
    if ([self.notebookShelfItem.zoomModeActive boolValue] && !zoomPanel) {
        //calling as delayed selector becasue the main writing view is not refreshing for some reason
        [self performSelector:@selector(initiateZoomMode) withObject:nil afterDelay:0.001];
        
    }else{
        if ([self.notebookShelfItem.wristProtectionOn boolValue]) {
            //auxNavigator.hidden = NO;
        }else{
            //auxNavigator.hidden = YES;
        }
    }
    
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    if ([self.notebookShelfItem.wristProtectionOn boolValue]) {
        deskToolbarView.wristProtectionButton.selected = YES;
        pageCurlView.canTurnPage = NO;
	}else {
        pageCurlView.canTurnPage = YES;
        deskToolbarView.wristProtectionButton.selected = NO;
	}
    
}


-(void)unloadInvisibleViews{
	
	
	if(deskToolbarView.zoomButton.selected) [self dismissZoomMode];
	
	//onScreenPageView.drawingImageView.image = self.currentPageImage;
	
	//Remove unnessary objects from memory before switch to shelf
	
	self.previousPageImage = nil;
	
	self.currentPageImage = nil;
	
	self.nextPageImage = nil;
	
	[writingView removeFromSuperview];
	self.writingView = nil;
    
    if (zoomPanel) {
        [self dismissZoomMode];
    }
    
}



#pragma mark -
#pragma mark Page Handling Methods

-(void)refreshPageNumbers{
    
    onScreenPageView.pageNumberLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NofN", @"%d of %d"), pageCurlView.currentPageIndex +1, pageCurlView.numberOfPages];
	
	if (zoomPanel)
		zoomPanel.pageNumberLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NofNAlt", @"%d of %d"), pageCurlView.currentPageIndex +1, pageCurlView.numberOfPages];
}

-(UIImage *)getPageSnapshotFromDatabase:(NSUInteger)pageIndex{
	
	UIImage *pageImage = [self getImageForPage:pageIndex];
	return [self getPageSnapshot:pageImage withPageIndex:pageIndex];
}


-(UIImage *)getPageSnapshot:(UIImage *)pageImage withPageIndex:(NSUInteger)pageIndex{
    
    UIGraphicsBeginImageContextWithOptions(onScreenPageView.bounds.size, NO, 0.0);
    
    offScreenPageView.drawingImageView.image = pageImage;
	
    [offScreenPageView applyTheme:[self getThemeForPage:pageIndex]];
    
	offScreenPageView.pageNumberLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NofN", @"%d of %d"), pageIndex +1, pageCurlView.numberOfPages];
	[offScreenPageView setDate:[self getCreationDateForPage:pageIndex]];
	
    NSArray *audios = [notebook annotationsForPage:[self getPageManagedObject:pageIndex] ofType:FTPDFAnnotationTypeAudio];
    NSArray *images = [notebook annotationsForPage:[self getPageManagedObject:pageIndex] ofType:FTPDFAnnotationTypeImage];
    [offScreenPageView addAnnotationsOfType:audios imageAnnotations:images];

	[offScreenPageView.layer renderInContext:UIGraphicsGetCurrentContext()];
	
    offScreenPageView.drawingImageView.image = nil; //remove the image to optimize memory
    
    [self renderTextLayerInCurrentContext:pageIndex];
    
    //[[self getUIImageForTextLayer:pageIndex] drawInRect:CGRectMake(0, 0, offScreenPageView.bounds.size.width, offScreenPageView.bounds.size.height-60)];
    
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}


#pragma mark Leaves View Delegate Method

- (void) leavesView:(LeavesView *)leavesView initiatedTurnToPageAtIndex:(NSUInteger)pageIndex{
	
    [self normalizeDeskMode];
    
    [coverContainerView bringSubviewToFront:pageCurlView];
    
	previousPageIndex = pageCurlView.currentPageIndex;
    
	if (writingView.isDirty) {
		self.currentPageImage = [writingView getUIImage];
	}
	
	if (pageIndex > pageCurlView.currentPageIndex) {
		//turn next page
		
		justTurnedNext = YES;
		if (!cacheNextPreviousPages) self.nextPageImage = [self getImageForPage:pageIndex];
        
        [pageCurlView setTopPageContentWithImage:[self getPageSnapshot:self.currentPageImage withPageIndex:pageIndex-1]];
		[pageCurlView applyTheme:[self getThemeForPage:pageIndex-1]];
        
        @synchronized(self.nextPageImage){
            onScreenPageView.drawingImageView.image = [self composeTextLayerOverPageImage:pageIndex pageImage:self.nextPageImage];
            NSArray *audios = [notebook annotationsForPage:[self getPageManagedObject:pageIndex] ofType:FTPDFAnnotationTypeAudio];
            NSArray *images = [notebook annotationsForPage:[self getPageManagedObject:pageIndex] ofType:FTPDFAnnotationTypeImage];

            [onScreenPageView addAnnotationsOfType:audios imageAnnotations:images];
        }
        
        onScreenPageView.pageNumberLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NofN", @"%d of %d"), pageIndex +1, pageCurlView.numberOfPages];
        [onScreenPageView setDate:[self getCreationDateForPage:pageIndex]];
        
        if (deskMode == kDeskModeText) {
        }
	}else {
		//turn previous page
		
		justTurnedNext = NO;
		if (!cacheNextPreviousPages) self.previousPageImage = [self getImageForPage:pageIndex];
        
        @synchronized(self.previousPageImage){
            [pageCurlView setTopPageContentWithImage:[self getPageSnapshot:self.previousPageImage withPageIndex:pageIndex]];
        }
        [pageCurlView applyTheme:[self getThemeForPage:pageIndex]];
        
        onScreenPageView.drawingImageView.image = [self composeTextLayerOverPageImage:pageIndex+1 pageImage:self.currentPageImage];
        
        NSArray *audios = [notebook annotationsForPage:[self getPageManagedObject:pageIndex+1] ofType:FTPDFAnnotationTypeAudio];
        NSArray *images = [notebook annotationsForPage:[self getPageManagedObject:pageIndex+1] ofType:FTPDFAnnotationTypeImage];
        [onScreenPageView addAnnotationsOfType:audios imageAnnotations:images];
	}
    
    
    //This block should be before the "onScreenPageView applyTheme" call becasue we are using
    //the theme value of onScreenPageView to apply to new pages
    if (writingView.isDirty) {
		[self saveImageForPage:previousPageIndex
                         image:self.currentPageImage
            backgroundSavePage:YES
       backgroundSaveThumbnail:YES
         onCompletion:nil];
        
        if (!cacheNextPreviousPages) self.currentPageImage = nil;
		writingView.isDirty = NO;
	}
    
    if (pageIndex > pageCurlView.currentPageIndex) {
        //turn next page
        paperThemeChangedWithPastPageTurn = [onScreenPageView applyTheme:[self getThemeForPage:pageIndex]];
    }
    
	writingView.hidden = YES;
	//onScreenPageView.hidden = YES;
    
    deskToolbarView.userInteractionEnabled = NO;
}



- (void) leavesView:(LeavesView *)leavesView willTurnToPageAtIndex:(NSUInteger)pageIndex{
	// No action
}

- (void) leavesView:(LeavesView *)leavesView didTurnToPageAtIndex:(NSUInteger)pageIndex{
	
    //NSLog(@"didTurnToPageAtIndex: %d", pageIndex+1);

    [pageCurlView setTopPageContentWithImage:nil];

    if (justTurnedNext) {
       
		if (cacheNextPreviousPages) @synchronized(self.previousPageImage) {self.previousPageImage = self.currentPageImage;}
        
       @synchronized(self.nextPageImage)  {self.currentPageImage = self.nextPageImage;}
       
        if (cacheNextPreviousPages) [self cacheNextPageImageWithIndex:pageIndex+1];
		if (!cacheNextPreviousPages) self.nextPageImage = nil;
       
	}else {
		
		if (cacheNextPreviousPages) @synchronized(self.nextPageImage) {self.nextPageImage = self.currentPageImage;}
		
        @synchronized(self.previousPageImage) {self.currentPageImage = self.previousPageImage;}
        
		if (cacheNextPreviousPages) [self cachePreviousPageImageWithIndex:pageIndex-1];
		if (!cacheNextPreviousPages) self.previousPageImage = nil;
        
        paperThemeChangedWithPastPageTurn = [onScreenPageView applyTheme:[self getThemeForPage:pageIndex]];
	}
    

    if (paperThemeChangedWithPastPageTurn) {
        //NSLog(@"Refreshing writingView background");
        
        [self updatePageCurlImage];
    }
    
    if (deskMode == kDeskModeText) {
    }else {
        [self putTextForPage:pageIndex];
    }
    [self refreshAnnotationsView];
    [writingView putUIImage:self.currentPageImage];

	[self getWritingPositionForPage:pageIndex];
	writingView.hidden = NO;
	
	if (zoomManagerView) {
		[self setZoomAreaPosition:[self getZoomAreaPositionForPage:pageIndex]];
	}else{
        if (self.alwaysInPortrait) [desktopView scrollRectToVisible:CGRectZero];
    }
	
	[onScreenPageView setDate:[self getCreationDateForPage:pageIndex]];
	
	[self refreshPageNumbers];
    
	onScreenPageView.hidden = NO;
    deskToolbarView.userInteractionEnabled = YES;
	
    [coverContainerView insertSubview:pageCurlView aboveSubview:onScreenPageView];
}


- (void) leavesViewNoPreviousPageTriggered:(LeavesView *)leavesView {
	SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
																		 message:NSLocalizedString(@"FirstPage", @"First page")
																		   style:kSmartMessageJustText];
	self.view.userInteractionEnabled = NO;
	[self.view addSubview:smartMessageView];
	[smartMessageView dismissAfterInterval:0.5 delegate:self];
}

- (void) leavesViewNoNextPageTriggered:(LeavesView *)leavesView {
	SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
																		 message:NSLocalizedString(@"LastPage", @"Last page")
																		   style:kSmartMessageJustText];
	self.view.userInteractionEnabled = NO;
	[self.view addSubview:smartMessageView];
	[smartMessageView dismissAfterInterval:0.5 delegate:self];
}

-(void) leavesViewCannotTurnPage:(LeavesView *)leavesView{
    
    //No action
}


#if FREE_VERSION

-(void)leavesViewTrialLimitReached:(LeavesView *)leavesView{
    [APP_DELEGATE showTrialLimitReachedMessage:@"Notebook Turn Page"];
}

#endif

#pragma mark Fetching and Saving Pages

-(void)saveImageForPage:(NSUInteger)page
                  image:(UIImage *)image
     backgroundSavePage:(BOOL)backgroundSavePage
backgroundSaveThumbnail:(BOOL)backgroundSaveThumbnail
           onCompletion:(GenericSuccessBlock)completion
{
	//Fetch the page the page
	FTNNotebookPage *pageManagedObject = [self getPageManagedObject:page];
	
	if (!pageManagedObject) {
        pageManagedObject = (FTNNotebookPage*)[self.notebook insertPageAtIndex:page];
        pageManagedObject.paperTheme = onScreenPageView.lastAppliedTheme;
        
        pageManagedObject.paperTheme = onScreenPageView.lastAppliedTheme;
        
		newPageCreationFlag = NO;
        self.pageCurlView.numberOfPages = self.notebook.pages.count+1;
        self.notebookShelfItem.numPages = [NSNumber numberWithInteger:self.notebook.pages.count];

        //***************************************************
        //Flurry Info
        //***************************************************
        NSDictionary *flurryInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithUnsignedInteger:self.notebook.pages.count], @"Pages",
                                        nil];
        [Flurry logEvent:@"Page Created" withParameters:flurryInfoDict];
        //***************************************************
        
        //***************************************************
        //Crashlytics Info
        //***************************************************
        
        CLSLog(@"Page Created");
        
        //***************************************************

        
	}
	
    pageManagedObject.pageContent = image;
    
    if (pageManagedObject.textEntries.count || [notebook annotationsForPage:pageManagedObject].count)
    {
        UIImage *thumbImage = [self compositePageImage:image pageAtIndex:page];
        [pageManagedObject setThumbnailImage:thumbImage];
    }else{
        UIImage *thumbnailImage = [image  imageByScalingProportionallyToSize:CGSizeMake(image.size.width/(4*[UIScreen mainScreen].scale), image.size.height/(4*[UIScreen mainScreen].scale))];
        [pageManagedObject setThumbnailImage:thumbnailImage];
    }
	
	pageManagedObject.lastUpdated = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
	pageManagedObject.writingPosition =  [NSNumber numberWithFloat:writingView.writingPosition];
	pageManagedObject.writingPositionLand =  [NSNumber numberWithFloat:writingView.writingPositionLanscape];
    pageManagedObject.writingPositionLandInverted =  [NSNumber numberWithFloat:writingView.writingPositionLanscapeInverted];
    
	if (zoomManagerView) {
		pageManagedObject.zoomPositionX = [NSNumber numberWithFloat:zoomManagerView.targetRect.origin.x];
		pageManagedObject.zoomPositionY = [NSNumber numberWithFloat:zoomManagerView.targetRect.origin.y];
	}
	
    self.notebookShelfItem.lastUpdated = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
    [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];

	[notebook saveWithCompletionHandler:^(BOOL success) {
        if(self.notebookShelfItem.enSyncEnabled)
        {
            [FTENPublishManager recordSyncLog:[NSString stringWithFormat:@"User triggered save of page (%ld of %lu) of notebook: %@", (long)(pageManagedObject.pageIndex.integerValue+1), (unsigned long)notebook.pages.count, self.notebookShelfItem.title]];
            [[FTENPublishManager sharedPublishManager] pageDidGetUpdated:pageManagedObject];
            
        }
        [[FTCloudBackUpManager sharedCloudBackUpManager] shelfItemDidGetUpdated:self.notebookShelfItem];
        if (completion)
        {
            completion(true);
        }
    }];


    [self.notebook turnPageToFault:pageManagedObject];
#ifdef DEBUG
    
	//ShelfItem integrity check
    
    NSSortDescriptor * sortByPageNumber = [[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES];
    NSArray * descriptors = [NSArray arrayWithObject:sortByPageNumber];
    NSArray *sortedPages = [notebook.pages sortedArrayUsingDescriptors:descriptors];
    BOOL checkPassed = YES;
    for (int i=0; i < [sortedPages count]; i++) {
        FTNNotebookPage *aPage = [sortedPages objectAtIndex:i];
        if (i != [aPage.pageIndex intValue]) {
            NSLog(@"ShelfItem integrity check failed :(");
            checkPassed = NO;
            break;
        }
    }
    
    if (checkPassed) {
        //NSLog(@"ShelfItem integrity check passed :)");
    }else{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                 message:@"ShelfItem integrity check failed :(" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:action];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
#endif 
    
}

-(void)cacheNextPageImageWithIndex:(NSUInteger)pageIndex{
    FTNNotebookPage *pageManagedObject = [self getPageManagedObject:pageIndex];
    
    if (pageManagedObject) {
        NSDictionary *backgroundSaveDict = [NSDictionary dictionaryWithObjectsAndKeys: 
                                            pageManagedObject, @"objectID",
                                            nil];
        [self performSelectorInBackground:@selector(backgroundLoadNextPageImages:) withObject:backgroundSaveDict];
    }else {
        @synchronized(self.nextPageImage) {self.nextPageImage = nil;}
    }
}

-(void)backgroundLoadNextPageImages:(NSDictionary *)backgroundSaveDict{
    
    @synchronized(self.nextPageImage) {
        
        @autoreleasepool {
            
            //[NSThread sleepForTimeInterval:4.5];
            FTNNotebookPage *pageObjectID = [backgroundSaveDict objectForKey:@"objectID"];
            self.nextPageImage = pageObjectID.pageContent;
        }
    }
}

-(void)cachePreviousPageImageWithIndex:(NSUInteger)pageIndex{
    FTNNotebookPage *pageManagedObject = [self getPageManagedObject:pageIndex];
    if (pageManagedObject) {
        NSDictionary *backgroundSaveDict = [NSDictionary dictionaryWithObjectsAndKeys: 
                                            pageManagedObject, @"objectID",
                                            nil];
        [self performSelectorInBackground:@selector(backgroundLoadPreviousPageImages:) withObject:backgroundSaveDict];
    }else {
        @synchronized(self.previousPageImage) {self.previousPageImage = nil;}
    }
}

-(void)backgroundLoadPreviousPageImages:(NSDictionary *)backgroundSaveDict{
    
    @synchronized(self.previousPageImage) {
        
        @autoreleasepool {
            
            //[NSThread sleepForTimeInterval:4.5];
            FTNNotebookPage *pageObjectID = [backgroundSaveDict objectForKey:@"objectID"];
            self.previousPageImage = pageObjectID.pageContent;
        }
    }
}

-(UIImage *)getImageForPage:(NSUInteger)page{
	
	//NSLog(@"getImageForPage: %d", page+1);
	
    
    
	if (page >= notebook.pages.count) {
		return nil;
	}
	
    @synchronized([DataServices sharedDataServices]){
        
        FTNNotebookPage *fetchedPage = [self getPageManagedObject:page];
        
        if (fetchedPage) {
            
            UIImage *imageToReturn = fetchedPage.pageContent;
            
            //Re-fault to optimize memory
           [notebook turnPageToFault:fetchedPage];

            //NSLog(@"Fetching page %d", page+1);
            //[imageToReturn saveImageToDocumentsFolder:[NSString stringWithFormat:@"Fetched Page%d.png",page+1]];
            
            return imageToReturn;
        }
	}
    
	return nil;
	
}


- (NSString *)getThemeForPage:(NSUInteger)page{
    
    if (page >= notebook.pages.count) {
		return self.notebookShelfItem.paperTheme;
	}
	
	FTNNotebookPage * fetchedPage = [self getPageManagedObject:page];
	
	if (fetchedPage) {
		NSString *paperThemeGUID = [fetchedPage.paperTheme copy];
		
		//Re-fault to optimize memory
      [notebook turnPageToFault:fetchedPage];

		return paperThemeGUID;
	}
	
	return self.notebookShelfItem.paperTheme;
}

-(UIImage *)getCurrentPageImageForSending{
	
    
    FTNNotebookPage * page = [self getPageManagedObject:pageCurlView.currentPageIndex];
    
    if (!page) {
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(onScreenPageView.bounds.size, NO, 0.0);
    
    offScreenPageView.drawingImageView.image = [self getImageForPage:pageCurlView.currentPageIndex];
    
    NSArray *audioANnotations = [notebook annotationsForPage:page ofType:FTPDFAnnotationTypeAudio];
    NSArray *imageANnotations = [notebook annotationsForPage:page ofType:FTPDFAnnotationTypeImage];
    [offScreenPageView addAnnotationsOfType:audioANnotations imageAnnotations:imageANnotations];
    
	offScreenPageView.pageNumberLabel.text = @"";
    offScreenPageView.notebookTitleLabel.text = @"";
	[offScreenPageView setDate:nil];
	
    [offScreenPageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    [[self getUIImageForTextLayer:pageCurlView.currentPageIndex] drawInRect:CGRectMake(0, 0, offScreenPageView.bounds.size.width, offScreenPageView.bounds.size.height-60)];
    
    offScreenPageView.drawingImageView.image = nil; //remove the image to optimize memory
    offScreenPageView.notebookTitleLabel.text = self.notebookShelfItem.title;
    
    [offScreenPageView clearAllAnnotations];
    
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}


-(void)getWritingPositionForPage:(NSUInteger)page{
	
	FTNNotebookPage * fetchedPage = [self getPageManagedObject:page];
	
	if (fetchedPage) {
        
        
        writingView.writingPosition = [fetchedPage.writingPosition floatValue];
        writingView.writingPositionLanscape = [fetchedPage.writingPositionLand floatValue];
        writingView.writingPositionLanscapeInverted = [fetchedPage.writingPositionLandInverted floatValue];
        [self writingPositionChanged];
        [notebook turnPageToFault:fetchedPage];
        return;
	}
	
    writingView.writingPosition = INITIAL_WRITING_POSITION;
    writingView.writingPositionLanscape = INITIAL_WRITING_POSITION_LAND;
    writingView.writingPositionLanscapeInverted = INITIAL_WRITING_POSITION_LAND;
	[self writingPositionChanged];
}

-(CGPoint) getZoomAreaPositionForPage:(NSUInteger)pageIndex{
	FTNNotebookPage * fetchedPage = [self getPageManagedObject:pageIndex];
	
	if (fetchedPage) {
		float x = [fetchedPage.zoomPositionX floatValue];
		float y = [fetchedPage.zoomPositionY floatValue];
        [notebook turnPageToFault:fetchedPage];

        if (x == 0.0 && y == 0.0) {
            return CGPointMake([self.notebookShelfItem.zoomMargin floatValue], 0);
        }
        
		return CGPointMake(x,y);
	}
	
	return CGPointMake([self.notebookShelfItem.zoomMargin floatValue], 0);
}

-(void) saveZoomPanelPosition{
	
	if (!zoomManagerView) {
		return;
	}
	
	FTNNotebookPage * fetchedPage = [self getPageManagedObject:pageCurlView.currentPageIndex];
	
	if (fetchedPage) {
		fetchedPage.zoomPositionX = [NSNumber numberWithFloat:zoomManagerView.targetRect.origin.x];
		fetchedPage.zoomPositionY = [NSNumber numberWithFloat:zoomManagerView.targetRect.origin.y];
		[notebook saveWithCompletionHandler:nil];
        [notebook turnPageToFault:fetchedPage];
    }
}


-(NSDate *) getCreationDateForPage:(NSUInteger)pageIndex{
	FTNNotebookPage * fetchedPage = [self getPageManagedObject:pageIndex];
	
	if (fetchedPage) {
		NSDate *creationDate =[NSDate dateWithTimeIntervalSinceReferenceDate:[fetchedPage.creationDate doubleValue]];
        [notebook turnPageToFault:fetchedPage];
        return creationDate;
	}
	
	return [NSDate date];
}

-(FTNNotebookPage *)getPageManagedObject:(NSUInteger)page{
    return (FTNNotebookPage *)[self.notebook pageWithIndex:page];
}


-(void)saveNotebookState:(BOOL)backgroundSave onCompletion:(GenericSuccessBlock)completion
{
    //Don't save when in finder becasue the desk may be in an inconsistant state
    //This fixes a few production bugs
    [self addPageIfNeeded];
    self.notebookShelfItem.currentPageIndex = [NSNumber numberWithInteger:pageCurlView.currentPageIndex];
    self.notebookShelfItem.numPages = [NSNumber numberWithInteger:self.notebook.pages.count];
    [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];
    
    [self.notebook updateDocumentShelfInfoFromShelfItem:self.notebookShelfItem];
    
    if (writingView.isDirty) {
        
        //NSLog(@"Image saved on closing");
        self.currentPageImage = [writingView getUIImage];
        [self saveImageForPage:pageCurlView.currentPageIndex
                         image:self.currentPageImage
            backgroundSavePage:backgroundSave
       backgroundSaveThumbnail:backgroundSave
         onCompletion:completion];
        writingView.isDirty = NO;
        if (zoomPanel) {
            [self saveZoomPanelPosition];
        }
    }
    else
    {
        [self.notebook saveWithCompletionHandler:completion];
    }
}

-(void)saveNotebookState:(BOOL)backgroundSave{
    [self saveNotebookState:backgroundSave onCompletion:nil];
}


-(void)addPageIfNeeded{
    
	if ( (pageCurlView.currentPageIndex == notebook.pages.count) && !newPageCreationFlag && writingView.isDirty)
    {
        [self addNewPage];
	}
}

- (void)addNewPage {
    pageCurlView.numberOfPages++;
    newPageCreationFlag = YES;
    [self refreshPageNumbers];
}

-(void)newPageDidGetInserted:(FTNPage*)page
{
    pageCurlView.numberOfPages++;
    self.nextPageImage = [self getImageForPage:page.pageIndex.integerValue];
    [pageCurlView jumpToNextPage];
}

#pragma mark Wiriting View Delegate Method

- (void)pointRegistered:(CGPoint)newPoint vertexType:(VertexType)vertexType{
	
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disableLongGesture) object:nil];
    if ((deskMode == kDeskModeEraser) && !putUpAlertIfEraserMovedOverImage) {
        putUpAlertIfEraserMovedOverImage = [self checkIfAnyImageAnnotationPresentAtPoint:newPoint];
    }
    //Autoscroll logic
    if (vertexType == kFirstVertex){
        
        if (!zoomPanel){
            pageCurlView.canTurnPage = NO;
        }
        
        if (zoomManagerView) {        
            if (autoscrollTimerSet) {
                
                [autoscrollTimer invalidate];
                autoscrollTimer = nil;
                //NSLog(@"autoscrollTimer Postponed");
            }
        }
        if(zoomPanel)
        {
            [zoomPanel stopPalmResetSliderMovement];
        }
    }
    
	if (vertexType == kLastVertex) {
		
        if (![self.notebookShelfItem.wristProtectionOn boolValue] && !zoomPanel) {
            [pageCurlView canTurnPageAfterAMoment];
        }
        
        
		//Create Page If Needed
		[self addPageIfNeeded];
		
        //Autoscroll logic
        if (zoomManagerView && ((deskMode == kDeskModePen) || (deskMode == kDeskModeMarker))) {
            
            if (autoscrollTimerSet) {
                autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                                   target:self 
                                                                 selector:@selector(zoomPanelPanRight) 
                                                                 userInfo:nil 
                                                                  repeats:NO];
                //NSLog(@"autoscrollTimer Rescheduled");
                return;
            }
            
            CGRect impactedRect = [zoomManagerView convertRect:writingView.impactedRect fromView:writingView];
            CGFloat maxX = CGRectGetMaxX(impactedRect);
            if (maxX > zoomManagerView.targetRect.origin.x + zoomManagerView.targetRect.size.width - (zoomPanel.zoomBordersView.autoscrollWidth/zoomPanel.zoomGLView.zoomFactor) + 5) {
                if (!autoscrollTimerSet) {
                    autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                                       target:self 
                                                                     selector:@selector(zoomPanelPanRight) 
                                                                     userInfo:nil 
                                                                      repeats:NO];
                    autoscrollTimerSet = YES;
                    //NSLog(@"autoscrollTimer Set");
                }
            }
            
        }
        if(zoomPanel)
        {
            [zoomPanel startPalmResetSliderMovement];
        }
        if ((deskMode == kDeskModeEraser) && putUpAlertIfEraserMovedOverImage) {
            [self showAlertPanelRegardingPhotoErase];
        }
        putUpAlertIfEraserMovedOverImage = NO;
	}

    else if(vertexType == kInterimVertex)
    {
        [self performSelector:@selector(disableLongGesture) withObject:nil afterDelay:self.longPressGesture.minimumPressDuration];
    }
}

- (void)currentStrokeCancelled
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disableLongGesture) object:nil];
    if (![self.notebookShelfItem.wristProtectionOn boolValue] && !zoomPanel) {
        [pageCurlView canTurnPageAfterAMoment];
    }
}

- (void)undoBufferStateChanged:(NSInteger)undoCount redoCount:(NSInteger)redoCount
{
    [deskToolbarView updateUndoButton];
    if (zoomPanel){
        [self refreshZoomButtonStates];
    }
}

- (void)writingPositionChanged{
	
    [UIView beginAnimations:nil context:NULL];
    
    UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation] forShelfItem:self.notebookShelfItem];
    
    [UIView commitAnimations];
}

- (void)externalScreenDetected{
    
    [self updateExternalDisplayAsNeeded];
    FTNNotebookPage * page = [self getPageManagedObject:self.pageCurlView.currentPageIndex];
}

#pragma mark -
#pragma mark Other Methods

-(void)canMoveToShelf:(completionBlock)block
{
    [FTNotebookUtils checkIfAudioIsPlayingShowMessage:NSLocalizedString(@"AudioRecoring_Message",@"") onCompletion:^(BOOL success) {
        if(block){
            block(success);
        }
    }];
}

-(void)backToShelfButtonAction
{
    [self canMoveToShelf:^(BOOL success) {
        if(success){
            [APP_DELEGATE logiRateEvent];
            
            //***************************************************
            //Flurry Info
            //***************************************************
            [Flurry endTimedEvent:@"Show Notebook" withParameters:nil];
            //***************************************************
            
            //***************************************************
            //Crashlytics Info
            //***************************************************
            
            CLSLog(@"Notebook close");
            
            //***************************************************
            
            if (!self.zoomPanel) {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:IS_ZOOM_TOOL_ACTIVE];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            //Pressure Stylus related
            [[FTStylusPenManager sharedInstance] unregisterView:self.writingView.zoomGLView setToDefault:NO];
            [[FTStylusPenManager sharedInstance] unregisterView:self.writingView setToDefault:NO];
            //[[FTStylusPenManager sharedInstance] unregisterView:self.pageCurlView setToDefault:NO];
            
            //    [[PressurePenEngine sharedPressurePenEngine] stop];
            [PressurePenEngine sharedPressurePenEngine].delegate = nil;
            
            [self resignFirstResponder];
            
            //Remove the search cache, if at all it exists
       //TOOD: Shelf     [[APP_DELEGATE searchCaches] removeObjectForKey:[[[self.notebookShelfItem objectID] URIRepresentation] absoluteString]];
            
            self.view.userInteractionEnabled = NO;
            [self normalizeDeskMode];
            
            [APP_DELEGATE setIsInverted:writingView.isInverted];
            [APP_DELEGATE setAlwaysInPortraitStatus:self.alwaysInPortrait];
            
            SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                                 message:NSLocalizedString(@"SavingNotebook", @"Saving Notebook")
                                                                                   style:kSmartMessageActivityIndicator];
            [self.view addSubview:smartMessageView];
            
            [self performSelector:@selector(delayedSwitch) withObject:nil afterDelay:0.001];
            if(self.notebookShelfItem.enSyncEnabled)
                [[FTENPublishManager sharedPublishManager] performSelector:@selector(startPublishing) withObject:nil afterDelay:1];
            NSString *filePath = self.notebookShelfItem.fileURL.path;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[FTCloudBackUpManager sharedCloudBackUpManager] startPublish];
                [[FTFileSizeGenerator sharedFileSizeGen] packageSizeAtPath:filePath fileSize:nil shouldUpdate:YES];
            });
            
        }
    }];
}

-(void) delayedSwitch{

   BOOL saveInBackgroun = NO;
    self.notebook.delegate = nil;
    [self.notebook markUnusedResourcesAsDeleted];
    [self saveNotebookState:saveInBackgroun onCompletion:^(BOOL success) {
        //***************************************************
        // Core Spotlight registration
        //***************************************************
        [[FTSearchIndexManager sharedManager] updateSearchIndex:self.notebookShelfItem completion:nil];
        //***************************************************
        
        [APP_DELEGATE switchToShelfAnimate:YES];
    }];
}

-(void)updateExternalDisplayAsNeeded{
    
}

-(void)shareButtonAction
{
    [self normalizeDeskMode];
    if (writingView.isDirty) {
        self.view.userInteractionEnabled = NO;
        
        SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                             message:NSLocalizedString(@"SavingNotebook", @"Saving Notebook")
                                                                               style:kSmartMessageActivityIndicator];
        [self.view addSubview:smartMessageView];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveNotebookState:false onCompletion:^(BOOL success) {
                self.view.userInteractionEnabled = true;
                [smartMessageView removeFromSuperview];
                [self showShareOptions];
            }];
        });
    }else {
        if (0 == notebook.pages.count) {
            SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                                 message:NSLocalizedString(@"NoPagesToShowInFinder", @"No pages to show in finder")
                                                                                   style:kSmartMessageJustText];
            self.view.userInteractionEnabled = NO;
            [self.view addSubview:smartMessageView];
            [smartMessageView dismissAfterInterval:1 delegate:self];
        }
        else {
            [self showShareOptions];
        }
    }

}
#pragma mark -
#pragma mark Zoom Methods 

-(void)zoomButtonAction{
	[self normalizeDeskMode];
	
	if (deskToolbarView.zoomButton.selected) {
		//Dismiss zoom mode
		
		[self dismissZoomMode];
        self.notebookShelfItem.zoomModeActive = [NSNumber numberWithBool:NO];
        [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];

        //***************************************************
        //Flurry Info
        //***************************************************
        [Flurry logEvent:@"Zoom Disabled" withParameters:nil];
        //***************************************************
        
        //***************************************************
        //Crashlytics Info
        //***************************************************
        
        CLSLog(@"Zoom Disabled");
        
        //***************************************************

        
		return;
	}
	
    //***************************************************
    //Flurry Info
    //***************************************************
    [Flurry logEvent:@"Zoom Enabled" withParameters:nil];
    //***************************************************
    
    //***************************************************
    //Crashlytics Info
    //***************************************************
    
    CLSLog(@"Zoom Enabled");
    
    //***************************************************

    
	//Initiate zoom mode
	//Make sure desk mode is pen or eraser
	if (deskMode != kDeskModePen && deskMode != kDeskModeMarker && deskMode != kDeskModeEraser) {
		[self switchMode:kDeskModePen];
	}
	
	[self initiateZoomMode];
    self.notebookShelfItem.zoomModeActive = [NSNumber numberWithBool:YES];
    [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];
    
}

-(void)initiateZoomMode{
	deskToolbarView.zoomButton.selected = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:FTAppDidEnterZoomMode object:nil];
	
	//release just in case
    [zoomManagerView removeFromSuperview];
	self.zoomManagerView = nil;
	
	zoomManagerView = [[ZoomManagerView alloc] initWithFrame:writingView.frame];
	[coverContainerView addSubview:zoomManagerView];
	zoomManagerView.delegate = self;
	zoomManagerView.lineHeight = [self.notebookShelfItem.zoomLineHeight intValue];
    zoomManagerView.zoomMargin = [self.notebookShelfItem.zoomMargin floatValue];
    
    [zoomPanel removeFromSuperview];
	self.zoomPanel = nil;
	
    CGFloat storedZoomHeight = [self.notebookShelfItem.zoomWindowHeight floatValue];
    storedZoomHeight += [[NSUserDefaults standardUserDefaults] integerForKey:@"ZOOM_PALM_REST_HEIGHT"];
	
	self.zoomPanel = [[ZoomPanel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - (storedZoomHeight + ZOOM_PANEL_TOP_MARGIN + ZOOM_PANEL_BOTTOM_MARGIN),
                                                                 self.view.bounds.size.width, storedZoomHeight + ZOOM_PANEL_TOP_MARGIN + ZOOM_PANEL_BOTTOM_MARGIN)];
	[self.view insertSubview:zoomPanel belowSubview:toolbarImageView];
    
    [self zoomPanelAdjustToOrientationChange:[[UIApplication sharedApplication] statusBarOrientation]];
    
	//[self.view addSubview:zoomPanel];
	zoomPanel.delegate = self;
	zoomPanel.zoomGLView.delegate = writingView;
	zoomPanel.zoomGLView.zoomFactor = [self.notebookShelfItem.zoomFactor floatValue]; //[[DataServices sharedDataServices].appDefaultsManageObject.currentZoomFactor floatValue];
    zoomPanel.zoomBordersView.autoscrollWidth = [self.notebookShelfItem.zoomAutoscrollWidth intValue];
	
    [self refreshPageNumbers];
    
	writingView.zoomGLView = zoomPanel.zoomGLView;
    [[FTStylusPenManager sharedInstance] unregisterView:self.writingView setToDefault:NO];
    //[[FTStylusPenManager sharedInstance] unregisterView:self.pageCurlView setToDefault:NO];

    [[FTStylusPenManager sharedInstance] registerView:writingView.zoomGLView delegate:(id)writingView.zoomGLView];

	
	zoomPanel.zoomBordersView.lineHeight = zoomManagerView.lineHeight * zoomPanel.zoomGLView.zoomFactor;
	
	
	//Disable wrist protection
	//deskToolbarView.wristProtectionButton.selected = NO;
	//deskToolbarView.wristProtectionButton.enabled = NO;
	writingView.wristProtectionOn = NO;
	//auxNavigator.hidden = YES;
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
	if ([self.notebookShelfItem.wristProtectionOn boolValue]) {
		[zoomPanel setWristProtection:YES];
	}
	
	if (deskMode == kDeskModeEraser) {
		writingView.brushWidth = [[DataServices sharedDataServices].appDefaultsManageObject.currentEraserSize floatValue]/zoomPanel.zoomGLView.zoomFactor;
	}
	
	
	[self setZoomAreaPosition:[self getZoomAreaPositionForPage:pageCurlView.currentPageIndex]];
    desktopView.accessoryHeight = zoomPanel.frame.size.height;
	[self refreshZoomButtonStates];
    
    [zoomPanel selectAppopriateZoomTool:NO];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:IS_ZOOM_TOOL_ACTIVE]) {
        RKPenType penType = [[NSUserDefaults standardUserDefaults] integerForKey:ACTIVE_ZOOM_TOOL];
        [self zoomPanelColorSwatchSelected:[[PenDefaults sharedPenDefaults] getSelectedZoomSwatchColorForPenType:penType]
                                   penSize:[[PenDefaults sharedPenDefaults] getSelectedZoomSwatchPenSizeForPenType:penType]
                                forPenType:penType];
    }
    
    zoomPanel.zoomGLView.auxiliaryInputAvailable = NO;

    FTNNotebookPage * page = [self getPageManagedObject:self.pageCurlView.currentPageIndex];
}

-(void)zoomPanelAdjustToOrientationChange:(UIInterfaceOrientation)interfaceOrientation{

    if (self.alwaysInPortrait)
    {
        zoomPanel.frame = CGRectMake(0, self.view.bounds.size.height - zoomPanel.frame.size.height, self.view.bounds.size.width, zoomPanel.frame.size.height);
        [self zoomPanelContentViewAdjustToOrientationChange:UIInterfaceOrientationPortrait];
    }
    else
    {
        if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
        {
            zoomPanel.frame = CGRectMake(0, self.view.bounds.size.height - zoomPanel.frame.size.height, self.view.bounds.size.width, zoomPanel.frame.size.height);
        }
        else
        {
            zoomPanel.frame = CGRectMake(44, self.view.bounds.size.height - zoomPanel.frame.size.height, self.view.bounds.size.width - 44, zoomPanel.frame.size.height);
        }
        [self zoomPanelContentViewAdjustToOrientationChange:[FTNotebookUtils notebookLayoutOrientationForOrientation:interfaceOrientation forShelfItem:self.notebookShelfItem]];
    }

    zoomManagerView.frame = writingView.frame;
    
    zoomPanel.zoomGLView.isLandscape = writingView.isLandscape;
    zoomPanel.zoomGLView.isInverted = writingView.isInverted;
    
    [self zoomPanelZoomAreaChanged];
	
	[desktopView scrollRectToVisible:CGRectInset(zoomManagerView.targetRect, 0, -10)];
}

-(void)zoomPanelContentViewAdjustToOrientationChange:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
    {
        zoomPanel.zoomGLView.transform = CGAffineTransformMakeRotation(0);
        zoomManagerView.transform = CGAffineTransformMakeRotation(0);
    }
    else
    {
        if(writingView.isInverted)
        {
            zoomPanel.zoomGLView.transform = CGAffineTransformMakeRotation(M_PI * -.5);
            zoomManagerView.transform = CGAffineTransformMakeRotation(M_PI * .5);
        }
        else
        {
            zoomPanel.zoomGLView.transform = CGAffineTransformMakeRotation(M_PI * .5);
            zoomManagerView.transform = CGAffineTransformMakeRotation(M_PI * -.5);
        }
    }
}

-(void)zoomPanelZoomFactorChangeRequested:(CGFloat)newZoomFactor{
	
	zoomPanel.zoomGLView.zoomFactor = newZoomFactor;
	zoomPanel.zoomBordersView.lineHeight = zoomManagerView.lineHeight * zoomPanel.zoomGLView.zoomFactor;
	[zoomPanel setNeedsLayout];
	
	//[DataServices sharedDataServices].appDefaultsManageObject.currentZoomFactor = [NSNumber numberWithFloat:zoomPanel.zoomGLView.zoomFactor];
    self.notebookShelfItem.zoomFactor = [NSNumber numberWithFloat:zoomPanel.zoomGLView.zoomFactor];
    [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];

	[self zoomPanelZoomAreaChanged];
    
}

-(void)zoomPanelZoomAreaChanged{
	//Setup the initial zoom rect
	
    CGFloat newX = MIN(zoomManagerView.targetRect.origin.x, 
					   zoomManagerView.bounds.size.width - zoomPanel.zoomGLView.frame.size.width/zoomPanel.zoomGLView.zoomFactor);
	
	
	CGFloat newY = MIN(zoomManagerView.targetRect.origin.y, 
					   zoomManagerView.bounds.size.height - zoomManagerView.lineHeight);
	
	CGRect tempRect = CGRectIntegral(CGRectMake(newX, newY, 
                                                zoomPanel.zoomGLView.frame.size.width/zoomPanel.zoomGLView.zoomFactor, 
                                                zoomPanel.zoomGLView.frame.size.height/zoomPanel.zoomGLView.zoomFactor));
    
    if (!CGRectEqualToRect(tempRect, zoomManagerView.targetRect))
    {
        if(applicationEnteredBackground)
            publishPausedDueToBackground = YES;
        
        zoomManagerView.targetRect = tempRect;
        writingView.currentZoomRect = [writingView convertRect:tempRect fromView:zoomManagerView];
        
        [writingView performSelector:@selector(publishCanvas) withObject:nil afterDelay:0.0];
        
        desktopView.accessoryHeight = zoomPanel.frame.size.height;
        
        [desktopView scrollRectToVisible:CGRectInset(zoomManagerView.targetRect, 0, -10)];
    }
}

-(void)zoomPanelLineHeightChanged{
	zoomManagerView.lineHeight = [self.notebookShelfItem.zoomLineHeight intValue]; //[[DataServices sharedDataServices].appDefaultsManageObject.currentZoomLineHeight intValue];
	zoomPanel.zoomBordersView.lineHeight = zoomManagerView.lineHeight * zoomPanel.zoomGLView.zoomFactor;
	[self zoomPanelZoomAreaChanged];
	[zoomPanel setWristProtection:[self.notebookShelfItem.wristProtectionOn boolValue]];
	//[zoomManagerView setNeedsDisplay];
}

-(void)zoomPanelUndoTapped{
    
    [self performSelector:@selector(undoButtonAction)];
    [self refreshZoomButtonStates];
}

-(void)zoomPanelRedoTapped{
    [self performSelector:@selector(redoButtonAction)];
    [self refreshZoomButtonStates];
    
}

-(void)zoomPanelColorSwatchSelected:(UIColor *)color
                            penSize:(NSUInteger)penSize
                         forPenType:(RKPenType)penType
{
    if (penType == kPenTypeHighlighter) {
        
        if(deskMode != kDeskModeMarker)
            [self switchMode:kDeskModeMarker];

        [writingView setWritingMode:kMarkerMode];
        [writingView setColor:color];
        
    }else{
        
        if (deskMode != kDeskModePen) [self switchMode:kDeskModePen];
        
        switch (penType) {
            case kPenTypePen:
                [writingView setWritingMode:kPenMode];
                break;
            case kPenTypePencil:
                [writingView setWritingMode:kPencilMode];
                break;
            case kPenTypeCalligraphy:
                [writingView setWritingMode:kCalligraphyMode];
                break;
            default:
                [writingView setWritingMode:kPenMode];
                break;
        }
        
        [writingView setColor:color];
    }
    
    writingView.brushWidth = penSize;
    self.deskToolbarView.penButton.selected     = NO;
    self.deskToolbarView.markerButton.selected  = NO;
}

/*
-(void)switchToMainToobar{
    
    
    if (deskMode == kDeskModeEraser) {
        deskToolbarView.eraserButton.selected = YES;
        return;
    }
    
    RKPenType penType = [[PenDefaults sharedPenDefaults] currentPenType];
    
    if (penType == kPenTypeHighlighter) {
        
        UIColor *color = [[PenDefaults sharedPenDefaults] getColorForCurrentHighlighter];
        
        if(deskMode != kDeskModeMarker)
            [self switchMode:kDeskModeMarker];
        
        [writingView setColor:color];
        writingView.brushWidth = [[PenDefaults sharedPenDefaults] getHighlighterSize];
        deskToolbarView.markerButton.selected = YES;
        [deskToolbarView refreshSelectedMarkerColor];
        
    }else if (penType == kPenTypePen ||
              penType == kPenTypePencil ||
              penType == kPenTypeCalligraphy){
        
        [self setCurrentPenWritingMode];
        
        deskToolbarView.penButton.selected = YES;
        [deskToolbarView refreshSelectedPenColor];
    }
    
}
*/

-(void)zoomPanelEraserTapped{
    //if (zoomPanel.erasorButton.selected) return;
    
    [self performSelector:@selector(eraserButtonAction)];
    [self refreshZoomButtonStates];
    
}

-(void)zoomPanelCloseButtonTapped{
    [self performSelector:@selector(zoomButtonAction)];
}

-(void)zoomPanelPrevPageRequested{
	[pageCurlView jumpToPreviousPage];
}

-(void)zoomPanelNextPageRequested{
	[pageCurlView jumpToNextPage];
}


-(void)zoomPanelPanLeft{
	
	CGFloat newX, newY;
    
	if (zoomManagerView.targetRect.origin.x < 5 + zoomManagerView.zoomMargin && zoomManagerView.targetRect.origin.y > 5 ) {
		
		newX =   zoomManagerView.bounds.size.width -zoomManagerView.targetRect.size.width;
		newY = MAX(zoomManagerView.targetRect.origin.y - zoomManagerView.lineHeight, 0);
		
	}else {
        
        
        CGFloat minX;
        
        if (zoomManagerView.bounds.size.width - zoomManagerView.zoomMargin > zoomManagerView.targetRect.size.width) {
            minX = zoomManagerView.zoomMargin;
        }else{
            minX = zoomManagerView.bounds.size.width - zoomManagerView.targetRect.size.width;
        }
        
		newX = MAX(zoomManagerView.targetRect.origin.x - zoomManagerView.targetRect.size.width*0.8, minX);
		newY = zoomManagerView.targetRect.origin.y;
	}
	
    CGRect tempRect = CGRectMake(newX, newY, 
                                 zoomManagerView.targetRect.size.width, 
                                 zoomManagerView.targetRect.size.height);
    
    zoomManagerView.targetRect = tempRect;
    writingView.currentZoomRect = [writingView convertRect:tempRect fromView:zoomManagerView];
	
	[writingView publishCanvas];
	[zoomManagerView setNeedsDisplay];
	[zoomPanel setNeedsDisplay];
	
	[desktopView scrollRectToVisible:CGRectInset(zoomManagerView.targetRect, 0, -10)];
    
    zoomPanel.zoomGLView.didWriteAfterLastMove = NO;
    writingView.impactedRect = CGRectNull;
    
}

-(void)zoomPanelPanRight{
    
    [autoscrollTimer invalidate];
    autoscrollTimer = nil;
    autoscrollTimerSet = NO;
    
    CGFloat offsetX = zoomManagerView.targetRect.size.width;
    
    if (zoomPanel.zoomGLView.didWriteAfterLastMove) {
        CGRect impactedRect = [zoomManagerView convertRect:writingView.impactedRect fromView:writingView];
        CGFloat maxX = CGRectGetMaxX(impactedRect);
        offsetX = MAX(maxX - zoomManagerView.targetRect.origin.x, 0);
    }
    
	if (zoomManagerView.targetRect.origin.x + zoomManagerView.targetRect.size.width + 5 > zoomManagerView.bounds.size.width) {
		
		if (zoomManagerView.bounds.size.height - zoomManagerView.lineHeight > zoomManagerView.targetRect.origin.y + 5) {
			[self zoomPanelPanNewLine];
			return;
		}
	}
	
	CGFloat newX = MIN(zoomManagerView.targetRect.origin.x + offsetX*0.8, zoomManagerView.bounds.size.width - zoomManagerView.targetRect.size.width);
	
	CGFloat newY = zoomManagerView.targetRect.origin.y;
	
	CGRect tempRect = CGRectMake(newX, newY, 
                                 zoomManagerView.targetRect.size.width, 
                                 zoomManagerView.targetRect.size.height);
    
    zoomManagerView.targetRect = tempRect;
    writingView.currentZoomRect = [writingView convertRect:tempRect fromView:zoomManagerView];
	
	[writingView publishCanvas];
	[zoomManagerView setNeedsDisplay];
	[zoomPanel setNeedsDisplay];
	
	[desktopView scrollRectToVisible:CGRectInset(zoomManagerView.targetRect, 0, -10)];
	
    zoomPanel.zoomGLView.didWriteAfterLastMove = NO;
    writingView.impactedRect = CGRectNull;
}

-(void)zoomPanelPanNewLine{
	
    CGFloat newX;
    
    if (zoomManagerView.bounds.size.width - zoomManagerView.zoomMargin > zoomManagerView.targetRect.size.width) {
        newX = zoomManagerView.zoomMargin;
    }else{
        newX = zoomManagerView.bounds.size.width - zoomManagerView.targetRect.size.width;
    }
    
	CGFloat newY = MIN(zoomManagerView.targetRect.origin.y + zoomManagerView.lineHeight, zoomManagerView.bounds.size.height - zoomManagerView.lineHeight);
	
	CGRect tempRect = CGRectMake(newX, newY, 
                                 zoomManagerView.targetRect.size.width, 
                                 zoomManagerView.targetRect.size.height);
    
    zoomManagerView.targetRect = tempRect;
    writingView.currentZoomRect = [writingView convertRect:tempRect fromView:zoomManagerView];
	
	[writingView publishCanvas];
	[zoomManagerView setNeedsDisplay];
	[zoomPanel setNeedsDisplay];
	
	[desktopView scrollRectToVisible:CGRectInset(zoomManagerView.targetRect, 0, -10)];
    
    zoomPanel.zoomGLView.didWriteAfterLastMove = NO;
    writingView.impactedRect = CGRectNull;
}

-(void)zoomPanelAutoscrollWidthChanged:(int)newAutoscrollWidth{
    self.notebookShelfItem.zoomAutoscrollWidth = [NSNumber numberWithInt:newAutoscrollWidth];
    [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];
}

-(BOOL)zoomPanelTouches:(RKZoomPanelSide)whichSide{
    
	switch (whichSide) {
		case kZoomPanelLeftSide:
			
			if (zoomManagerView.targetRect.origin.x < 3)
				return YES;
			
			break;
		case kZoomPanelRightSide:
			if (zoomManagerView.targetRect.origin.x > zoomManagerView.bounds.size.width - zoomManagerView.targetRect.size.width - 3)
				return YES;
			
			break;
		case kZoomPanelTopSide:
			if (zoomManagerView.targetRect.origin.y < 3)
				return YES;
			
			break;
		case kZoomPanelBottomSide:
			if (zoomManagerView.targetRect.origin.y > zoomManagerView.bounds.size.height - zoomManagerView.targetRect.size.height - 3)
				return YES;
			
			break;
	}
	
	return NO;
}

-(void)zoomManagerRectMoved{
	
    writingView.currentZoomRect = [writingView convertRect:zoomManagerView.targetRect fromView:zoomManagerView];
	[writingView performSelector:@selector(publishCanvas) withObject:nil afterDelay:0.0];
	
	[desktopView scrollRectToVisible:CGRectInset(zoomManagerView.targetRect, 0, -10)];
	[zoomPanel setNeedsDisplay];
    
    zoomPanel.zoomGLView.didWriteAfterLastMove = NO;
    writingView.impactedRect = CGRectNull;
}

-(void)zoomManagerRectSized{
	
	zoomPanel.zoomGLView.zoomFactor = zoomPanel.zoomGLView.frame.size.width / zoomManagerView.targetRect.size.width;
	
	zoomPanel.zoomGLView.zoomFactor = CLAMP(zoomPanel.zoomGLView.zoomFactor, 1.3,3.0);
    
    //NSLog(@"zoomManagerRectSized: %f", zoomPanel.zoomGLView.zoomFactor);
    
    //[DataServices sharedDataServices].appDefaultsManageObject.currentZoomFactor = [NSNumber numberWithFloat:zoomPanel.zoomGLView.zoomFactor];
    self.notebookShelfItem.zoomFactor = [NSNumber numberWithFloat:zoomPanel.zoomGLView.zoomFactor];
    [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];

	zoomPanel.zoomBordersView.lineHeight = zoomManagerView.lineHeight * zoomPanel.zoomGLView.zoomFactor;
	[zoomPanel setNeedsLayout];
	[self zoomPanelZoomAreaChanged];
    
    zoomPanel.zoomGLView.didWriteAfterLastMove = NO;
    writingView.impactedRect = CGRectNull;
}

-(void)zoomManagerMarginAdjusted{
    self.notebookShelfItem.zoomMargin = [NSNumber numberWithFloat:zoomManagerView.zoomMargin];
    [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];
}

-(void)setZoomAreaPosition:(CGPoint)newPosition{
	
	zoomManagerView.targetRect = CGRectIntegral( CGRectMake(0, 0, 
															zoomPanel.zoomGLView.frame.size.width/zoomPanel.zoomGLView.zoomFactor, 
															zoomPanel.zoomGLView.frame.size.height/zoomPanel.zoomGLView.zoomFactor));
	
	CGFloat newX = MIN(newPosition.x, zoomManagerView.bounds.size.width - zoomManagerView.targetRect.size.width);
	CGFloat newY = MIN(newPosition.y, zoomManagerView.bounds.size.height - zoomManagerView.lineHeight);
	
	CGRect tempRect = CGRectMake(newX, newY, 
                                 zoomManagerView.targetRect.size.width, 
                                 zoomManagerView.targetRect.size.height);
    
    zoomManagerView.targetRect = tempRect;
    writingView.currentZoomRect = [writingView convertRect:tempRect fromView:zoomManagerView];
	
	[writingView publishCanvas];
	[zoomManagerView setNeedsDisplay];
	[zoomPanel setNeedsDisplay];
	
	[desktopView scrollRectToVisible:CGRectInset(zoomManagerView.targetRect, 0, -10)];
    
    zoomPanel.zoomGLView.didWriteAfterLastMove = NO;
    writingView.impactedRect = CGRectNull;
}


-(void)zoomManagerRequestsScroll:(CGFloat)scrollOffset{
	[desktopView scrollBy:scrollOffset];
}

-(void)refreshZoomButtonStates
{
    zoomPanel.undoButton.enabled = [self canUndo];
    zoomPanel.redoButton.enabled = [self canRedo];
    zoomPanel.erasorButton.selected = deskToolbarView.eraserButton.selected;
}

-(void)zoomPanelHeightChanged{
    //[DataServices sharedDataServices].appDefaultsManageObject.currentZoomHeight = [NSNumber numberWithInt:zoomPanel.zoomGLView.frame.size.height];
    self.notebookShelfItem.zoomWindowHeight = [NSNumber numberWithInt:zoomPanel.zoomGLView.frame.size.height];
    [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];
}


-(void)dismissZoomMode{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FTAppDidEXitZoomMode object:nil];
    [[FTStylusPenManager sharedInstance] unregisterView:self.writingView.zoomGLView setToDefault:NO];

    //[[FTStylusPenManager sharedInstance] registerView:self.pageCurlView delegate:(id)self.writingView];
    [[FTStylusPenManager sharedInstance] registerView:self.writingView delegate:(id)self.writingView];

	
	[self saveZoomPanelPosition];
	
	deskToolbarView.zoomButton.selected = NO;
	desktopView.accessoryHeight = 0.0;
	
	//Enable wrist protection if needed
	//deskToolbarView.wristProtectionButton.enabled = YES;
	
	if ([self.notebookShelfItem.wristProtectionOn boolValue]) {
		
		//deskToolbarView.wristProtectionButton.selected = YES;
		writingView.wristProtectionOn = YES;
        //auxNavigator.hidden = NO;
		
	}
    
	if (deskMode == kDeskModeEraser) {
		writingView.brushWidth = [[DataServices sharedDataServices].appDefaultsManageObject.currentEraserSize floatValue];
	}
	
	writingView.zoomGLView = nil;
	
	//remove
	[zoomManagerView removeFromSuperview];
	self.zoomManagerView = nil;
	
	[zoomPanel removeFromSuperview];
    

	self.zoomPanel = nil;
    
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

-(void)zoomPanelPalmRestHeightChanged:(int)newPalmRestHeight{
    
    desktopView.accessoryHeight = zoomPanel.frame.size.height;
	[desktopView scrollRectToVisible:CGRectInset(zoomManagerView.targetRect, 0, -10)];
}

#pragma mark -
#pragma mark Text Input Methods 


-(void) textButtonAction{
    
    if (deskMode == kDeskModeText) {
        return;
    }
    
	[self normalizeDeskMode];
	
	[self switchMode:kDeskModeText];
    
    [self showTextFunctionHintIfNeeded];
    
}

-(void)textPlacementViewRequestsScroll:(CGFloat)scrollOffset{
	[desktopView scrollBy:scrollOffset];
}

-(void)textPlacementViewRequestsTextboxToVisible{
	
	[self performSelector:@selector(bringTextboxToVisible) withObject:nil afterDelay:0.5];
    
}

-(void)textPlacementViewRequestsRectToVisibile:(CGRect)targetRect{
	[desktopView scrollRectToVisible:targetRect];
}

-(void)bringTextboxToVisible{
}

-(CGFloat)textPlacementGetOptimalFontSizeForCurrentPage:(NSString *)fontName{
    
    return 0;
}

-(void)textPlacementFontSizeSetToOptimal:(CGFloat)optimalFontSize{
    
    if ([self.view viewWithTag:99999]) {
        return;
    }
    
    SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                         message:[NSString stringWithFormat:NSLocalizedString(@"FontSizeSetToLineHeight", @"Font size set to %d to match line height of the paper."), (int)optimalFontSize]
                                                                           style:kSmartMessageJustText];
    //Do the disable the view because the text view is in editing mode
    //self.view.userInteractionEnabled = NO;
    smartMessageView.center = CGPointMake(smartMessageView.center.x, smartMessageView.center.y - 100);
    [self.view addSubview:smartMessageView];
    smartMessageView.tag = 99999;
    [smartMessageView dismissAfterInterval:2 delegate:self];
}

-(id)textPlacementCreateNewTextEntry{
    
    //Fetch the page the page
    
    FTNNotebookPage * pageManagedObject = [self getPageManagedObject:pageCurlView.currentPageIndex];
	
	if (!pageManagedObject) {
		//Add the page if it does not exist
        self.currentPageImage = [writingView getUIImage];
        [self saveImageForPage:pageCurlView.currentPageIndex
                         image:self.currentPageImage
            backgroundSavePage:YES
       backgroundSaveThumbnail:YES
         onCompletion:nil];
        
        writingView.isDirty = NO;
        newPageCreationFlag = NO;
        pageCurlView.numberOfPages = notebook.pages.count+1;
        [self refreshPageNumbers];
        
        pageManagedObject = [self getPageManagedObject:pageCurlView.currentPageIndex];
    }
    
    //***************************************************
    //Flurry Info
    //***************************************************
    [Flurry logEvent:@"Textbox Created" withParameters:nil];
    //***************************************************
    
    //***************************************************
    //Crashlytics Info
    //***************************************************
    
    CLSLog(@"Textbox Created");
    
    //***************************************************
    return nil;
}

-(void)textPlacementTextEntriesReplaced{
    [self updateExternalDisplayAsNeeded];
}

-(void)putTextForPage:(NSUInteger)pageIndex{
    FTNNotebookPage * pageManagedObject = [self getPageManagedObject:pageIndex];
    
	if (pageManagedObject) {
        
        if (pageManagedObject.textEntries.count == 0) {
            writingView.hasText = NO;
        }else{
            writingView.hasText = YES;
            [writingView setTextLayerImage:[self getUIImageForTextLayer:pageCurlView.currentPageIndex]];
        }
    }else{
        writingView.hasText = NO;
    }
}

-(void)textPlacementTextEntryChanged{
    //This is hack to mark for saving
    writingView.isDirty = YES;   
    //NSLog(@"textPlacementTextEntryChanged");
    
    [self updateExternalDisplayAsNeeded];
}

/*
 -(void)textPlacementTextEntrySaved{
 if (writingView.extGLView) {
 writingView.hasText = YES;
 [writingView setTextLayerImage:[self getUIImageForTextLayer:pageCurlView.currentPageIndex]];
 [writingView publishCanvas];
 }
 }
 */

-(UIImage *)getUIImageForTextLayer:(NSUInteger)pageIndex{
    FTNNotebookPage * pageManagedObject = [self getPageManagedObject:pageIndex];
    
    //NSLog(@"Generating text layer for page: %d", pageIndex + 1);
    
    if (pageManagedObject) {
        
        if (pageManagedObject.textEntries.count == 0) {
            return nil;
        }
        
        UIGraphicsBeginImageContextWithOptions(writingView.bounds.size, NO, 0.0);
        
        //CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0f, writingView.bounds.size.height);
        //CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0f, -1.0f);
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        //[newImage performSelector:@selector(saveImageToDocumentsFolder:) withObject:@"TextLayerImage.png" afterDelay:1.0];
        
        return newImage;
        
    }
    
    return nil;
    
}

-(UIImage *)composeTextLayerOverPageImage:(NSUInteger)pageIndex pageImage:(UIImage *)pageImage{
    
    FTNNotebookPage * pageManagedObject = [self getPageManagedObject:pageIndex];
    
    if (pageManagedObject) {
        
        if (pageManagedObject.textEntries.count == 0) {
            return pageImage;
        }
        
        UIGraphicsBeginImageContextWithOptions(writingView.bounds.size, NO, 0.0);
        
        [pageImage drawInRect:writingView.bounds];
        
        [self renderTextLayerInCurrentContext:pageIndex];
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
    
    return pageImage;
}

-(UIImage *)composeTextLayerOverPageForThumbnail:(NSUInteger)pageIndex pageImage:(UIImage *)pageImage{
    
    CGRect rect = CGRectMake(0, 0, pageImage.size.width/4.0, pageImage.size.height/4.0);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1.0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    
    [pageImage drawInRect:rect];
    [[self getUIImageForTextLayer:pageIndex] drawInRect:rect];
     
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;

}

-(void)renderTextLayerInCurrentContext:(NSUInteger)pageIndex{
    
    FTNNotebookPage * pageManagedObject = [self getPageManagedObject:pageIndex];
    
    //NSLog(@"Generating text layer for page: %d", pageIndex + 1);
    
    if (pageManagedObject) {
        
        if (pageManagedObject.textEntries.count == 0) {
            return;
        }
        
    }
}

-(UIImage *)getUIImageForTextLayer1:(NSUInteger)pageIndex{
    FTNNotebookPage * pageManagedObject = [self getPageManagedObject:pageIndex];
    
    //NSLog(@"Generating text layer for page: %d", pageIndex + 1);
    
    if (pageManagedObject) {
        
        if (pageManagedObject.textEntries.count == 0) {
            return nil;
        }
        
        UIGraphicsBeginImageContextWithOptions(writingView.bounds.size, NO, 0.0);
        
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0f, writingView.bounds.size.height);
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0f, -1.0f);
        
        for (id<TextEntryProtocol> textEntry in pageManagedObject.textEntries) {
            
            if ([textEntry.isLandscape intValue]) {
                if ([textEntry.isInverted intValue]) {
                    CGContextRotateCTM(UIGraphicsGetCurrentContext(), M_PI * .5);
                }else{
                    CGContextRotateCTM(UIGraphicsGetCurrentContext(), M_PI * -.5);
                } 
            }
            
            
            CGRect targetRect = CGRectInset(CGRectMake([textEntry.x floatValue], [textEntry.y floatValue], [textEntry.width floatValue], [textEntry.height floatValue]),8,9);
            
            UIFont *targetFont = [UIFont fontWithName:textEntry.font size:[textEntry.pointSize floatValue]];
            
            //adjustment
            //targetRect = CGRectIntegral(CGRectMake(targetRect.origin.x, targetRect.origin.y+(0.023 * targetFont.ascender), targetRect.size.width, targetRect.size.height));
            
            
            //Show the rect for testing
            /*
             CGRect targetRect1 = CGRectInset(CGRectMake([textEntry.x floatValue], [textEntry.y floatValue], [textEntry.width floatValue], [textEntry.height floatValue]),0,0);
             [[UIColor lightGrayColor] setFill];
             CGContextAddRect(UIGraphicsGetCurrentContext(), targetRect1);
             CGContextFillPath(UIGraphicsGetCurrentContext());
             */
            
            [UIColorFromRGB([textEntry.textColor intValue]) setFill];
            
            [textEntry.text drawStringInRect:targetRect
                                    withFont:targetFont
                               lineBreakMode:NSLineBreakByWordWrapping
                                   alignment:[textEntry.textAlignment intValue]];
            
            
            if ([textEntry.isLandscape intValue]) {
                if ([textEntry.isInverted intValue]) {
                    CGContextRotateCTM(UIGraphicsGetCurrentContext(), M_PI * -.5);
                }else{
                    CGContextRotateCTM(UIGraphicsGetCurrentContext(), M_PI * .5);
                } 
            }
            
        }
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return newImage ;
        
    }
    
    return nil;
    
}

-(void)showTextFunctionHintIfNeeded{
    
#if SHOW_TEXT_HINT
    if(![[DataServices sharedDataServices].appDefaultsManageObject.textFunctionHint boolValue])
        return;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Hint", @"HINT") message:NSLocalizedString(@"TextToolHint", @"Double-tap anywhere...") preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"DontShowHintAgain", @"Don't Show") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [DataServices sharedDataServices].appDefaultsManageObject.textFunctionHint = [NSNumber numberWithBool:NO];
        [APP_DELEGATE commitDataChanges];
    }];
    [alertController addAction:action];
    
    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:otherAction];

    [self presentViewController:alertController animated:YES completion:nil];
#endif
    
}

#pragma mark -
#pragma mark Quick Page Navigation Popover

-(void)performQuickLookButtonAction:(UIButton *)sender
{
    [self normalizeDeskMode];
	
    if (writingView.isDirty) {
        self.view.userInteractionEnabled = NO;
        
        SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                             message:NSLocalizedString(@"SavingNotebook", @"Saving Notebook")
                                                                               style:kSmartMessageActivityIndicator];
        smartMessageView.tag = 125453;
        [self.view addSubview:smartMessageView];
        
        [self performSelector:@selector(delayedQuickLookAction:) withObject:sender afterDelay:0.001];
    }else {
        [self performSelector:@selector(delayedQuickLookAction:) withObject:sender];
    }

}

-(void)quickLookButtonAction:(UIButton *)sender{
    
    //tags set to buttons
    //Desk: 111
    //Aux Nav: 222
    //Zoom Panel: 333
    
    //Do not show the popover if in-appropriate button is tapped
    if (zoomPanel) {
        if (sender.tag != 333) return;
    }else{
        if (sender.tag != 111) return;
        
        if (!pageCurlView.canTurnPage) return;
        
    }
    
    if ((sender.tag == 111) && ([[PressurePenEngine sharedPressurePenEngine] pressurePenWristProtectionActive])) {
        return;
    }
    [self performQuickLookButtonAction:sender];
    
}

-(void)delayedQuickLookAction:(UIButton *)sender{
    
    self.view.userInteractionEnabled = YES;
    
    UIView *smartMessageView = [self.view viewWithTag:125453];
    [smartMessageView removeFromSuperview];
    
    [self saveNotebookState:YES];
}


-(void)pageSelectedFromPageList:(NSUInteger)pageIndex{
	if (pageCurlView.currentPageIndex == pageIndex) {
		return;
	}

#if FREE_VERSION
    if (pageIndex + 1 > TRIAL_LIMIT_NUM_PAGES) {
        [APP_DELEGATE showTrialLimitReachedMessage:@"Page List Popover"];
        return;
    }
#endif
    
	[self showPage:pageIndex refreshCurrentPage:YES];
}

#pragma mark -
#pragma mark Finder Methods 

-(void) finderButtonAction{
	
	[self normalizeDeskMode];
	
    if (writingView.isDirty) {
        self.view.userInteractionEnabled = NO;
        
        SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                             message:NSLocalizedString(@"SavingNotebook", @"Saving Notebook")
                                                                               style:kSmartMessageActivityIndicator];
        smartMessageView.tag = 125453;
        [self.view addSubview:smartMessageView];
        
        [self performSelector:@selector(delayedShowFinder) withObject:nil afterDelay:0.001];
    }else {
        [self performSelector:@selector(delayedShowFinder)];
    }
    
}

-(void)delayedShowFinder{
    
    //Wait until data services is done
    @synchronized([DataServices sharedDataServices]){}
    
    self.view.userInteractionEnabled = YES;
    
    UIView *smartMessageView = [self.view viewWithTag:125453];
    [smartMessageView removeFromSuperview];
    
    [self saveNotebookState:YES];
    
    if (0 == notebook.pages.count) {
		SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
																			 message:NSLocalizedString(@"NoPagesToShowInFinder", @"No pages to show in finder")
																			   style:kSmartMessageJustText];
		self.view.userInteractionEnabled = NO;
		[self.view addSubview:smartMessageView];
		[smartMessageView dismissAfterInterval:1 delegate:self];
		return;
	}
    
    self.returningFromFinder = YES;
}


-(void)showPage:(NSUInteger)pageIndex refreshCurrentPage:(BOOL)refreshCurrentPage{
    [self showPage:pageIndex refreshCurrentPage:refreshCurrentPage retainUndoBuffer:NO];
}

//Helper function to show a page
-(void)showPage:(NSUInteger)pageIndex refreshCurrentPage:(BOOL)refreshCurrentPage retainUndoBuffer:(BOOL)retainUndo{
	
	pageCurlView.currentPageIndex = pageIndex;
    
    NSString *paperGUID = [self getThemeForPage:pageIndex];
    
    [pageCurlView applyTheme:paperGUID];
    
    BOOL themeChanged = [onScreenPageView applyTheme:paperGUID];
    
	if(refreshCurrentPage){
		self.currentPageImage = [self getImageForPage:pageIndex];
		onScreenPageView.drawingImageView.image = self.currentPageImage;
        
        if (deskMode == kDeskModeText) {
        }else{
            [self putTextForPage:pageCurlView.currentPageIndex];
        }
        [self refreshAnnotationsView];
        //[writingView putUIImage:self.currentPageImage];
        writingView.hidden = YES;
        
		[self getWritingPositionForPage:pageIndex];
        
		if (zoomManagerView) {
			[self setZoomAreaPosition:[self getZoomAreaPositionForPage:pageCurlView.currentPageIndex]];
		}
		
	}
    
    if (cacheNextPreviousPages) {
		[self cachePreviousPageImageWithIndex:pageCurlView.currentPageIndex-1];
        [self cacheNextPageImageWithIndex:pageCurlView.currentPageIndex+1];
	}
	
    writingView.isDirty = NO;
    
	[onScreenPageView setDate:[self getCreationDateForPage:pageIndex]];
	
	[self refreshPageNumbers];
    
    [self performSelector:@selector(delayedShowPage:)
               withObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           paperGUID, @"paper_guid",
                           [NSNumber numberWithBool:themeChanged], @"theme_changed",
                           [NSNumber numberWithBool:refreshCurrentPage], @"refresh_page",
                           [NSNumber numberWithBool:retainUndo], @"retain_undo", nil]
               afterDelay:0.001];
}

-(void)delayedShowPage:(NSDictionary *)showPageOptions{
    
    if (applicationEnteredBackground) return;
    
    BOOL themeChanged = [[showPageOptions objectForKey:@"theme_changed"] boolValue];
    BOOL refreshCurrentPage = [[showPageOptions objectForKey:@"refresh_page"] boolValue];
    BOOL retainUndo =  [[showPageOptions objectForKey:@"retain_undo"] boolValue];
    
    onScreenPageView.drawingImageView.image = nil;
    
    if (themeChanged) {
        [self updatePageCurlImage];
    }
    
    if(refreshCurrentPage){
        [writingView putUIImage:self.currentPageImage retainUndoBuffer:retainUndo];
        writingView.hidden = NO;
	}
    
}

#pragma mark -
#pragma mark Notebook Settings Methods

-(void) settingsButtonAction{
    [self openSettingsPageWithDefaultSetting:SettingsName_NotebookSetup];
}

-(void)moreActionsButtonAction
{
    [self normalizeDeskMode];
    [self saveNotebookState:YES];
    
    FTMoreActionsViewController *notebookSettingsViewController = [[FTMoreActionsViewController alloc] initWithStyle:UITableViewStyleGrouped delegate:self];
    
    notebookSettingsViewController.notebookShelfItem = self.notebookShelfItem;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:notebookSettingsViewController];
    navController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.moreActionsToolsController = navController;

    UIPopoverPresentationController *popOver = navController.popoverPresentationController;
    popOver.permittedArrowDirections = UIPopoverArrowDirectionUp;
    popOver.sourceView = deskToolbarView.rightPanelView;
    popOver.sourceRect = CGRectInset(deskToolbarView.settingsButton.frame, 10, 10);
    popOver.delegate = self;
    
    ////////////////
    //Actions Section
    /////////////////
    FTActionSettingsType actionType = FTActionSettingsTypeNone;
    if ([self.deskToolbarView isButtonHiddenDueToWidthConstraint:self.deskToolbarView.addAnnotationButton])
    {
        actionType = actionType | FTActionSettingsTypeAddAnnotation;
    }
    if ([self.deskToolbarView isButtonHiddenDueToWidthConstraint:self.deskToolbarView.textButton])
    {
        actionType = actionType | FTActionSettingsTypeAddAnnotation;
    }
    if ([self.deskToolbarView isButtonHiddenDueToWidthConstraint:self.deskToolbarView.clearPageButton])
    {
        actionType = actionType | FTActionSettingsTypeClearPage;
    }
    if ([self.deskToolbarView isButtonHiddenDueToWidthConstraint:self.deskToolbarView.wristProtectionButton])
    {
        actionType = actionType | FTActionSettingsTypeWristProtection;
    }
    if ([self.deskToolbarView isButtonHiddenDueToWidthConstraint:self.deskToolbarView.theCopyPasteButton])
    {
        actionType = actionType | FTActionSettingsTypeLassoSelection;
    }
    if ([self.deskToolbarView isButtonHiddenDueToWidthConstraint:self.deskToolbarView.zoomButton])
    {
        actionType = actionType | FTActionSettingsTypeZoom;
    }
    if ([self.deskToolbarView isButtonHiddenDueToWidthConstraint:self.deskToolbarView.shareIconButton])
    {
        actionType = actionType | FTActionSettingsTypeShareAction;
    }
    [notebookSettingsViewController showActionsListForTypes:actionType];
    ////////////////
    [self presentViewController:moreActionsToolsController animated:YES completion:nil];
}

#pragma mark Popover Delegate Method (shared across)
//This is shared across all pop-overs (not just settings pop-over)
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    self.photosPopover = nil;
    self.exportPopoverController = nil;
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

-(void)dismissMoreActionsToolsControllerAnimate:(BOOL)animate
{
    if (self.moreActionsToolsController)
    {
        [self.moreActionsToolsController dismissViewControllerAnimated:animate completion:nil];
        self.moreActionsToolsController = nil;
    }
}
#pragma mark Settings View Controller Delegate Methods

-(void)notebookSettingsViewControllerReadOnlyModeChanged{
    if ([self.notebookShelfItem.readOnly boolValue]) {
        [self setReadonlyMode];
    }else{
        [self dismissReadonlyMode];
    }
    [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];
    //*********************************
    //Flurry
    //*********************************
    
    NSDictionary *flurryInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"NoteBook",@"Book Type",[[self.notebookShelfItem readOnly] boolValue]?@"Enabled":@"Disabled",@"Is Read Only", nil];
    [Flurry logEvent:@"Read-Only Changed" withParameters:flurryInfo];
    //*********************************
    
    
    //***************************************************
    //Crashlytics Info
    //***************************************************
    
    CLSLog(@"Read-Only Changed");
    
    //***************************************************

}
-(void)notebookSettingsViewControllerEvernoteSwitchChanged
{
    //Check if the evernote publish feature is purchased
    if(![[FTENPublishManager sharedPublishManager]evernotePublishFeaturePurchased])
    {
        [[FTENPublishManager sharedPublishManager] promptPurchaseOfENPublishFeature:self];
        return;
    }
    if(![[ENSession sharedSession] isAuthenticated] && !self.notebookShelfItem.enSyncEnabled)
    {
        [[FTENPublishManager sharedPublishManager] loginToEvernoteWithViewController:self completionHandler:^(BOOL success) {
            if(success)
                [self notebookSettingsViewControllerEvernoteSwitchChanged];
            
        }];
        return;
    }

    self.notebookShelfItem.enSyncEnabled = !self.notebookShelfItem.enSyncEnabled;
    [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];
    if(self.notebookShelfItem.enSyncEnabled)
    {
        [FTENPublishManager recordSyncLog:[NSString stringWithFormat:@"User enabled sync from inside notebook: %@", self.notebookShelfItem.title]];
        
//         [[FTENPublishManager sharedPublishManager]  udpateSyncRecordsOfShelfItemWithObjectID:self.notebookShelfItem removeDeletedPageRecords:YES];
         [[FTENPublishManager sharedPublishManager] startPublishing];
    }
    else
    {
        [FTENPublishManager recordSyncLog:[NSString stringWithFormat:@"User disabled sync from inside notebook: %@", self.notebookShelfItem.title]];
        [[FTENPublishManager sharedPublishManager] shelfItemDidGetUpdated:self.notebookShelfItem];
    }
    
    //***************************************************
    //Flurry Info
    //***************************************************
    
    if(self.notebookShelfItem.enSyncEnabled)
        [Flurry logEvent:@"Evernote Sync Enabled" withParameters:@{@"From":@"Notebook",@"New":@"NO"}];
    else
        [Flurry logEvent:@"Evernote Sync Disabled" withParameters:@{@"From":@"Notebook"}];
    
    //***************************************************
}

-(void)notebookSettingsViewControllerPageTemplateChanged:(NSString *)newPaperThemeGUID defaultGoingForward:(BOOL)makeDefault applyToAllPages:(BOOL)applyToAllPages{
    
    [onScreenPageView applyTheme:newPaperThemeGUID];
    [pageCurlView applyTheme:newPaperThemeGUID];
    
    FTNNotebookPage * fetchedPage = [self getPageManagedObject:pageCurlView.currentPageIndex];
	
	if (fetchedPage) {
		fetchedPage.paperTheme = newPaperThemeGUID;
        if(self.notebookShelfItem.enSyncEnabled)
        {
            [FTENPublishManager recordSyncLog:[NSString stringWithFormat:@"User changed template of page (%ld of %lu) of notebook: %@", (long)(fetchedPage.pageIndex.integerValue+1), (unsigned long)notebook.pages.count, self.notebookShelfItem.title]];
            [[FTENPublishManager sharedPublishManager] pageDidGetUpdated:fetchedPage];
        }
        [[FTCloudBackUpManager sharedCloudBackUpManager] shelfItemDidGetUpdated:self.notebookShelfItem];
        [notebook turnPageToFault:fetchedPage];
	}else{
        
        //Add the page if it does not exist
        self.currentPageImage = [writingView getUIImage];
        [self saveImageForPage:pageCurlView.currentPageIndex
                         image:self.currentPageImage
            backgroundSavePage:YES
       backgroundSaveThumbnail:YES
         onCompletion:nil];
        
        writingView.isDirty = NO;
        newPageCreationFlag = NO;
        pageCurlView.numberOfPages = self.notebook.pages.count + 1;
        [self refreshPageNumbers];
        fetchedPage = [self getPageManagedObject:pageCurlView.currentPageIndex];
    }
    
    if (makeDefault || applyToAllPages) {
        self.notebookShelfItem.paperTheme = newPaperThemeGUID;
        
        [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];
        
    }
    [self updatePageCurlImage];

    [writingView publishCanvas];
    
    if (applyToAllPages) {
        if(self.notebookShelfItem.enSyncEnabled)
            [FTENPublishManager recordSyncLog:[NSString stringWithFormat:@"User changed template from inside notebook for all %lu pages of notebook: %@", (unsigned long)self.notebook.pages.count, self.notebookShelfItem.title]];
        
        NSArray *pagesArray = notebook.pages;
        for (FTNNotebookPage * page in pagesArray) {
            page.paperTheme = newPaperThemeGUID;
            [notebook saveWithCompletionHandler:nil];
            [[FTENPublishManager sharedPublishManager] pageDidGetUpdated:page];
            [[FTCloudBackUpManager sharedCloudBackUpManager] shelfItemDidGetUpdated:self.notebookShelfItem];
            [notebook turnPageToFault:page];
       }
        
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PaperThemeUpdated" object: nil userInfo:@{@"page":fetchedPage}];
}

-(void)notebookSettingsViewControllerShowStore{
    
    [[SFManager sharedInstance] displayStoreFrontWithRootViewController:self];
    //**********************************
    //Flurry
    //**********************************
    NSDictionary *flurryInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"NoteBook Settings",@"Store Front From", nil];
    [Flurry logEvent:@"Store Viewed" withParameters:flurryInfo timed:YES];
    //**********************************
    
    
    //***************************************************
    //Crashlytics Info
    //***************************************************
    
    CLSLog(@"Store Viewed");
    
    //***************************************************

}

-(void)notebookSettingsViewControllerWristProtectionChanged{
    
    pageCurlView.pressurePenPageTurnMode=[PressurePenEngine sharedPressurePenEngine].pressurePenWristProtectionActive;
    if(![PressurePenEngine sharedPressurePenEngine].pressurePenWristProtectionActive)
    {
        if(self.writingView.zoomGLView)
        {
            [[FTStylusPenManager sharedInstance] unregisterView:self.writingView.zoomGLView setToDefault:YES];
        }
        else
        {
            [[FTStylusPenManager sharedInstance] unregisterView:self.writingView setToDefault:YES];
            //[[FTStylusPenManager sharedInstance] unregisterView:self.pageCurlView setToDefault:YES];
        }
    }
    else
    {
        if(self.writingView.zoomGLView)
        {
            [[FTStylusPenManager sharedInstance] registerView:self.writingView.zoomGLView delegate:(id)self.writingView.zoomGLView];
        }
        else
        {
            //[[FTStylusPenManager sharedInstance] registerView:self.pageCurlView delegate:(id)self.writingView];
            [[FTStylusPenManager sharedInstance] registerView:self.writingView delegate:(id)self.writingView];
        }

    }
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

-(void)notebookSettingsViewControllerClearPageAction{
    
    [self dismissMoreActionsToolsControllerAnimate:YES];
   
    FTNNotebookPage * aPage = [self getPageManagedObject:pageCurlView.currentPageIndex];
    [notebook removeAllAnnotationsForPage:aPage];
    [notebook saveWithCompletionHandler:nil];

    [writingView eraseAll];
    //Create Page If Needed
    [self addPageIfNeeded];
    
    [self putTextForPage:pageCurlView.currentPageIndex];
    [writingView publishCanvas];

    [self refreshAnnotationsView];
}

-(void)notebookSettingsClose
{
    [self dismissMoreActionsToolsControllerAnimate:YES];
}

-(void)notebookSettingsDidTappedOnActionLassoPaste
{
    [self dismissMoreActionsToolsControllerAnimate:YES];
    [self switchMode:kDeskModeClipboard];
    [self pasteMenuAction2:nil];
}

-(void)notebookSettingsDidTappedOnZoom
{
    [self zoomButtonAction];
    [self dismissMoreActionsToolsControllerAnimate:YES];
}

-(void)notebookSettingsDidTappedOnActionLassoSelection
{
    [self dismissMoreActionsToolsControllerAnimate:YES];
    if (lassoView)
    {
        return;
    }
    
    
    [self normalizeDeskMode];
    
    if (deskMode == kDeskModeClipboard) {
        //[photoView finalizePhotoPlacement];
        return;
    }
    
    lassoView = [[LassoSelectionView alloc] initWithFrame:writingView.frame];
    lassoView.delegate = self;
    [coverContainerView addSubview:lassoView];

    [self switchMode:kDeskModeClipboard];
}

-(void)notebookSettingsDidTappedOnActionWristProtection
{
    [self dismissMoreActionsToolsControllerAnimate:YES];
    [self wristProtectionButtonAction];
}

-(void)notebookSettingsDidTappedOnAddAnnotation
{
    [self dismissMoreActionsToolsControllerAnimate:YES];
    [self addAnnotationButtonAction:nil];
}

-(void)notebookSettingsDidTappedOnShareAction
{
    [self dismissMoreActionsToolsControllerAnimate:YES];
    [self shareButtonAction];
}

-(void)notebookSettingsViewControllerChoosePaper
{

}
#pragma mark SendViewController delegate passthrough methods

-(void)notebookSettingsSendPageViaTwitter{
    
    //Create the tweet sheet
    SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    //Add a tweet message
    [tweetSheet setInitialText:@"#Noteshelf "];
#ifdef DEBUG
    [tweetSheet setInitialText:@"#Diamond "];
#endif
    //Add an image
    [tweetSheet addImage:[self orientImageForSending:[self getCurrentPageImageForSending]]];
    //Set a blocking handler for the tweet sheet
    tweetSheet.completionHandler = ^(TWTweetComposeViewControllerResult result){
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        if (result == TWTweetComposeViewControllerResultDone){
            
            //***************************************************
            //Flurry Info
            //***************************************************
            [Flurry logEvent:@"Page Tweeted"];
            //***************************************************
            
            //***************************************************
            //Crashlytics Info
            //***************************************************
            
            CLSLog(@"Page Tweeted");
            
            //***************************************************

        }
    };
    //Show the tweet sheet!
    UIViewController *viewController = (APP_DELEGATE).window.visibleViewController;
    [viewController presentViewController:tweetSheet animated:YES completion:nil];
}

-(void)notebookSettingsSendPageViaFacebook{
    //we will dismiss this object when it is finished posting
    
    if(NSClassFromString(@"SLComposeViewController")) {
        
        //iOS 6 onwards
        
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result){
            
            [controller dismissViewControllerAnimated:YES completion:nil];
            
            if (result == SLComposeViewControllerResultDone) {
                
                //***************************************************
                //Flurry Info
                //***************************************************
                [Flurry logEvent:@"Page To Facebook"];
                //***************************************************
                
                //***************************************************
                //Crashlytics Info
                //***************************************************
                
                CLSLog(@"Page To Facebook");
                
                //***************************************************

            }
            
        };
        controller.completionHandler =myBlock;
        
        //[controller setInitialText:@"Test Message"];
        //[controller addURL:[NSURL URLWithString:@"http://www.fluidtouch.biz"]];
        [controller addImage:[self orientImageForSending:[self getCurrentPageImageForSending]]];
        
        UIViewController *viewController = (APP_DELEGATE).window.visibleViewController;
        [viewController presentViewController:controller animated:YES completion:nil];
        
    }
}

-(void)notebookSettingsSendPageViaEmail{
    
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    
    [controller addAttachmentData: UIImagePNGRepresentation([self orientImageForSending:[self getCurrentPageImageForSending]])
                         mimeType: @"image/png"
                         fileName:[NSString stringWithFormat:@"%@ P%lu.png", self.notebookShelfItem.title, (unsigned long)pageCurlView.currentPageIndex]];
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    UIViewController *viewController = (APP_DELEGATE).window.visibleViewController;
    [viewController presentViewController:controller animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    if (result == MFMailComposeResultSent) {
        //***************************************************
        //Flurry Info
        //***************************************************
        [Flurry logEvent:@"Page Emailed"];
        //***************************************************
        
        //***************************************************
        //Crashlytics Info
        //***************************************************
        
        CLSLog(@"Page Emailed");
        
        //***************************************************
        
    }
    
    [self becomeFirstResponder];
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma change of orientation
-(void)notebookSettingsDidChangeNotebookOrientation
{
    self.forceLayout = YES;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    [self.desktopView setNeedsLayout];

    if (deskToolbarView.zoomButton.selected) {
        [self zoomPanelAdjustToOrientationChange:[[UIApplication sharedApplication] statusBarOrientation]];
        [self zoomManagerRectMoved];
    }
}

-(UIImage *)orientImageForSending:(UIImage *)anImage{
    if (writingView.isLandscape) {
        
        if (writingView.isInverted) {
            return [anImage imageRotatedByDegrees:-90];
        }else{
            return [anImage imageRotatedByDegrees:90];
        }
        
    }else{
        return anImage;
    }
}

#pragma mark -
#pragma mark Undo/Redo/Clear Methods

-(void)undo
{
    [self undoButtonAction];
}

-(void)redo
{
    [self redoButtonAction];
}

-(void) undoButtonAction{
	
    [self normalizeDeskMode];
	[writingView undo];
    if (zoomPanel) [self refreshZoomButtonStates];
}

-(void) redoButtonAction{
    
	[self normalizeDeskMode];
	[writingView redo];
    if (zoomPanel) [self refreshZoomButtonStates];
}

-(void) clearPageButtonAction{
    
    [self normalizeDeskMode];
    
    FTNNotebookPage * aPage = [self getPageManagedObject:pageCurlView.currentPageIndex];
    
    FTActionSheet *actionSheet;
    
    if (aPage.textEntries.count || [notebook annotationsForPage:aPage].count)
    {
        actionSheet = [[FTActionSheet alloc] initWithTitle:nil
                                                  delegate:self cancelButtonTitle:nil
                                    destructiveButtonTitle:NSLocalizedString(@"ClearPage", @"Clear Page")
                                         otherButtonTitles:@[NSLocalizedString(@"ClearHandwritingOnly", @"Clear Handwriting Only"), NSLocalizedString(@"Cancel", @"Cancel")]];
        actionSheet.tag = 333;
    }else{
        actionSheet = [[FTActionSheet alloc] initWithTitle:nil
                                                  delegate:self cancelButtonTitle:nil
                                    destructiveButtonTitle:NSLocalizedString(@"ClearPage", @"Clear Page")
                                         otherButtonTitles:@[NSLocalizedString(@"Cancel", @"Cancel") ]];
        actionSheet.tag = 222;
    }

    [actionSheet showFromRect:CGRectInset(deskToolbarView.clearPageButton.bounds, 10, 10) inView:deskToolbarView.clearPageButton animated:YES];
}


-(void)activeStylusButtonAction
{
    [self openSettingsPageWithDefaultSetting:SettingsName_Stylus];
}

-(void)didDismissSettingsController
{
    UIView *currentWritingView = self.writingView;
    if(self.writingView.zoomGLView)
    {
        currentWritingView = self.writingView.zoomGLView;
    }
    [[FTStylusPenManager sharedInstance] registerView:currentWritingView delegate:(id)currentWritingView];
    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    [self refreshActiveStylusButton];
}

-(void)refreshActiveStylusButton
{
    BOOL needsRefresh = false;
    if([[PressurePenEngine sharedPressurePenEngine] isAnyStylusConnected])
    {
        if(self.deskToolbarView.activeStylusButton.hidden != false){
            self.deskToolbarView.activeStylusButton.hidden = false;
            self.deskToolbarView.activeStylusButton.selected = true;
            needsRefresh = true;
        }
    }
    else
    {
        if(self.deskToolbarView.activeStylusButton.hidden != true){
            self.deskToolbarView.activeStylusButton.hidden = true;
            self.deskToolbarView.activeStylusButton.selected = false;
            needsRefresh = true;
        }
    }
    if(needsRefresh){
        [self.deskToolbarView setNeedsLayout];
    }
}

#pragma mark -
#pragma mark Wrist Protection

-(void) wristProtectionButtonAction{
    [self wristProtectionToggle:YES];
}

-(void) wristProtectionToggle:(BOOL)showMessage{
	
	[self normalizeDeskMode];
	
	if (deskToolbarView.wristProtectionButton.selected) {
		deskToolbarView.wristProtectionButton.selected = NO;
		//auxNavigator.hidden = YES;
        pageCurlView.canTurnPage = YES;
        
        //***************************************************
        //Flurry Info
        //***************************************************
        [Flurry logEvent:@"WP Disabled" withParameters:nil];
        //***************************************************
        
        //***************************************************
        //Crashlytics Info
        //***************************************************
        
        CLSLog(@"WP Disabled");
        
        //***************************************************

        
	}else {
		deskToolbarView.wristProtectionButton.selected = YES;
		//auxNavigator.hidden = NO;
        pageCurlView.canTurnPage = NO;
		
        //***************************************************
        //Flurry Info
        //***************************************************
        [Flurry logEvent:@"WP Enabled" withParameters:nil];
        //***************************************************
        
        //***************************************************
        //Crashlytics Info
        //***************************************************
        
        CLSLog(@"WP Enabled");
        
        //***************************************************

        
	}
	
	writingView.wristProtectionOn = deskToolbarView.wristProtectionButton.selected;
    
	if (zoomPanel) {
		[zoomPanel setWristProtection:deskToolbarView.wristProtectionButton.selected];
        //auxNavigator.hidden = YES;
		writingView.wristProtectionOn = NO;
	}
	
    
    
	self.notebookShelfItem.wristProtectionOn = [NSNumber numberWithBool:deskToolbarView.wristProtectionButton.selected];
    [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];

    [self refreshAuxNavigatorDisplayForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    if (showMessage) {
        SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                             message:deskToolbarView.wristProtectionButton.selected ? NSLocalizedString(@"WristProtectionOn", @"Wrist Protection On") : NSLocalizedString(@"WristProtectionOff", @"Wrist Protection Off")
                                                                               style:kSmartMessageJustText];
        self.view.userInteractionEnabled = NO;
        [self.view addSubview:smartMessageView];
        [smartMessageView dismissAfterInterval:1 delegate:self];
    }
}

#pragma mark Wrist Protection Marker Delegate

-(void)wristProtectionMarkerEnded:(CGFloat)newPosition{
	
    
    //NSLog(@"Marker Position: %f", newPosition);
    
    UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation] forShelfItem:self.notebookShelfItem];
    if (UIInterfaceOrientationIsPortrait(layoutOrientation) || self.alwaysInPortrait) {
        
        writingView.writingPosition =  864 - newPosition + WRITING_POSITION_OFFSET;
        
    }else{
        if (writingView.isInverted) {
            writingView.writingPositionLanscapeInverted = newPosition - WRITING_POSITION_OFFSET; 
        }else{
            writingView.writingPositionLanscape = newPosition - WRITING_POSITION_OFFSET;
        }
    }
	
	//If real page exists, mark the writing view for saving
	if (pageCurlView.currentPageIndex < notebook.pages.count) {
		writingView.isDirty = YES;
	}
	
}

#pragma mark Auxiliary Navigator Delegate methods

-(void)auxiliaryNavigatorTurnPrevious{
	[pageCurlView jumpToPreviousPage];
}

-(void)auxiliaryNavigatorTurnNext{
	[pageCurlView jumpToNextPage];
}

#pragma mark -
#pragma mark SmartMessageView Delegate Methods

-(void)smartMessageDismissed:(SmartMessageView *)smartMessageView{
    
	self.view.userInteractionEnabled = YES;
}

#pragma mark -
#pragma mark Pen Methods

-(void) penButtonAction{
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:IS_ZOOM_TOOL_ACTIVE]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:IS_ZOOM_TOOL_ACTIVE];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [zoomPanel selectAppopriateZoomTool:YES];
        
        if(deskMode == kDeskModePen) deskMode = -1;
    }
    
    [self switchMode:kDeskModePen];
}

-(void)applyOrientationForPenRack:(UIInterfaceOrientation)interfaceOrientation
{
}


-(void)applyOrientationForAddAnnotationView:(UIInterfaceOrientation)interfaceOrientation
{
}

#pragma mark Pen Rack Delegate Methods

-(void)penToolChanged:(FTBasePenModel *)pen   {
    [self setCurrentPenWritingMode];
    if(deskToolbarView.markerButton.isSelected)
        [deskToolbarView refreshSelectedMarkerColor];
    else
        [deskToolbarView refreshSelectedPenColor];
    
}

-(void)penColorSelected:(FTBasePenModel *)pen {
    [self setCurrentPenWritingMode];
    if(deskToolbarView.markerButton.isSelected)
        [deskToolbarView refreshSelectedMarkerColor];
    else
        [deskToolbarView refreshSelectedPenColor];
    if (zoomPanel) [self refreshZoomButtonStates];
}

-(void)brushWidthChanged:(FTBasePenModel *)pen  {
	writingView.brushWidth = pen.brushSize.floatValue;
}

-(void)shapeDetectionDidEnabled
{
    [deskToolbarView refreshShapeIndicator];
}

-(void)penRackClosed{
    //************************************
    //Flurry
    //************************************
    [[[FTPenCollectionManager sharedCollectionManager] selectedPen] logToFlurryForShelfItemType:self.notebookShelfItem.type.integerValue];
    //************************************
	penRackOpen = NO;
}

-(BOOL)isLandscapeNotebook
{
    return self.writingView.isLandscape;
}

#pragma mark -
#pragma mark Marker Methods

-(void) markerButtonAction{
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:IS_ZOOM_TOOL_ACTIVE]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:IS_ZOOM_TOOL_ACTIVE];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [zoomPanel selectAppopriateZoomTool:YES];
        if(deskMode == kDeskModeMarker) deskMode = -1;
    }
	[self switchMode:kDeskModeMarker];
}

#pragma mark -
#pragma mark Eraser Methods

-(void) eraserButtonAction{
	[self switchMode:kDeskModeEraser];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:IS_ZOOM_TOOL_ACTIVE];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self refreshZoomButtonStates];
    [self.zoomPanel selectAppopriateZoomTool:YES];
}

-(void)applyOrientationForEraserRack:(UIInterfaceOrientation)interfaceOrientation{
    
}


#pragma mark Eraser Picker Delegate Methods

-(void)eraserSizeSelected:(CGFloat)newSize{
	writingView.brushWidth = newSize;
	if (zoomPanel) {
		writingView.brushWidth = newSize/zoomPanel.zoomGLView.zoomFactor;
	}
    
    //***************************************************
    //Flurry Info
    //***************************************************
    
    NSDictionary *flurryInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"NoteBook", @"Book Type",
                                    [NSNumber numberWithFloat:newSize], @"Size",
                                    nil];
    [Flurry logEvent:@"Eraser" withParameters:flurryInfoDict];
    
    //***************************************************
    
    
    //***************************************************
    //Crashlytics Info
    //***************************************************
    
    CLSLog(@"Eraser Selected");
    
    //***************************************************


    
}

-(void)eraserRackClosed{
	eraserPickerOpen = NO;
}

#pragma mark -
#pragma mark Pen Tuning Related

-(void)penTuningApplyAction{
    
//    writingView.brushWidth = [[PenDefaults sharedPenDefaults] getSizeForPenType:[PenDefaults sharedPenDefaults].currentPenType];
//    [writingView setColor:[[PenDefaults sharedPenDefaults] getColorForCurrentPen]];
    FTBasePenModel *selectedPen = [FTPenCollectionManager sharedCollectionManager].selectedPen;
    if(nil == selectedPen)
    {
        selectedPen = [[[[FTPenCollectionManager sharedCollectionManager] pensCollection] objectAtIndex:0] selectedPen];
    }
    writingView.brushWidth = selectedPen.brushSize.floatValue;
    [writingView setColor: selectedPen.color];    
}

-(void)penTuningCloseAction{
    [self dismissMoreActionsToolsControllerAnimate:YES];
}

#pragma mark -
#pragma mark Stickers Methods

-(void) iconsButtonAction{
    
	[self switchMode:kDeskModeStickers];
}

-(void)applyOrientationForStickersRack:(UIInterfaceOrientation)interfaceOrientation
{
    if (self.alwaysInPortrait) {
        
        CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
        if(UIInterfaceOrientationIsPortrait(interfaceOrientation))
            self.stickerSelectionView.frame = CGRectMake(0, CGRectGetMaxY(self.deskToolbarView.frame), viewWidth, 1004-44);
        else if(UIInterfaceOrientationIsLandscape(interfaceOrientation))
            self.stickerSelectionView.frame = CGRectMake(0, CGRectGetMaxY(self.deskToolbarView.frame), viewWidth, 748-44);
        [self.stickerPlacementView layoutForOrientation:UIInterfaceOrientationPortrait inverted:NO];

        [self.stickerSelectionView layoutIfNeeded];
        
        return;
    }
    
    UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:interfaceOrientation forShelfItem:self.notebookShelfItem];
    [self.stickerPlacementView layoutForOrientation:layoutOrientation inverted:writingView.isInverted];
    
    CGRect frame  = desktopView.frame;

    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        
        self.stickerSelectionView.transform = CGAffineTransformMakeRotation(0);
        frame.origin.y = CGRectGetMaxY(self.deskToolbarView.frame);
    }else{
        self.stickerSelectionView.transform = CGAffineTransformMakeRotation(M_PI * -.5);
    }
    
    self.stickerSelectionView.frame = frame;
    [self.stickerSelectionView layoutIfNeeded];
}

-(void) stickerSelected:(UIImage *)stickerImage emojiID:(NSUInteger)emojiID {
	stickerPlacementView.activeSticker.image = stickerImage;
}

-(void) placeStickerInRect:(CGRect)targetRect
              stickerImage:(UIImage *)stickerImage
                   emojiID:(NSUInteger)emojiID
{
    
    if (!self.alwaysInPortrait)
    {
        UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation] forShelfItem:self.notebookShelfItem];
        if (UIInterfaceOrientationIsLandscape(layoutOrientation))
        {
            if (writingView.isInverted) {
                stickerImage = [stickerImage imageRotatedByRadians:M_PI * .5];
            }else{
                stickerImage = [stickerImage imageRotatedByRadians:M_PI * -.5];
            }    
        }
    }
    
	[writingView putUIImage:stickerImage inRect:targetRect replace:NO];
	[self addPageIfNeeded];
}


#pragma mark -
#pragma mark Mode Switcher Method
-(void)switchModeForPencilToMode:(WritingMode)toMode selectButtonWithMode:(WritingMode)selectMode
{
    BOOL isZoomActive = [[NSUserDefaults standardUserDefaults] boolForKey:IS_ZOOM_TOOL_ACTIVE];
    
    //Map writingmode to deskmode
    RKDeskMode mode;
    switch (toMode) {
        case kPenMode:
        case kPencilMode:
        case kCalligraphyMode:
            mode = kDeskModePen;
            break;
            
        case kMarkerMode:
            mode = kDeskModeMarker;
            break;
        case kEraserMode:
            mode = kDeskModeEraser;
            break;
        default:
            break;
    }
    
    [self switchMode:mode];
    
    switch (toMode) {
        case kPenMode:
        case kPencilMode:
        case kCalligraphyMode:
            self.deskToolbarView.penButton.selected = NO;
            break;
            
        case kMarkerMode:
            self.deskToolbarView.markerButton.selected = NO;
            break;
        case kEraserMode:
            self.deskToolbarView.eraserButton.selected = NO;
            self.zoomPanel.erasorButton.selected = NO;
            break;
        default:
            break;
    }
    switch (selectMode) {
        case kPenMode:
        case kPencilMode:
        case kCalligraphyMode:
            self.deskToolbarView.penButton.selected = !isZoomActive;
            break;
            
        case kMarkerMode:
            self.deskToolbarView.markerButton.selected = !isZoomActive;
//        case kEraserMode:
//            self.deskToolbarView.eraserButton.selected = YES;
//            break;
        default:
            break;
    }

    if(isZoomActive && toMode!=kEraserMode)
    {
        
        RKPenType penType = [[NSUserDefaults standardUserDefaults] integerForKey:ACTIVE_ZOOM_TOOL];
        [self zoomPanelColorSwatchSelected:[[PenDefaults sharedPenDefaults] getSelectedZoomSwatchColorForPenType:penType]
                                   penSize:[[PenDefaults sharedPenDefaults] getSelectedZoomSwatchPenSizeForPenType:penType]
                                forPenType:penType];
    }

}

-(void)switchMode:(RKDeskMode)newDeskMode{
	
    [self closeAddRackViewOnCompletion:nil];
    if (newDeskMode!=deskMode) {
		
		if (newDeskMode != kDeskModePen && newDeskMode != kDeskModeMarker && newDeskMode != kDeskModeEraser && deskToolbarView.zoomButton.selected ) {
			[self dismissZoomMode];
            self.notebookShelfItem.zoomModeActive = [NSNumber numberWithBool:NO];
            [self.currentShelfItemProvider saveShelfItemChanges:self.notebookShelfItem];
        }
        
		//Close the current desk mode
		switch (deskMode) {
			case kDeskModePen:
				deskToolbarView.penButton.selected = NO;
				
				break;
			case kDeskModeMarker:
				deskToolbarView.markerButton.selected = NO;
				break;
				
			case kDeskModeEraser:
				deskToolbarView.eraserButton.selected = NO;
				break;
				
			case kDeskModeStickers:
				
				[self.stickerSelectionView removeFromSuperview];
				self.stickerSelectionView = nil;
                
                [self.stickerPlacementView removeFromSuperview];
                self.stickerPlacementView = nil;
				break;
				
			case kDeskModePhoto:
				
				if (photoView && !photoView.clipboardMode) {
					[self performPhotoPlacement];
					[photoView removeFromSuperview];
					self.photoView = nil;
				}
                
				break;
            case kDeskModeCamera:
				
				if (photoView && !photoView.clipboardMode) {
					[self performPhotoPlacement];
					[photoView removeFromSuperview];
					self.photoView = nil;
				}
                
				break;
            case kDeskModeClipboard:
				deskToolbarView.theCopyPasteButton.selected = NO;
				
				if ((photoView && photoView.clipboardMode) || clipboardView)
                {
                    if (clipboardView) {
                        [self performClipboardPlacement];
                        [clipboardView removeFromSuperview];
                        clipboardView = nil;
                    }
					else
                    {
                        [self performPhotoPlacement];
                        [photoView removeFromSuperview];
                        self.photoView = nil;
                    }
				}
                
                if(lassoView){
                    [lassoView finalizeMove];
                    [lassoView removeFromSuperview];
                    self.lassoView = nil;
                }
                
				break;
			case kDeskModeText:
				deskToolbarView.textButton.selected = NO;
            default:
                break;
		}
		
		//Init the new mode
		switch (newDeskMode) {
			case kDeskModePen:
                
                [[FTPenCollectionManager sharedCollectionManager] setPenRackMode:FTPenRackModeTypeDefault];
                [self setCurrentPenWritingMode];
        
				deskToolbarView.penButton.selected = YES;
                
                [DataServices sharedDataServices].appDefaultsManageObject.currentTool = [NSNumber numberWithInt:newDeskMode];
                [APP_DELEGATE commitDataChanges];
                
				break;
                
			case kDeskModeMarker:
                [[FTPenCollectionManager sharedCollectionManager] setPenRackMode:FTPenRackModeTypeAlternate];
                [self setCurrentPenWritingMode];
                
				deskToolbarView.markerButton.selected = YES;
                
                [DataServices sharedDataServices].appDefaultsManageObject.currentTool = [NSNumber numberWithInt:newDeskMode];
                [APP_DELEGATE commitDataChanges];
				break;
                
			case kDeskModeEraser:
				[writingView setWritingMode:kEraserMode];
				
                //Fix for Zoom Mode Eraser blow-up issue
				if (zoomPanel) {
					writingView.brushWidth = [[DataServices sharedDataServices].appDefaultsManageObject.currentEraserSize floatValue]/zoomPanel.zoomGLView.zoomFactor;
				}else {
                    writingView.brushWidth = [[DataServices sharedDataServices].appDefaultsManageObject.currentEraserSize floatValue];
                }
				
				deskToolbarView.eraserButton.selected = YES;
                
                [DataServices sharedDataServices].appDefaultsManageObject.currentTool = [NSNumber numberWithInt:newDeskMode];
                [APP_DELEGATE commitDataChanges];
                
				break;
				
			case kDeskModeStickers:
				
                
				self.stickerPlacementView = [[StickerPlacementView alloc] initWithFrame:self.writingView.frame];
                self.stickerPlacementView.alwaysInPortrait = self.alwaysInPortrait;
				[self.coverContainerView insertSubview:self.stickerPlacementView belowSubview:self.toolbarImageView];
				self.stickerPlacementView.delegate = self;
				//Removed from memory in this function's "close mode"
				
				CGRect stickerSelectionViewFrame = self.alwaysInPortrait ? CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height-44) : desktopView.frame;
                
				self.stickerSelectionView = [[StickerSelectionView alloc] initWithFrame:stickerSelectionViewFrame];
                self.stickerSelectionView.alwaysInPortrait = self.alwaysInPortrait;
				[self.view insertSubview:self.stickerSelectionView belowSubview:self.toolbarImageView];
				self.stickerSelectionView.delegate = self;
				//Removed from memory in this function's "close mode"
				[self applyOrientationForStickersRack:[[UIApplication sharedApplication] statusBarOrientation]];
                [self.stickerSelectionView animateStickersView:kStickersPanelShowRecent];
                
				break;
                
			case kDeskModePhoto:
            case kDeskModeCamera:
				break;
                
            case kDeskModeClipboard:
				deskToolbarView.theCopyPasteButton.selected = YES;
				break;
                
			case kDeskModeText:
				deskToolbarView.textButton.selected = YES;
				[writingView setWritingMode:kTextMode];
                
                [writingView performSelector:@selector(publishCanvas) withObject:nil afterDelay:0.001];
                
                [DataServices sharedDataServices].appDefaultsManageObject.currentTool = [NSNumber numberWithInt:newDeskMode];
                [APP_DELEGATE commitDataChanges];
                
				break;
            default:
                break;
				
		}
		//Set the current mode to new mode
		deskMode = newDeskMode;
		
	}else {
        //Current mode button re-tapped
		switch (deskMode) {
			case kDeskModePen:
            case kDeskModeMarker:
				//Open the pen rack
				break;
				
			case kDeskModeEraser:
				
				//Open the eraser selector
				
				if (eraserPickerOpen){
                    return;
                }
                
				break;
				
			case kDeskModeStickers:
				
				//Open the stickers panel
				if (!(self.stickerSelectionView.panelState == kStickersPanelHide)){
					[self.stickerSelectionView animateStickersView:kStickersPanelHide];
                    return;
                }
                
				[self.stickerSelectionView animateStickersView:kStickersPanelShowRecent];
				break;
				
			case kDeskModePhoto:
            case kDeskModeCamera:
				break;
                
			case kDeskModeClipboard:
				break;
                
			case kDeskModeText:
				break;
            default:
                break;
				
		}
	}
    
    if (zoomPanel) [self refreshZoomButtonStates];
    [self updateExternalDisplayAsNeeded];
    
}

-(void)normalizeDeskMode{
	
	//Normalize the current desk mode
	
	switch (deskMode) {
		case kDeskModePen:
        case kDeskModeMarker:
			break;
		case kDeskModeEraser:
			
			break;
			
		case kDeskModeStickers:
			[self.stickerSelectionView animateStickersView:kStickersPanelHide];
			break;
            
		case kDeskModePhoto:
        case kDeskModeCamera:
			[self switchMode:kDeskModePen];
			break;
            
        case kDeskModeClipboard:
			[self switchMode:kDeskModePen];
			break;
            
        case kDeskModeText:
            //Save the current text
            break;
        default:
            break;
            
	}
    [[FTAudioAnnotationViewManager sharedManager] deSelectAllAnnotations:YES];
    [self closeAddRackViewOnCompletion:nil];
}

-(void)setCurrentPenWritingMode{
    
    FTBasePenModel *penModel = [FTPenCollectionManager sharedCollectionManager].selectedPen;
    
    __unused RKPenType penType = penModel.penType;
    [writingView setWritingMode:penModel.writingMode];
    
    writingView.brushWidth = penModel.brushSize.floatValue;
    [writingView setColor:penModel.color];
}

#pragma mark -
#pragma mark Photo Insertion Methods

-(void) photoButtonAction:(id)sender
{
	[self normalizeDeskMode];
	
	if (deskMode == kDeskModePhoto || deskMode == kDeskModeCamera) {
        return;
	}
   
    BOOL cameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    
    if (cameraAvailable) {
        
        FTActionSheet *photoAttachmentsActionSheet = [[FTActionSheet alloc] initWithTitle:nil
                                                                                 delegate:self cancelButtonTitle:nil
                                                                   destructiveButtonTitle:nil
                                                                        otherButtonTitles:@[NSLocalizedString(@"PhotoAlbum", @"Photo Album"), NSLocalizedString(@"iPadCamera", @"iPad Camera")]];
        
        [APP_DELEGATE setVisibleActionSheet:photoAttachmentsActionSheet];
        photoAttachmentsActionSheet.tag = 111;
        [photoAttachmentsActionSheet showFromRect:CGRectInset([sender frame], 10, 10)
                                           inView:deskToolbarView.centerPanelView
                                         animated:YES];
        
    }else{
        [self performSelector:@selector(showPhotoPopover:) withObject:self.deskToolbarView.addAnnotationButton];
    }
}

- (void)actionSheet:(FTActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{

    [APP_DELEGATE setVisibleActionSheet:nil];
    
    if (actionSheet.tag == 111) {
        
        if(buttonIndex == 0){
            [self performSelector:@selector(showPhotoPopover:) withObject:nil];
        }else if(buttonIndex == 1){
            [self performSelector:@selector(showCameraPopover:) withObject:nil];
        }
        
    }else if (actionSheet.tag == 222 || actionSheet.tag == 333) {
        
        //Clear Page action sheet
        if(buttonIndex == 0 || (buttonIndex == 1 && actionSheet.tag == 333)){
            
            if (buttonIndex == 0 && actionSheet.tag == 333) {
                //Clear text entries
                FTNNotebookPage * aPage = [self getPageManagedObject:pageCurlView.currentPageIndex];
                [notebook removeAllAnnotationsForPage:aPage];
                [notebook saveWithCompletionHandler:nil];
            }
            
            [writingView eraseAll];
            //Create Page If Needed
            [self addPageIfNeeded];
            
            [self putTextForPage:pageCurlView.currentPageIndex];
            [writingView publishCanvas];
            [self refreshAnnotationsView];
            //***************************************************
            //Flurry Info
            //***************************************************
            [Flurry logEvent:@"Page Cleared" withParameters:nil];
            //***************************************************
            
            //***************************************************
            //Crashlytics Info
            //***************************************************
            
            CLSLog(@"Page Cleared");
            
            //***************************************************

            
        }
    }
	
}

-(void)showPhotoPopover:(UIButton*)sender
{
    if (photosPopover != nil) {
        [self.photosPopover dismissViewControllerAnimated:NO completion:nil];
		self.photosPopover = nil;
	}
	
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if(status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addAnnotationButtonAction:nil];
                [self showPhotoPopover:self.deskToolbarView.addAnnotationButton];
            });
        }];
        return;
    }

	FTImagePickerController *imagePickerController = [[FTImagePickerController alloc] init];
	imagePickerController.allowsEditing = NO;
	imagePickerController.delegate = self;
    
    imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
    if(!self.isRegularClass)
    {
        imagePickerController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    
    if(sender == nil) {
        sender = self.deskToolbarView.addAnnotationButton;
    }
    self.photosPopover = imagePickerController;
    
	UIPopoverPresentationController *popOver = imagePickerController.popoverPresentationController;
	popOver.delegate = self;
    popOver.sourceView = sender;
    popOver.permittedArrowDirections = UIPopoverArrowDirectionUp;
    popOver.sourceRect = sender.bounds;
    [self presentViewController:self.photosPopover animated:YES completion:nil];
}

-(void)showCameraPopover{
    [self closeAddRackViewOnCompletion:nil];
    
    if (photosPopover != nil) {
        [self.photosPopover dismissViewControllerAnimated:NO completion:nil];
        self.photosPopover = nil;
	}
    
	FTImagePickerController *imagePickerController = [[FTImagePickerController alloc] init];
	imagePickerController.allowsEditing = NO;
	imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    self.photosPopover = imagePickerController;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
    
    self.cameraShown = YES;
}

- (void)applyOrientationForPhotoPlacementView:(UIInterfaceOrientation)interfaceOrientation{
    
    if (self.alwaysInPortrait) {
        photoView.frame = writingView.frame;
        return;
    }
    UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:interfaceOrientation forShelfItem:self.notebookShelfItem];
    if (UIInterfaceOrientationIsPortrait(layoutOrientation))
    {
        photoView.transform = CGAffineTransformMakeRotation(0);
    }
    else
    {
        if (writingView.isInverted)
        {
            photoView.transform = CGAffineTransformMakeRotation(M_PI * .5);
        }
        else
        {
            photoView.transform = CGAffineTransformMakeRotation(M_PI * -.5);
        }  
    }
    photoView.frame = writingView.frame;
}

#pragma mark Image Picker Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
	
    // Try getting the edited image first. If it doesn't 
	// exist then you get the original image.
    UIImage* picture;
	NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	if (CFStringCompare((__bridge CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {               
        picture = [info objectForKey:UIImagePickerControllerEditedImage];
        if (!picture)
			picture = [info objectForKey:UIImagePickerControllerOriginalImage];             
    }else {
		return;
	}
	
	if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        [photosPopover dismissViewControllerAnimated:YES completion:nil];
        self.photosPopover = nil;
    }
    
	//Do something with the picture
	photoView = [[ImageTransformerContainerView alloc] initWithFrame:writingView.frame];
	photoView.delegate = self;
	[coverContainerView addSubview:photoView];
    [self applyOrientationForPhotoPlacementView:[[UIApplication sharedApplication] statusBarOrientation]];
    UIImage *image = [UIImage imageWithCGImage:picture.CGImage scale:[UIScreen mainScreen].scale orientation:picture.imageOrientation];
    photoView.sourceImage = [image scaleAndRotateImage];
    self.photoView.imageScale = [[UIScreen mainScreen] scale];
    self.photoView.allowsResizing = YES;
    [self.photoView setEditing:NO];
    [self.photoView setAllowsEditing:YES];
    
	//This is being released in mode switcher
	NSString *source=nil;
	if(picker.sourceType == UIImagePickerControllerSourceTypeCamera){
        source=@"Camera";
        UIImageWriteToSavedPhotosAlbum(picture, nil, nil, nil);
        [self switchMode:kDeskModeCamera];
    }
    else{
        source=@"Photos";
        [self switchMode:kDeskModePhoto];
    }
    
    //***************************************************
    //Flurry Info
    //***************************************************
    
    NSDictionary *flurryInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"NoteBook", @"Book Type",
                                    source, @"Source",
                                    NSStringFromCGSize(picture.size),@"Image Size",
                                    nil];
    [Flurry logEvent:@"Image Added" withParameters:flurryInfoDict];
    
    //***************************************************
    
    //***************************************************
    //Crashlytics Info
    //***************************************************
    
    CLSLog(@"Image Added");
    
    //***************************************************


}

#pragma mark Photo Insertion Delegate Methods


-(void)imageTransformerContainerViewCancel:(id<FTImageTransformerContainerViewProtocol>)imageTransformerContainerView{
    //Change the mode of the Desk
    
    if (deskMode == kDeskModeClipboard) {
        [clipboardView removeFromSuperview];
        self.clipboardView = nil;
        
        if(self.photoView.clipboardMode){
            [self.photoView removeFromSuperview];
            self.photoView = nil;
        }
    }else{
        id entry = self.photoView.representedObject;
        if (entry) {
            [self.writingView publishCanvas];
        }
        [photoView removeFromSuperview];
        self.photoView = nil;
    }
	
	[self switchMode:kDeskModePen];
}

-(void)imageTransformerContainerViewPaste:(id<FTImageTransformerContainerViewProtocol>)imageTransformerContainerView{
    
    if (deskMode == kDeskModeClipboard && clipboardView)
    {
        [self performClipboardPlacement];
    }else{
        [self performPhotoPlacement];
    }
    
    
    [self switchMode:kDeskModePen];
}

-(void)imageTransformerContainerViewDidTapOutsideControlPoint:(id<FTImageTransformerContainerViewProtocol>)imageTransformerContainerView
{
    [imageTransformerContainerView performSelector:@selector(pasteMenuAction:) withObject:imageTransformerContainerView];
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

-(void)imageTransformerContainerViewDelete:(id<FTImageTransformerContainerViewProtocol>)imageTransformerContainerView
{
}

-(void)imageTransformerContainerViewFixIt:(id<FTImageTransformerContainerViewProtocol>)imageTransformerContainerView
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"FIX_PHOTO_MSG_DONT_SHOW"])
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"FlattenImageWarning", @"This option will merge...") preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",@"Cancel") style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];

        UIAlertAction *dontshowAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"DontShowHintAgain",@"Don't Show") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FIX_PHOTO_MSG_DONT_SHOW"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self perforPhotoFixOperation];
        }];
        [alertController addAction:dontshowAction];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self perforPhotoFixOperation];
        }];
        [alertController addAction:okAction];

        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        [self perforPhotoFixOperation];
    }
}

-(void)perforPhotoFixOperation
{
    id entry = self.photoView.representedObject;
    [self performPhotoPlacementAndFixIt];
    if (entry)
    {
        [self.notebook saveWithCompletionHandler:nil];
    }
    [self switchMode:kDeskModeClipboard];
}

-(void)imageTransformerContainerViewCut:(id<FTImageTransformerContainerViewProtocol>)imageTransformerContainerView{
    //Used by clipboardView only
    
    CGRect targetRect = [clipboardView getPlacementRect];
    
    if (CGRectIsNull(targetRect)) {
        return;
    }
    
    targetRect = [writingView convertRect:targetRect fromView:clipboardView];
    
    
    UIImage *image = [writingView getUIImageInRect:targetRect];
    
    if (!self.alwaysInPortrait)
    {
        UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation] forShelfItem:self.notebookShelfItem];
        if (UIInterfaceOrientationIsLandscape(layoutOrientation))
        {
            if (writingView.isInverted) {
                image = [image imageRotatedByRadians1x:M_PI * -.5];
            }else{
                image = [image imageRotatedByRadians1x:M_PI * .5];
            }    
            
        }
    }
    
    
    [writingView clearImageInRect:targetRect];
    
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    pasteBoard.image = image;
    
    [clipboardView removeFromSuperview];
	self.clipboardView = nil;
    
    [self switchMode:kDeskModePen];
    
}

-(void)imageTransformerContainerViewCopy:(id<FTImageTransformerContainerViewProtocol>)imageTransformerContainerView{
    //Used by clipboardView only
    
    CGRect targetRect = [clipboardView getPlacementRect];
    
    if (CGRectIsNull(targetRect)) {
        return;
    }
    
    targetRect = [writingView convertRect:targetRect fromView:clipboardView];
    
    
    UIImage *image = [writingView getUIImageInRect:targetRect];
    
    if (!self.alwaysInPortrait) {
        UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation] forShelfItem:self.notebookShelfItem];
        if (UIInterfaceOrientationIsLandscape(layoutOrientation)) {
            if (writingView.isInverted) {
                image = [image imageRotatedByRadians1x:M_PI * -.5];
            }else{
                image = [image imageRotatedByRadians1x:M_PI * .5];
            }    
            
        }
    }
    
    NSData *pngData = UIImagePNGRepresentation(image);
    NSMutableDictionary *items = [NSMutableDictionary dictionary];
    [items setValue:[NSNumber numberWithBool:YES] forKey:@"NoteshelfPasteBoard"];
    [items setObject:pngData forKey:(NSString*)kUTTypePNG];
    [[UIPasteboard generalPasteboard] setItems:@[items]];

    [clipboardView removeFromSuperview];
	self.clipboardView = nil;
    
    [self switchMode:kDeskModePen];
}

-(void)performPhotoPlacement{
}

-(void)performPhotoPlacementAndFixIt
{
    self.view.userInteractionEnabled = NO;

    UIImage *imageToPlace = [photoView getTransformedImageClipToBounds:YES];
    if (imageToPlace)
    {
        CGRect placementRect = CGRectIntersection([photoView getPlacementRect], photoView.bounds);
        CGRect targetRect = [writingView convertRect:placementRect fromView:photoView];
        
        clipboardView = [[FTClipboardImageTransformerContainerView alloc] initWithFrame:writingView.frame];
        clipboardView.fromPhotoMode = YES;
        clipboardView.delegate = self;
        clipboardView.clipboardMode = YES;
        [coverContainerView addSubview:clipboardView];
        
        clipboardView.sourceImage = [UIImage imageWithCGImage:imageToPlace.CGImage scale:1 orientation:imageToPlace.imageOrientation];
        [self applyOrientationForClipboardView:[[UIApplication sharedApplication] statusBarOrientation]];
        
        [clipboardView setStartingFrame:[clipboardView convertRect:targetRect fromView:writingView]];

        [clipboardView displayTransformed];
        
        //***************************************************
        //Flurry Info
        //***************************************************
        [Flurry logEvent:@"Photo Operation" withParameters:nil];
        //***************************************************
        
        //***************************************************
        //Crashlytics Info
        //***************************************************
        
        CLSLog(@"Photo added to notebook");
        
        //***************************************************
        [self enableLongGesture];
    }
    
    [photoView removeFromSuperview];
	self.photoView = nil;
    
    self.view.userInteractionEnabled = YES;
}

#pragma mark -
#pragma mark Clipboard Methods - Lasso View Delegate

-(void)lassoSelectionView:(LassoSelectionView *)lassoSelectionView initiateSelection:(CGPathRef)cutPath{
    
    BOOL textHint = [[NSUserDefaults standardUserDefaults] boolForKey:@"SELECTION_TOOL_TEXT_HINT_HIDE"];
    
    if (!textHint) {
        if ([self selectionOverlapsWithTextbox:cutPath]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"SelectionToolDoesNotSupportText", @"Selection tool does not...") preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"DontShowHintAgain", @"Don't Show") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SELECTION_TOOL_TEXT_HINT_HIDE"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }];
            [alertController addAction:action];
            
            UIAlertAction *otherAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:otherAction];

            [self presentViewController:alertController animated:YES completion:nil];

            //***************************************************
            //Flurry Info
            //***************************************************
            [Flurry logEvent:@"Lasso Operation - Textbox Warning" withParameters:nil];
            //***************************************************
            
            //***************************************************
            //Crashlytics Info
            //***************************************************
            
            CLSLog(@"Lasso Operation - Textbox Warning");
            
            //***************************************************

            
        }
    }
    [self raiseAlertForSelectionOverlapswithImageIfNeeded:cutPath];
    
    [writingView prepareForCut:cutPath];
}


-(void)lassoSelectionView:(LassoSelectionView *)lassoSelectionView selectionAreaMovedByOffset:(CGPoint)offset{
    [writingView moveCutAreaByOffset:offset];
}

-(void)lassoSelectionViewFinalizeMoves:(LassoSelectionView *)lassoSelectionView{
    [writingView finalizeMoveOperation:YES];
    //***************************************************
    //Flurry Info
    //***************************************************
    [Flurry logEvent:@"Lasso Operation" withParameters:nil];
    //***************************************************
    
    //***************************************************
    //Crashlytics Info
    //***************************************************
    
    CLSLog(@"Lasso Operation");
    
    //***************************************************

}

-(void)lassoSelectionViewTransformCommand:(LassoSelectionView *)lassoSelectionView{
    
    UIImage *cutImage = [writingView getSelectionAreaImage];
    
    if (!self.alwaysInPortrait) {
        UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation] forShelfItem:self.notebookShelfItem];
        if (UIInterfaceOrientationIsLandscape(layoutOrientation)) {
            if (writingView.isInverted) {
                cutImage = [cutImage imageRotatedByRadians1x:M_PI * -.5];
            }else{
                cutImage = [cutImage imageRotatedByRadians1x:M_PI * .5];
            }
            
        }
    }
    
    //Create the clipboard view
    clipboardView = [[FTClipboardImageTransformerContainerView alloc] initWithFrame:writingView.frame];
	clipboardView.delegate = self;
    clipboardView.clipboardMode = YES;
	[coverContainerView addSubview:clipboardView];
    
    clipboardView.sourceImage = cutImage;
    [self applyOrientationForClipboardView:[[UIApplication sharedApplication] statusBarOrientation]];

    [clipboardView setStartingFrame:[clipboardView convertRect:lassoSelectionView.selectionRect fromView:lassoSelectionView]];
    
    [self.lassoView resignFirstResponder];
    [self.lassoView removeFromSuperview];
    self.lassoView = nil;
    
    [self performSelector:@selector(delayedTransformCommand) withObject:nil afterDelay:0.001];
}

-(void)delayedTransformCommand{
    [writingView finalizeMoveOperation:NO];
}

-(void)lassoSelectionViewCutCommand:(LassoSelectionView *)lassoSelectionView{
    
    UIImage *cutImage = [writingView getSelectionAreaImage];
    if (!self.alwaysInPortrait) {
        UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation] forShelfItem:self.notebookShelfItem];
        if (UIInterfaceOrientationIsLandscape(layoutOrientation)) {
            if (writingView.isInverted) {
                cutImage = [cutImage imageRotatedByRadians1x:M_PI * -.5];
            }else{
                cutImage = [cutImage imageRotatedByRadians1x:M_PI * .5];
            }
            
        }
    }
    
    NSData *pngData = UIImagePNGRepresentation(cutImage);
    NSMutableDictionary *items = [NSMutableDictionary dictionary];
    [items setValue:[NSNumber numberWithBool:YES] forKey:@"NoteshelfPasteBoard"];
    [items setObject:pngData forKey:(NSString*)kUTTypePNG];
    [[UIPasteboard generalPasteboard] setItems:@[items]];

    [writingView finalizeMoveOperation:NO];
    
    [self.lassoView resignFirstResponder];
    [self.lassoView removeFromSuperview];
    self.lassoView = nil;
    
    [self switchMode:kDeskModePen];
}

-(void)lassoSelectionViewCopyCommand:(LassoSelectionView *)lassoSelectionView{
    
    UIImage *cutImage = [writingView getSelectionAreaImage];
    
    if (!self.alwaysInPortrait) {
        UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation] forShelfItem:self.notebookShelfItem];
        if (UIInterfaceOrientationIsLandscape(layoutOrientation)) {
            if (writingView.isInverted) {
                cutImage = [cutImage imageRotatedByRadians1x:M_PI * -.5];
            }else{
                cutImage = [cutImage imageRotatedByRadians1x:M_PI * .5];
            }
            
        }
    }
    
    
    NSMutableDictionary *items = [NSMutableDictionary dictionary];
    [items setValue:[NSNumber numberWithBool:YES] forKey:@"NoteshelfPasteBoard"];
    [items setObject:UIImagePNGRepresentation(cutImage) forKey:(NSString*)kUTTypePNG];
    [[UIPasteboard generalPasteboard] setItems:@[items]];

    [writingView finalizeMoveOperation:YES];
    
    [self.lassoView resignFirstResponder];
    [self.lassoView removeFromSuperview];
    self.lassoView = nil;
    
    [self switchMode:kDeskModePen];
}


-(BOOL)selectionOverlapsWithTextbox:(CGPathRef)selectionPath{
    FTNNotebookPage * page = [self getPageManagedObject:pageCurlView.currentPageIndex];
    
    if (!page) return NO;
    
    for (id<TextEntryProtocol> textEntry in page.textEntries) {
        //Check of selection area overlaps with the text entry
        CGRect rect = CGRectMake([textEntry.x floatValue], [textEntry.y floatValue], [textEntry.width floatValue], [textEntry.height floatValue]);
        
        if ([textEntry.isLandscape boolValue]) {
            if ([textEntry.isInverted boolValue]) {
                //rect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeRotation(M_PI * .5));
            }else{
                //rect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeRotation(M_PI * -.5));
            }
            
            rect = CGRectMake([textEntry.x floatValue], [textEntry.y floatValue], [textEntry.height floatValue], [textEntry.width floatValue]);
        }
        
        CGRect pathRect = CGPathGetBoundingBox(selectionPath);
        if (CGRectIntersectsRect(rect, pathRect)) return YES;
    }

    return NO;
}

-(void)raiseAlertForSelectionOverlapswithImageIfNeeded:(CGPathRef)cutPath
{
    BOOL imageHint = [[NSUserDefaults standardUserDefaults] boolForKey:@"SELECTION_TOOL_IMAGE_HINT_HIDE"];
    
    if (!imageHint) {
        if ([self selectionOverLapsWithImageAnnotations:cutPath]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"SelectionToolDoesNotSupportImage", @"Selection tool does not...") preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"DontShowHintAgain", @"Don't Show") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SELECTION_TOOL_IMAGE_HINT_HIDE"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }];
            [alertController addAction:action];
            
            UIAlertAction *otherAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:otherAction];

            [self presentViewController:alertController animated:YES completion:nil];

            //***************************************************
            //Flurry Info
            //***************************************************
            [Flurry logEvent:@"Lasso Operation - Image Warning" withParameters:nil];
            //***************************************************
            
            //***************************************************
            //Crashlytics Info
            //***************************************************
            
            CLSLog(@"Lasso Operation - Image Warning");
            
            //***************************************************
        }
    }
}
-(BOOL)selectionOverLapsWithImageAnnotations:(CGPathRef)selectionPath
{
    return NO;
}
#pragma mark General Clipboard Methods

-(BOOL)canBecomeFirstResponder{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL retValue = NO;
    
    if (action == @selector(pasteMenuAction2:) || action == @selector(newCutCopyMenuAction:)){
        retValue = YES;
        
    }
    
    return retValue;
}

- (void)pasteMenuAction2:(id)sender {
    
    if (self.lassoView) {
        [self.lassoView removeFromSuperview];
        self.lassoView = nil;
    }
    
    //Create the clipboard view
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    if ([pasteBoard containsPasteboardTypes:@[@"NoteshelfPasteBoard"]])
    {
        clipboardView = [[FTClipboardImageTransformerContainerView alloc] initWithFrame:writingView.frame];
        clipboardView.clipboardMode = YES;
        clipboardView.delegate = self;
        [coverContainerView addSubview:clipboardView];
        [self applyOrientationForClipboardView:[[UIApplication sharedApplication] statusBarOrientation]];
        
        
        UIMenuController *theMenu = [UIMenuController sharedMenuController];
        [theMenu setMenuVisible:NO animated:YES];
        
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        if (pasteBoard.image) {
            clipboardView.sourceImage = pasteBoard.image;
        }
    }
    else
    {
        self.photoView = [[ImageTransformerContainerView alloc] initWithFrame:writingView.frame];
        self.photoView.clipboardMode = YES;
        self.photoView.delegate = self;
        [coverContainerView addSubview:self.photoView];
        [self applyOrientationForPhotoPlacementView:[[UIApplication sharedApplication] statusBarOrientation]];
        
        
        UIMenuController *theMenu = [UIMenuController sharedMenuController];
        [theMenu setMenuVisible:NO animated:YES];
        
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        if (pasteBoard.image) {
            self.photoView.sourceImage = pasteBoard.image;
            self.photoView.imageScale = [[UIScreen mainScreen] scale];
            self.photoView.allowsResizing = YES;
            [self.photoView setEditing:NO];
            [self.photoView setAllowsEditing:YES];
            
        }
    }
}

-(void)newCutCopyMenuAction:(id)sender{
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    [theMenu setMenuVisible:NO animated:YES];
}

-(void)audioButtonAction:(id)sender
{
    [self normalizeDeskMode];
    [self showAudioListPopover:sender];
}

-(void)addAnnotationButtonAction:(id)sender
{

}

-(void)closeAddRackViewOnCompletion:(void(^)(BOOL))completionHandler
{
}

-(void) copyPasteButtonAction{
    if (lassoView) {
        if (lassoView.isSelectionActive) {
            [lassoView showMenuFromRect:[lassoView convertRect:deskToolbarView.theCopyPasteButton.bounds fromView:deskToolbarView.theCopyPasteButton]];
             return;
        }
    }
    
    
	[self normalizeDeskMode];
    
	if (deskMode == kDeskModeClipboard) {
        //[photoView finalizePhotoPlacement];
        return;
	}
    
    lassoView = [[LassoSelectionView alloc] initWithFrame:writingView.frame];
	lassoView.delegate = self;
	[coverContainerView addSubview:lassoView];
    //[self applyOrientationForClipboardView];
    
    
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    
    UIImage *imageInPastboard = nil;
    
    @try
    {
        imageInPastboard = pasteBoard.image;
    }
    @catch (NSException *exception)
    {
        [FTGoogleAnalytics logGoogleEventWithCategory:FTGoogleEventUnexpectedErrorNotificationsKey
                                               action:@"Pasteboard data corrupt"
                                                label:nil
                                                value:nil];
    }
    
    if (imageInPastboard) {
        
        [self becomeFirstResponder];
        
        UIMenuController *theMenu = [UIMenuController sharedMenuController];
        UIMenuItem *pasteMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Paste", @"Paste") action:@selector(pasteMenuAction2:)];
        UIMenuItem *newCutCopyMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"CutCopy", @"Cut / Copy") action:@selector(newCutCopyMenuAction:)];
        theMenu.menuItems = [NSArray arrayWithObjects:newCutCopyMenuItem, pasteMenuItem, nil];
        [theMenu setTargetRect:CGRectInset(self.deskToolbarView.theCopyPasteButton.bounds,10,10) inView:self.deskToolbarView.theCopyPasteButton];
        [theMenu setMenuVisible:YES animated:YES];
        
    }
    
	[self switchMode:kDeskModeClipboard];
	
}


- (void)applyOrientationForClipboardView:(UIInterfaceOrientation)interfaceOrientation{
    
    if (self.alwaysInPortrait) {
        clipboardView.frame = writingView.frame;
        return;
    }
    
    UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:interfaceOrientation forShelfItem:self.notebookShelfItem];
    if (UIInterfaceOrientationIsPortrait(layoutOrientation))
    {
        clipboardView.transform = CGAffineTransformMakeRotation(0);
    }
    else
    {
        
        if (writingView.isInverted) {
            clipboardView.transform = CGAffineTransformMakeRotation(M_PI * .5);
        }else{
            clipboardView.transform = CGAffineTransformMakeRotation(M_PI * -.5);
        }  
        
    }
    
    clipboardView.frame = writingView.frame;
}

-(void)performClipboardPlacement{
    
    self.view.userInteractionEnabled = NO;
    
    UIImage *imageToPlace = [clipboardView getTransformedImage];
    
    if (imageToPlace) {
        
        if (!self.alwaysInPortrait)
        {
            UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation] forShelfItem:self.notebookShelfItem];
            if (UIInterfaceOrientationIsLandscape(layoutOrientation))
            {
                if (writingView.isInverted)
                {
                    imageToPlace = [imageToPlace imageRotatedByRadians:M_PI * .5];
                }
                else
                {
                    imageToPlace = [imageToPlace imageRotatedByRadians:M_PI * -.5];
                }    
                
            }
        }
        
        CGRect targetRect = [writingView convertRect:[clipboardView getPlacementRect] fromView:clipboardView];
        
        [writingView putUIImage:imageToPlace inRect:targetRect replace:NO];
        [self addPageIfNeeded];
    }
    
    [clipboardView removeFromSuperview];
	self.clipboardView = nil;
    
    self.view.userInteractionEnabled = YES;
    
}

#pragma mark -
#pragma mark Memory Clean-up

-(void)releasePopoversIfNeeded{
	
	if (photosPopover != nil) {
        [photosPopover dismissViewControllerAnimated:YES completion:nil];
		self.photosPopover = nil;
		
	}
    
    [self dismissMoreActionsToolsControllerAnimate:NO];
    
}

- (void)dealloc {
    
    [self removeObservers];
    [[FTAudioAnnotationViewManager sharedManager] cleanUP];
    [self resignFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    for (FTNNotebookPage * aPage in notebook.pages) {
        [notebook turnPageToFault:aPage];
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#if iPEN_CREGLE_SUPPORTED
- (void)drawingsBegan:(NSArray*)drawingEvents withAccessory:(CRAccessory*)accessory
{
    [self.writingView drawingsBegan:drawingEvents withAccessory:accessory];
    
}
- (void)drawingsMoved:(NSArray*)drawingEvents withAccessory:(CRAccessory*)accessory
{
    [self.writingView drawingsMoved:drawingEvents withAccessory:accessory];
    
}
- (void)drawingsEnded:(NSArray*)drawingEvents withAccessory:(CRAccessory*)accessory
{
    [self.writingView drawingsEnded:drawingEvents withAccessory:accessory];

}
#endif

- (void)processPointRegisteredForShape:(CGPoint)newPoint vertexType:(VertexType)vertexType
{
    if (
        [[FTPenCollectionManager sharedCollectionManager] shapeDetectionEnabled] &&
        (deskMode != kDeskModeEraser)
        )
    {
        switch (vertexType)
        {
            case kFirstVertex:
            {
                self.shapeStroke = nil;
                self.shapeStroke = [[FTShapeStroke alloc] init];
                [self.shapeStroke addPoint:newPoint];
            }
                break;
                
            case kInterimVertex:
            {
                [self.shapeStroke addPoint:newPoint];
            }
                break;
                
            case kLastVertex:
            {
                [self.shapeStroke addPoint:newPoint];
                
                NSMutableArray *strokePoints = [self.shapeStroke shapePoints];
                if (strokePoints.count > 0)
                {
                    [self.writingView cancelCurrentRenderedStroke];
                    [strokePoints enumerateObjectsUsingBlock:^(NSMutableArray  *eachStrokePoints, NSUInteger idx, BOOL *stop)
                     {
                         [self.writingView renderPoints:eachStrokePoints];
                     }];
                }
                [self.shapeStroke clearAllPoints];
                self.shapeStroke = nil;
            }
                break;
                
            default:
                break;
        }

    }
}

-(FTNNotebookPage * )getPageManagedObjectForPageIndex:(NSInteger)index createIfNeeded:(BOOL)createIfNeeded
{
    FTNNotebookPage * pageManagedObject = [self getPageManagedObject:index];
    
    if (!pageManagedObject && createIfNeeded)
    {
        //Add the page if it does not exist
        self.currentPageImage = [writingView getUIImage];
        [self saveImageForPage:pageCurlView.currentPageIndex
                         image:self.currentPageImage
            backgroundSavePage:YES
       backgroundSaveThumbnail:YES
         onCompletion:nil];
        
        writingView.isDirty = NO;
        newPageCreationFlag = NO;
        pageCurlView.numberOfPages = notebook.pages.count+1;
        [self refreshPageNumbers];
        
        pageManagedObject = [self getPageManagedObject:pageCurlView.currentPageIndex];
    }
    return pageManagedObject;
}

-(void)didSelectAnnotationEntry:(id)annotationEntry eventType:(FTProcessEventType)eventType
{
}

#pragma mark gesture handler
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint locationInView = [touch locationInView:self.writingView];
    id annotation = nil;
    
    if(self.photoView)
    {
        UIView *view = [self.photoView hitTest:[touch locationInView:self.photoView] withEvent:nil];
        if (view != self.photoView) {
            return NO;
        }
    }
    
    NSArray *viewControllers = [[FTAudioAnnotationViewManager sharedManager] selectedViewControllers];
    for (FTAudioAnnotationViewController *eachController in viewControllers)
    {
        if (CGRectContainsPoint([eachController annotationRect], [touch locationInView:self.writingView]))
        {
            return NO;
        }
    }
    
    if (annotation)
    {
        return YES;
    }
    return NO;
}

-(void)singleTapGestureRecognized:(UITapGestureRecognizer*)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint locationInView = [gestureRecognizer locationInView:self.writingView];
        
    }
}

-(void)didLongTapped:(UILongPressGestureRecognizer*)pressGesture
{
    if (pressGesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint locationInView = [pressGesture locationInView:self.writingView];
        
    }
}

-(void)enableLongGesture
{
    self.longPressGesture.enabled = YES;
}

-(void)disableLongGesture
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(enableLongGesture) object:nil];
    self.longPressGesture.enabled = NO;
}

-(void)selectAnnotationEntry:(id)entry eventtype:(FTProcessEventType)eventType
{
    [self didSelectAnnotationEntry:entry eventType:eventType];
}

-(UIImage*)compositePageImage:(UIImage*)pageImage pageAtIndex:(NSInteger)pageIndex
{
    FTNNotebookPage * page = [self getPageManagedObject:pageIndex];
    
    UIImage *textLayerImage = nil;
    UIImage *annotationLayerImage = nil;
    UIImage *audioLayerImage = nil;
    
    if (page.textEntries.count > 0) {
       textLayerImage = [self getUIImageForTextLayer:pageIndex];
    }
    
    UIImage *baseImage = pageImage;
    
    if ([notebook annotationsForPage:page].count > 0) {
    }
    CGRect rect = CGRectMake(0, 0, baseImage.size.width/4.0, baseImage.size.height/4.0);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1.0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    
    if (annotationLayerImage) {
        [annotationLayerImage drawInRect:rect];
    }
    
    [baseImage drawInRect:rect];
    
    if (audioLayerImage) {
        [audioLayerImage drawInRect:rect];
    }
    
    if (textLayerImage) {
        [textLayerImage drawInRect:rect];
    }

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(void)didEndAllTouches:(NSNotification*)notification
{
    [self performSelector:@selector(enableLongGesture) withObject:nil afterDelay:0.3];
}

#pragma mark convert helper

-(void)showAlertPanelRegardingPhotoErase
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"ERASE_PHOTO_MSG_DONT_SHOW"])
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"ErasePhotoMsg", @"Photo cannot be earsed partially...") preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK") style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:action];
        
        
        UIAlertAction *otherAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"DontShowHintAgain",@"Don't Show") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ERASE_PHOTO_MSG_DONT_SHOW"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }];
        [alertController addAction:otherAction];

        [self presentViewController:alertController animated:YES completion:nil];
    }
}

-(BOOL)checkIfAnyImageAnnotationPresentAtPoint:(CGPoint)touchLocation
{
    BOOL hasAnnotation = NO;
    if (deskMode == kDeskModeEraser)
    {
    }
    return hasAnnotation;
}

#pragma mark Audio Related
-(void)showAudioListPopover:(UIView*)sender
{
    [self saveNotebookState:YES];

    FTAudioListViewController *audioListController = [[FTAudioListViewController alloc] initWithNibName:@"FTAudioListViewController" bundle:nil];
    audioListController.modalPresentationStyle = UIModalPresentationPopover;
    audioListController.preferredContentSize = CGSizeMake(420, 350);
    audioListController.delegate = self;
    audioListController.dataSource = self;
    
    [audioListController showPopoverOnViewController:self.view.window.rootViewController fromRect:sender.bounds onView:sender];
}

-(void)popoverDidDismiss:(FTAudioListViewController*)controller
{

}

-(void)deselectAudioButton
{
    if (zoomPanel) {
        [self zoomButtonAction];
    }
    [self closeAddRackViewOnCompletion:nil];
}

-(NSArray*)audioAnnotationsForController:(FTAudioListViewController*)controller
{
    NSArray *pages = self.notebook.pages;
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES];
    NSArray *allPages = [pages sortedArrayUsingDescriptors:@[descriptor]];
    NSMutableArray *audioAnnotations = [NSMutableArray array];
    
    [allPages enumerateObjectsUsingBlock:^(FTNNotebookPage * obj, NSUInteger idx, BOOL *stop) {
        
        [audioAnnotations addObjectsFromArray:[notebook annotationsForPage:obj ofType:FTPDFAnnotationTypeAudio]];
    }];
    
    return audioAnnotations;
}

-(id)currentlyVisiblePage
{
    FTNNotebookPage * page = [self getPageManagedObject:self.pageCurlView.currentPageIndex];
    return page;

}

#pragma mark Audio Export
-(void)showExportForAudioAnnotation:(FTAudioAnnotation*)annotation inRect:(CGRect)rect onView:(UIView*)sourceView
{
    SmartMessageView *smartMessage = [[SmartMessageView alloc] initWithFrame:self.view.bounds message:NSLocalizedString(@"Exporting", @"Exporting") style:kSmartMessageProgress];
    [self.view addSubview:smartMessage];
    
    [annotation prepareAnnotationForExportOnUpdate:^(float progress)
     {
         smartMessage.progressIndicator.progress = progress;
     }
                                      onCompletion:^(NSURL *fileURL, NSError *error)
     {
         [smartMessage removeFromSuperview];
         if(!error && fileURL)
         {
             self.audioShareInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
             self.audioShareInteractionController.delegate = self;
             self.audioShareInteractionController.name = @"Noteshelf Recording";
             [self.audioShareInteractionController presentOptionsMenuFromRect:rect inView:sourceView animated:YES];
         }
         else
         {
             UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"UnexpectedError", @"Unexpected error. Please try...") message:nil preferredStyle:UIAlertControllerStyleAlert];
             
             UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil];
             [alertController addAction:action];
             [self presentViewController:alertController animated:YES completion:nil];
         }
     }];
}

#pragma mark - Audio list Delegates -

-(void)didClickOnAnnotation:(FTAudioAnnotation*)annotation controller:(FTAudioListViewController*)controller
{
    FTNNotebookPage * page = annotation.associatedPage;
    if (page.pageIndex.integerValue == self.pageCurlView.currentPageIndex){
        [self selectAnnotationEntry:annotation eventtype:FTProcessEventTypeNone];
    }
    else{
        [[FTAudioAnnotationViewManager sharedManager] deSelectAllAnnotations:YES];
        [[FTAudioAnnotationViewManager sharedManager] showAudioControlForAnnoatation:annotation audioState:FTAudioStatePlaying];
    }
}

-(void)didClickOnExportButton:(FTAudioAnnotation*)annotation controller:(FTAudioListViewController*)controller
{
    [controller dismissControllerAnimated:YES completion:^
     {
         UIButton *button = self.deskToolbarView.addAnnotationButton;
         [self showExportForAudioAnnotation:annotation inRect:button.bounds onView:button];
     }];
}

-(void)didClickOnAddNewRecording:(FTAudioListViewController*)controller
{
    [controller dismissControllerAnimated:YES completion:^{
        [self deselectAudioButton];
        [self startNewRecording];
        
        if(zoomPanel || self.writingView.currentWritingMode == kTextMode ){
            [[FTAudioAnnotationViewManager sharedManager] deSelectAllAnnotations:NO];
        }
    }];
}

-(void)didClickOnContinueRecording:(FTAudioAnnotation*)annotation controller:(FTAudioListViewController*)controller
{
    [controller dismissControllerAnimated:YES completion:^{
        [self deselectAudioButton];
        [[FTAudioAnnotationViewManager sharedManager] showAudioControlForAnnoatation:annotation audioState:FTAudioStateRecording];
    }];
}


-(CGRect)finalBoundingRectForRect:(CGRect)inBoundingRect visibleBounds:(CGRect)inVisibleBounds
{
    const NSInteger kOverlappingThreshold = kAudioRecIconSize.width/2;
    __block CGRect boundingRect = inBoundingRect;
    __block CGPoint boundingRectOrigin = inBoundingRect.origin;
    
    FTNNotebookPage * page = [self getPageManagedObject:self.pageCurlView.currentPageIndex];
    if (page)
    {
        NSArray *annotations = [notebook annotationsForPage:page ofType:FTPDFAnnotationTypeAudio];
        boundingRect.origin = boundingRectOrigin;
    }
    return  boundingRect;
}

-(BOOL)isBoundingRectIntersectWithPageBoundary:(CGRect)boundingRect visibleRect:(CGRect)visibleRect
{
    BOOL isIntersect =  NO;
    
    if(CGRectGetMaxY(visibleRect) < CGRectGetMaxY(boundingRect)){
        isIntersect = YES;
    }
    else if(CGRectGetMaxX(visibleRect) < CGRectGetMaxX(boundingRect)){
        isIntersect = YES;
    }
    return isIntersect;
}

-(void)startNewRecording
{
}

-(void)addViewForAnnotation:(id)annotation eventType:(FTProcessEventType)eventtype
{
}

-(UIView*)parentViewForAudioAnnotation
{
    return self.writingView;
}

-(void)audioPlayerDidClose:(NSNotification*)notification
{
    [UIView animateWithDuration:0.1f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self animatePreRotation:[[UIApplication sharedApplication] statusBarOrientation]];
                     } completion:^(BOOL finished) {
                         
                     }];
    [[FTAudioAnnotationViewManager sharedManager] deSelectAllAnnotations:YES];
}

-(void)audioPlayerDidStopRecording:(NSNotification*)notification
{
    NSDictionary *usefInfo = notification.userInfo;
    FTAudioRecordingModel *model = usefInfo[FTAudioSessionAudioRecordingNotificationKey];
    FTAudioSessionEvent state = [[usefInfo valueForKey:FTAudioSessionEventNotificationKey] integerValue];
    if (state == FTAudioSessionDidStopRecording)
    {
    }
}

-(void)audioPlayerDidOpen:(NSNotification*)notification
{
    [UIView animateWithDuration:0.1f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self animatePreRotation:[[UIApplication sharedApplication] statusBarOrientation]];
                     } completion:^(BOOL finished) {
                         
                     }];
}

-(void)annotationDidDeselect:(id<FTAudioAnnotationProtocol>)annotation
{
}

-(void)annotationDidSelect:(id<FTAudioAnnotationProtocol>)annotation
{
    
}

-(void)annotationDidDelete:(id<FTAudioAnnotationProtocol>)annotation
{
}

-(void)annotation:(id<FTAudioAnnotationProtocol>)annotation didMoveToRect:(CGRect)newBoundingRect
{
    [annotation setBoundingRect:newBoundingRect];
}

- (void)annotationView:(FTAudioAnnotationViewController*)annotationViewController
              exportAs:(id<FTAudioAnnotationProtocol>)annotation
{
    CGRect rect = [self.writingView convertRect:annotationViewController.annotationRect fromView:annotationViewController.view];

    [self showExportForAudioAnnotation:(FTAudioAnnotation*)annotation inRect:rect onView:self.writingView];
}
-(void)applyOrientationForAudioAnnotation:(UIInterfaceOrientation)interfaceOrientation
{
    [[FTAudioAnnotationViewManager sharedManager] updateOrientation:interfaceOrientation alwaysInPortrait:self.alwaysInPortrait isInverted:writingView.isInverted];
}

-(void)refreshAnnotationsView
{
    FTNNotebookPage * page = [self getPageManagedObject:self.pageCurlView.currentPageIndex];

    UIInterfaceOrientation layoutOrientation = [FTNotebookUtils notebookLayoutOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation] forShelfItem:self.notebookShelfItem];
    [self applyOrientationForAudioAnnotation:layoutOrientation];
}

-(NSArray*)annotationHolderViews
{
    NSMutableArray *annotationHolderViews = [NSMutableArray array];
    return annotationHolderViews;
}

#pragma mark

-(void)addAnnotationsFromEntries:(NSArray*)annotationEntries
{
}

-(void)removeAnnotationsFromEntries:(NSArray*)annotationEntries
{
}

-(void)updateAnnotationsFromEntries:(NSArray*)annotationEntries
{
}

-(BOOL)alwaysInPortrait
{
    return self.notebookShelfItem.isPortraitBook;
}

#pragma mark UIDocumentInteractionControllerDelegate
- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    self.audioShareInteractionController = nil;
}

-(void)updatePageCurlImage
{
    NSInteger index = pageCurlView.currentPageIndex;
    if (index > 0) {
        index = index-1;
    }
}

-(FTBaseShelfItemsProvider*)shelfItemProvider
{
    return self.currentShelfItemProvider;
}

-(void)backgroundSave:(NSDictionary *)backgroundSaveDict notebook:(FTNNotebookDocument*)notebook
{
    @autoreleasepool {
        
        FTNNotebookPage *pageManagedObject = (FTNNotebookPage *) [backgroundSaveDict objectForKey:@"objectID"];
        
        //NSLog(@"Saving page: %d", [pageManagedObject.pageIndex intValue] + 1);
        
        BOOL savePage = [[backgroundSaveDict objectForKey:@"savePage"] boolValue];
        BOOL saveThumbnail = [[backgroundSaveDict objectForKey:@"saveThumbnail"] boolValue];
        
        UIImage *imageToSave = [backgroundSaveDict objectForKey:@"imageToSave"];
        
        if (savePage)
        {
            [pageManagedObject setPageContent:imageToSave];
        }
        if (saveThumbnail)
        {
            UIImage *baseThumbImage = imageToSave;
            UIImage *annotationLayerImage = [backgroundSaveDict objectForKey:@"annotationLayerImage"];
            
            if (annotationLayerImage)
            {
                baseThumbImage = [annotationLayerImage overlayImage:imageToSave];
            }
            UIImage *audioOverlayImage = [backgroundSaveDict objectForKey:@"annotationAudioLayerImage"];
            baseThumbImage = [baseThumbImage overlayImage:audioOverlayImage];
            
            UIImage *thumbnailImage = [baseThumbImage imageByScalingProportionallyToSize:CGSizeMake(baseThumbImage.size.width/(4*[UIScreen mainScreen].scale), baseThumbImage.size.height/(4*[UIScreen mainScreen].scale))];
            
            if (pageManagedObject.textEntries.count > 0)
            {
                [pageManagedObject setThumbnailImage:[thumbnailImage overlayImage:[backgroundSaveDict objectForKey:@"textLayerImage"]]];
            }
            else
            {
                [pageManagedObject setThumbnailImage:thumbnailImage];
            }
        }
        
        if(savePage)
        {
            if(self.notebookShelfItem.enSyncEnabled)
            {
                [FTENPublishManager recordSyncLog:[NSString stringWithFormat:@"User triggered background save of page (%ld of %lu) of notebook: %@", (long)(pageManagedObject.pageIndex.integerValue+1), (unsigned long)pageManagedObject.parentDocument.pages.count, self.notebookShelfItem.title]];
                
                [[FTENPublishManager sharedPublishManager] pageDidGetUpdated:pageManagedObject];
                [[FTENPublishManager sharedPublishManager] startPublishing];
                
            }
            [[FTCloudBackUpManager sharedCloudBackUpManager] shelfItemDidGetUpdated:self.notebookShelfItem];
        }
        
        //NSLog(@"backgroundSave:end");
    }
}

#pragma mark - FTDocumentDelegate methods
- (void)documentDidGetReloaded:(FTDocument *)document
{
    CLSLog(@"Document Did Reloaded");
    [self configureRenderView];
}

-(void)documentWillGetReloaded:(FTDocument *)document onCompletion:(void (^)())completionBLock
{
    CLSLog(@"Document Will Reloaded");
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [self normalizeDeskMode];
    [[FTAudioAnnotationViewManager sharedManager] deSelectAllAnnotations:YES];
    [self closeAddRackViewOnCompletion:^(BOOL success) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        if(completionBLock) {
            completionBLock();
        }
    }];
}

- (void)documentDidReceiveConflict:(FTDocument*)document conflictingVersions:(NSArray*)conflictingVersions
{
    CLSLog(@"Document in conflict");
    
    [self showConflict:document];
}

-(void)showConflict:(FTDocument*)document
{
    //This notification can come many times when document is open. So check if the conflict view controller is already shown. If so, just update the conflicting versions
    if([self.presentedViewController isEqual:self.conflictViewController])
    {
        [self.conflictViewController updateConflictingVersions];
    }
    else
    {
//       self.conflictViewController = [FTCloudDocumentConflictScreen conflictViewControllerForDocument:self.notebook];
//        self.conflictViewController.modalPresentationStyle = UIModalPresentationFormSheet;
//        [self presentViewController:self.conflictViewController animated:YES completion:nil];
    }
}
#pragma mark - Universal Settings
- (void)shelfThemeChanged {
    self.toolbarImageView.image = [FTShelfTheme currentTheme].toolbarImagePortrait;
}

- (void)openSettingsPageWithDefaultSetting:(NSString *)settingName {
    
    [self normalizeDeskMode];
    if(writingView.isDirty) {
        __block SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                             message:NSLocalizedString(@"SavingNotebook", @"Saving Notebook")
                                                                               style:kSmartMessageActivityIndicator];
        [self.view addSubview:smartMessageView];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveNotebookState:false onCompletion:^(BOOL success) {
                [smartMessageView removeFromSuperview];
                if(success) {
                    [self delayedOpenSettings:settingName];
                }
            }];
        });
        return;
    }
    else {
        [self delayedOpenSettings:settingName];
    }
}

-(void)delayedOpenSettings:(NSString *)settingName
{
    FTUniversalSettingsSplitViewController *settingsViewController = (FTUniversalSettingsSplitViewController *)[FTSettingsConstants.SettingsStoryboard instantiateViewControllerWithIdentifier: @"FTUniversalSettingsSplitViewController"];
    settingsViewController.modalPresentationStyle = UIModalPresentationCustom;
    if (self.isRegularClass) {
        if (!self.transitioningDelegate) {
            self.transitioningDelegate = [[FTSettingsSlideInPresentationManager alloc] init];
        }
        settingsViewController.transitioningDelegate = self.transitioningDelegate;
    }
//    settingsViewController.currentShelfProvider = self.currentShelfItemProvider;
    settingsViewController.settingsDelegate = self;
//    settingsViewController.notebookShelfItem = self.notebookShelfItem;
//    settingsViewController.notebookDocument = self.notebook;
//    settingsViewController.page = [self getPageManagedObject:pageCurlView.currentPageIndex];
    settingsViewController.currentSettingName = settingName;
    
    [self presentViewController:settingsViewController animated:YES completion:nil];
}
-(void)documentDidMoved:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //TODO: unloading should be moved, to document level
        for (FTNNotebookPage *eachPage in self.notebook.pages) {
            [eachPage unloadContents];
        }

        [self getWritingPositionForPage:pageCurlView.currentPageIndex];
        if (deskMode == kDeskModeText) {
        }
        [self refreshPageNumbers];
        [self refreshAnnotationsView];
    });
}

-(void)closeAudioPopover
{
    BOOL isAudioPopoverOpen = [self.view.window.rootViewController.presentedViewController isKindOfClass:[FTAudioListViewController class]];
    if(isAudioPopoverOpen && !self.view.window.rootViewController.presentedViewController.isBeingDismissed) {
        [self.view.window.rootViewController.presentedViewController dismissViewControllerAnimated:true completion:nil];
    }
}

#pragma mark -
#pragma mark Debugging Helpers

static int notebookCopyCounter = 50;

-(void)copyNotebookMultipleTimes{
    
    if (notebookCopyCounter) {
        self.view.userInteractionEnabled = NO;
        NSLog(@"Creating notebook %d", notebookCopyCounter);
        [self debuggingButtonAction1];
        notebookCopyCounter--;
    }else{
        self.view.userInteractionEnabled = YES;
    }
    
}

-(void)debuggingButtonAction1{
    
    [self normalizeDeskMode];
    [self saveNotebookState:YES];
    
    
    if (!self.notebook.pages.count) {
        
        SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                             message:@"No pages to copy"
                                                                               style:kSmartMessageJustText];
        self.view.userInteractionEnabled = NO;
        [self.view addSubview:smartMessageView];
        [smartMessageView dismissAfterInterval:1 delegate:self];
        
        return;
    }
    
    [self unloadInvisibleViews];
    
    SmartMessageView *copyMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                        message: [NSString stringWithFormat:@"Copy pages %d of %lu", 1, (unsigned long)self.notebook.pages.count]
                                                                          style:kSmartMessageProgress];
    
    
    
    copyMessageView.tag = SMART_MESSAGE_TAG;
    self.view.userInteractionEnabled = NO;
    [self.view addSubview:copyMessageView];
    
    currentExportPageIndex = 0;
    totalPagesForCopyPage = self.notebook.pages.count;
    
    ShelfItem *newShelfItem = [NSEntityDescription insertNewObjectForEntityForName:@"ShelfItem" inManagedObjectContext:[APP_DELEGATE managedObjectContext]];
    newShelfItem.uuid = [FTUtils GetUUID];
    newShelfItem.currentPageIndex = [NSNumber numberWithInt:0];
    newShelfItem.lastUpdated = self.notebookShelfItem.lastUpdated;
    newShelfItem.title = [NSString stringWithFormat:@"%@ Copy", self.notebookShelfItem.title];
    newShelfItem.theme = self.notebookShelfItem.theme;
    newShelfItem.type = self.notebookShelfItem.type;
    newShelfItem.orderOnShelf = self.notebookShelfItem.orderOnShelf;
    newShelfItem.passcodeNumber = nil;
    
    [APP_DELEGATE commitDataChanges];
    
    [self performSelector:@selector(copyPage:) withObject:newShelfItem afterDelay:0.001];
}

-(void)debuggingButtonAction2{
    
    [self normalizeDeskMode];
    [self saveNotebookState:YES];
    
    
    if (!self.notebook.pages.count) {
        
        SmartMessageView *smartMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                             message:@"No pages to copy"
                                                                               style:kSmartMessageJustText];
        self.view.userInteractionEnabled = NO;
        [self.view addSubview:smartMessageView];
        [smartMessageView dismissAfterInterval:1 delegate:self];
        
        return;
    }
    
    [self unloadInvisibleViews];
    
    SmartMessageView *copyMessageView = [[SmartMessageView alloc] initWithFrame:self.view.bounds
                                                                        message: [NSString stringWithFormat:@"Copy pages %d of %lu", 1, (unsigned long)self.notebook.pages.count]
                                                                          style:kSmartMessageProgress];
    
    
    
    copyMessageView.tag = SMART_MESSAGE_TAG;
    self.view.userInteractionEnabled = NO;
    [self.view addSubview:copyMessageView];
    
    currentExportPageIndex = 0;
    totalPagesForCopyPage = self.notebook.pages.count;
    
    //NSEnumerator *e = [self.shelfItemManagedObject.pages objectEnumerator];
    //FTNNotebookPage * page;
    
    //while (page = [e nextObject]) {
    //		NSLog(@"%@",[page pageIndex]);
    //}
    
    [self performSelector:@selector(copyPage:) withObject:nil afterDelay:0.001];
}

-(void)copyPage:(ShelfItem *)targetShelfItem
{
    FTNNotebookPage * pageToCopy = (FTNNotebookPage *)[self.notebook pageWithIndex:0];
    FTNNotebookPage * pageManagedObject = pageToCopy;
    
    if (targetShelfItem) {
        pageManagedObject.pageIndex = [NSNumber numberWithInteger:currentExportPageIndex];
    }else {
        pageManagedObject.pageIndex = [NSNumber numberWithInteger: (totalPagesForCopyPage + currentExportPageIndex) ];
    }
    
    [notebook saveWithCompletionHandler:nil];
    [notebook turnPageToFault:pageToCopy];
    [notebook turnPageToFault:pageManagedObject];
    
    pageCurlView.numberOfPages++;
    
    currentExportPageIndex++;
    
    SmartMessageView *copyMessageView = (SmartMessageView *)[self.view viewWithTag:SMART_MESSAGE_TAG];
    
    if (currentExportPageIndex < totalPagesForCopyPage) {
        copyMessageView.messageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"CopyingPageNofN",@"Copying pages %d of %d"), currentExportPageIndex, totalPagesForCopyPage];
        copyMessageView.progressIndicator.progress = (float)currentExportPageIndex/totalPagesForCopyPage;	
        [self performSelector:@selector(copyPage:) withObject:targetShelfItem afterDelay:0.001];
    }else {
        
        [self loadInvisibleViews];
        
        copyMessageView.progressIndicator.progress = 1.0;	
        copyMessageView.messageLabel.text = NSLocalizedString(@"CopyCompleted",@"Copy Complete");
        [copyMessageView dismissAfterInterval:1 delegate:self];
        
#if DEBUG
        if (notebookCopyCounter) {
            [self copyNotebookMultipleTimes];
        }
#endif
    }
    
}

#pragma mark - FinderRefactoring
- (void)refresh {
    [self configureRenderView];
    [self refreshPageNumbers];
    [self refreshAnnotationsView];
}

@end
