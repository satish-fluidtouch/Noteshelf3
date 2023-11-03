//
//  FTPDFRenderViewController.m
//  Noteshelf
//
//  Created by Amar Udupa on 7/3/13.
//
//
#import "FTPDFRenderViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>

#import "FTPDFExportView.h"

#import "FTAudioListViewController.h"

#import "Noteshelf-Swift.h"

#import "iRate.h"
#import "FTAudioUtils.h"
#import "FTAudioPlayerController.h"

@import FTRenderKit;

#define ASSIGNMENTS_PLIST @"Assignments.plist"

@interface FTOrientationChangeInfo : NSObject
@property(assign) CGRect photoEditRect;
@end

@implementation FTOrientationChangeInfo

@end

@interface FTPDFRenderViewController (ZoomRelated) <FTZoomOverlayViewControllerDelegate>

@end

@interface FTPDFRenderViewController (Audio)<FTAudioPlayerControllerProtocol>
- (void)addPlayerNotifications;
@end


@interface FTPDFRenderViewController (Accessibility)

-(void)performAccessibiltyUIUpdate;

@end

@interface FTPDFRenderViewController() <UIScrollViewDelegate,MFMailComposeViewControllerDelegate,UIGestureRecognizerDelegate,UIPopoverPresentationControllerDelegate,UIDocumentInteractionControllerDelegate,FTActiveStickyIndicatorDelegate,FTNoteshelfDocumentDelegate>
{
    BOOL savingInProgress;
}

@property (weak,readwrite) FTZoomOverlayViewController *zoomOverlayController;

@property (assign) BOOL forceLayout;
@property (assign) BOOL isPageScrollingByUser;
@property (assign) BOOL isViewLoadingFirstime;

@property (weak) UIWindow *currentWindow;
@property (strong) NSString *extDisplayID;

@property (weak) UITapGestureRecognizer *fourFingerGesture;

@property (nonatomic,assign) BOOL applePencilDoubleTapMsgShown;


@property (nonatomic,assign) CGSize oldSize;

@property (nonatomic,strong) NSTimer *autoscrollTimer;
@property (nonatomic, assign) BOOL autoscrollTimerSet;
@property (nonatomic,assign) CGRect previousTargetRect;

@property (nonatomic,assign) BOOL zoomTriggerredByRectSizing;
@property (nonatomic,assign) CGRect zoomRectAfterSizing;

#if !TARGET_OS_MACCATALYST
@property (strong) UIActivityViewController *audioShareInteractionController;
@property (assign) BOOL audioExportIsSendingToOtherApp;
#endif

@property (nonatomic,strong) FTCloudDocumentConflictScreen *conflictViewController;

//Audio player
@property (weak)FTAudioPlayerController *playerController;

@property (weak) FTNS1MigrationInfoView *migrationInfoView;

@property (assign) RKDeskMode lastSelectedMode;

//From .h
@property (strong) id<FTDocumentProtocol> pdfDocument;

@property(assign) CGPoint tappedPoint;

@property(assign) NSRange currentVisiblePageRange;

//@property (assign) NSInteger currentPageIndex;
@property (assign) NSUInteger currentPageIndexToBeShown;
@property (assign) CGFloat contentScaleInNormalMode;
@property (strong) FTPageNumberView *pageNumberLabel;

@end

@implementation FTPDFRenderViewController

@synthesize pdfDocument;
@synthesize mainScrollView = _mainScrollView;
@synthesize eachPageViewArray;
@synthesize selectedAnnotations;
@synthesize showPageImmediately;
@synthesize currentPageIndexToBeShown;
@synthesize returningFromFinder;
@synthesize zoomTriggerredByRectSizing;
@synthesize contentScaleInNormalMode;
@synthesize openCloseDocumentDelegate;
@synthesize textToolbarDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteringEditMode:) name:FTEnteringEditModeNotification object:nil];
        
        __block __weak FTPDFRenderViewController *weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:@"FTPressuePenActionChangedNotification"
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification * _Nonnull note)
         {
            RKAccessoryButtonAction eventType = [[note.userInfo objectForKey:@"PressurePenAction"] integerValue];
            [weakSelf pressurePenButtonAction:eventType];
        }];
    }
    return self;
}

- (id)initWithDocumentInfo:(FTDocumentOpenInfo*)documentInfo
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.pdfDocument = documentInfo.document;
        [self.pdfDocument addListner:self];
        [[self.pdfDocument localMetadataCache] setShapeDetectionEnabled:FALSE];
        NSInteger currentPageIndex = [[self.pdfDocument localMetadataCache] lastViewedPageIndex];
        if(documentInfo.currentPageIndex != -1) {
            currentPageIndex = documentInfo.currentPageIndex;
        }
        NSArray *pages = [self.pdfDocument pages];
        if(currentPageIndex >= pages.count) {
            currentPageIndex = (int)(pages.count-1);
        }

        self.currentPageIndexToBeShown = currentPageIndex;

        self.finderSearchOptions = [[FTFinderSearchOptions alloc] init];
        if(documentInfo.documentSearchResults != nil) {
            self.finderSearchOptions.documentSearchResults = documentInfo.documentSearchResults;
            [self.finderSearchOptions populateSearchPagesIfNeededWithDocument:self.pdfDocument];
        }
        self.openDocToken = documentInfo.documentOpenToken;
    }
    return self;
}
-(void)loadView
{
    //Universal Settings
    self.currentVisiblePageRange = NSMakeRange(NSNotFound, 0);
    self.showPageImmediately=YES;
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.view = view;
    view.autoresizesSubviews = YES;

    UIView *contentView = [[UIView alloc] initWithFrame:view.bounds];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.contentHolderView = contentView;
    [view addSubview:contentView];
    self.view.backgroundColor = [UIColor clearColor];
    [self updateBackgroundcolor];

    CGRect scrollViewFrame = self.contentHolderView.bounds;
    FTDocumentScrollView *scrollView = [[FTDocumentScrollView alloc] initWithFrame:scrollViewFrame];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [scrollView addInteraction:[[UIDropInteraction alloc] initWithDelegate:self]];

    [self.contentHolderView addSubview:scrollView];
    self.mainScrollView = scrollView;
    
    [self updatePageLayout];

    self.previousVisiblePageIndex = (self.pageLayoutType == FTPageLayoutVertical ? -1 : 0);

    self.previousDeskMode = -1;
    self.currentDeskMode = -1;
    
    self.eachPageViewArray = [NSMutableArray array];
    _oldSize = self.contentHolderView.bounds.size;
    
    //Pressure Stylus related
#if !TARGET_OS_MACCATALYST
    [PressurePenEngine sharedPressurePenEngine].delegate = self;
    [[PressurePenEngine sharedPressurePenEngine] start];
#endif
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disablePanDetection) name:FTPDFDisableGestures object:self.view.window];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentDidGetSecurityUpdate) name:@"FTDocumentDidGetSecurityUpdate" object:nil];
    
    FTNS1MigrationInfoView *infoView = [[FTNS1MigrationInfoView alloc] initWithFrame:CGRectMake(0, 0, self.contentHolderView.frame.size.width, 44)];
    infoView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.contentHolderView addSubview:infoView];
    self.migrationInfoView = infoView;
    [infoView updateInfoString:NSLocalizedString(@"NS1ContentsEditNotSupport", @"Handwriting from Noteshelf Classic can not be edited in Noteshelf 2")];
    self.migrationInfoView.hidden = true;
        
    [self addPlayerNotifications];
    
    [self addObserverForPageLayoutChange];
    
    [self addkeyboardListeners];
    self.mainScrollView.clipsToBounds = NO;
}

-(BOOL)prefersHomeIndicatorAutoHidden{
    return YES;
}

-(void)enablePanDetection{
    FTDocumentScrollView *scrollview = (FTDocumentScrollView*)self.mainScrollView;
    [scrollview enablePanDetection:[self allowsFreeGestureConditions]];
}

-(void)disablePanDetection{
    [(FTDocumentScrollView*)self.mainScrollView disablePanDetection];
    //TODO: Casuing issues where on double tap using apple pencil in text mode not creating text box.
    //    [self becomeFirstResponder];
}

- (void)performUndoOperation {
    [self undo];
}

- (void)performRedoOperation {
    [self redo];
}

-(void)disableUndoGestures {
    [[self undoRedoGestureDetector] enableDisableUndoGesturesWithValue:false];
}

-(void)enableUndoGestures {
    [[self undoRedoGestureDetector] enableDisableUndoGesturesWithValue:true];
}

- (BOOL)allowsFreeGestureConditions
{
    BOOL allowFreeScroll = false;
    if(self.isInZoomMode
       || self.pdfDocument.localMetadataCache.currentDeskMode == kDeskModeReadOnly
       || self.pdfDocument.localMetadataCache.currentDeskMode == kDeskModeView
       || [[NSUserDefaults standardUserDefaults] boolForKey:APPLE_PENCIL_ENABLED]) {
        allowFreeScroll = true;
    }
    return allowFreeScroll;
}

- (void)dealloc
{
#if DEBUG
    printf("\ndealloc : FTPDFRrenderViewController\n");
#endif
    [self.pdfDocument removeListner:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.mainScrollView.scrollViewDelegate = nil;
    [[FTWhiteboardDisplayManager shared] exitExternalScreen:self.currentWindow displayID:self.extDisplayID];

    [self removeObservers];
    NSArray<FTPageViewController*> *controllers = [self visiblePageViewControllers];
    for(FTPageViewController *eachController in controllers) {
        [self removeObserversForPage:eachController.pdfPage];
    }
    
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:APPLE_PENCIL_ENABLED];
    [self.playerController removeFromParentViewController];
    [self.playerController.view removeFromSuperview];

    [self removeBlurEffect:NO];
    [self willDellocate];
    [[FTNoteshelfDocumentManager shared] closeDocumentWithDocument:self.pdfDocument
                                                             token:self.openDocToken
                                                      onCompletion:nil];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.laserStrokeStorage = [[FTLaserStrokeStorage alloc] initWithParentView:self.view];
    
    self.contentScaleInNormalMode = 1.0f;
    self.isViewLoadingFirstime = true;
    [self logBookInformationWithIsOpen:true];
    [self addObservers];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:APPLE_PENCIL_ENABLED options:NSKeyValueObservingOptionNew context:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleForceToShowShelf:) name:@"FTForceToDisplayShelfWhenBookOpened" object:nil];
    
    [self performAccessibiltyUIUpdate];
    
    UITapGestureRecognizer *fourFingerGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleFourFingerGesture:)];
    fourFingerGesture.numberOfTouchesRequired = 4;
    fourFingerGesture.delegate = self;
    [self.contentHolderView addGestureRecognizer:fourFingerGesture];
    self.fourFingerGesture = fourFingerGesture;
    [self setUpUndoRedoGesture];
    [self configureShortcutActions];
    [self showToolbarShortcutControllerIfNeededWithMode:self.currentDeskMode];
    [self enableOrDisableNewPageCreationOptionsInsideDocument];
#if TARGET_OS_MACCATALYST
    // Fix for book opening glitch
    [self prepareViewToShow:false];
#endif
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
#if !TARGET_OS_MACCATALYST
    if(self.isViewLoadingFirstime && [self bookScaleAnim]) {
        self.isViewLoadingFirstime = false;
        [self prepareViewToShow:false];
        [self showNotebookInfoToast];
    }
#endif
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeNotebookInfoToast];
}

-(void)enableOrDisableNewPageCreationOptionsInsideDocument {
    if (self.currentDeskMode == kDeskModeReadOnly){
        [(FTDocumentScrollView*)self.mainScrollView disableNewPageCreationOptions];
    }
    else{
        [(FTDocumentScrollView*)self.mainScrollView enableNewPageCreationOptions];
    }
}

-(void)handleTwoFingerTap:(UITapGestureRecognizer *)tapGesture {
    [self showPageNavigator];
}

-(void)handleTwoFingerUndo:(UITapGestureRecognizer *)tapGesture {
    [self undo];
}

-(void)handleThreeFingerRedo:(UITapGestureRecognizer *)tapGesture {
    [self redo];
}

- (void)handleFourFingerGesture:(UITapGestureRecognizer *)gesture {
    [[NSNotificationCenter defaultCenter] postNotificationName:FTToggleToolbarModeNotificationName object:nil];
}

- (void)addChildViewController:(UIViewController *)childController {
    UIViewController *zoomController = self.zoomOverlayController;
    if(nil != zoomController) {
        [zoomController removeFromParentViewController];
    }
    [super addChildViewController:childController];
    if(nil != zoomController) {
        [super addChildViewController:zoomController];
    }
}

-(void)handleForceToShowShelf:(NSNotification*)notification {
    if([self.view.window isEqual:notification.object]) {
        [self backToShelfButtonAction: FTNormalAction with: self.shelfItemManagedObject.title];
    }
}

-(BOOL)prefersStatusBarHidden
{
    return [super prefersStatusBarHidden];
}

-(void)addObservers
{
    __block __weak FTPDFRenderViewController *weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:@"FTDocumentDidAddedPageIndices"
                                                      object:(id)self.pdfDocument
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note)
     {
        [weakSelf clearSearchOptionsInfo];
        [weakSelf.zoomOverlayController updateZoomOriginForCurrentPage];

        NSRange range = [weakSelf pageRangeAddingOffset:weakSelf.currentVisiblePageRange];
        NSArray *pageIndices = note.userInfo[@"pageIndices"];
        for (NSNumber *eachPageIndex in pageIndices) {
            NSInteger index = [eachPageIndex integerValue];
            [weakSelf.eachPageViewArray insertObject:[NSNull null] atIndex:index];
            if(NSLocationInRange(index, range)) {
                weakSelf.currentVisiblePageRange = NSMakeRange(NSNotFound, 0);
            }
        }
        [weakSelf updateContentSize];
        [weakSelf _loadVisiblePages:false];
        
        if(weakSelf.isInZoomMode) {
            [weakSelf.zoomOverlayController refreshZoomTargetRectWithForcibly:TRUE];
        }
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:@"FTDocumentDidRemovePageIndices"
                                                      object:(id)self.pdfDocument
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note)
     {
        [weakSelf clearSearchOptionsInfo];
        NSArray *pageIndices = note.userInfo[@"pageIndices"];
        NSRange range = [weakSelf pageRangeAddingOffset:weakSelf.currentVisiblePageRange];
        
        FTPageViewController *currentZoomedController = weakSelf.zoomOverlayController.currentPageController;
        BOOL shouldReloadZoomController = false;
        
        for (NSNumber *eachPageIndex in pageIndices) {
            NSInteger index = [eachPageIndex integerValue];
            FTPageViewController *viewContorller = [weakSelf.eachPageViewArray objectAtIndex:index];
            [weakSelf purgePageAtIndex:index forcibly:TRUE];
            if(viewContorller == currentZoomedController) {
                shouldReloadZoomController = true;
            }
            [weakSelf.eachPageViewArray removeObjectAtIndex:index];
            if(NSLocationInRange(index, range)) {
                weakSelf.currentVisiblePageRange = NSMakeRange(NSNotFound, 0);
            }
        }
        
        [weakSelf updateContentSize];
        [weakSelf _loadVisiblePages:false];
        
        if(weakSelf.isInZoomMode) {
            if(shouldReloadZoomController) {
                [weakSelf.zoomOverlayController setCurrentPage:weakSelf.firstPageController.pdfPage
                                                pageController:weakSelf.firstPageController];
            }
            else {
                [weakSelf.zoomOverlayController refreshZoomTargetRectWithForcibly:TRUE];
            }
        }
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:@"FTDocumentDidMovedPageIndices"
                                                      object:(id)self.pdfDocument
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note)
     {
        [weakSelf clearSearchOptionsInfo];
        [weakSelf.zoomOverlayController updateZoomOriginForCurrentPage];

        NSRange range = [weakSelf pageRangeAddingOffset:weakSelf.currentVisiblePageRange];
        NSArray *fromIndices = note.userInfo[@"fromIndices"];
        NSInteger toIndex = [note.userInfo[@"toIndex"] integerValue];

        FTPageViewController *currentController = weakSelf.firstPageController;
        [weakSelf movePagesFromIndexes: fromIndices toIndex: toIndex];
        weakSelf.currentVisiblePageRange = NSMakeRange(NSNotFound, 0);
        [weakSelf updateContentSize];
        [weakSelf.mainScrollView forceLayoutSubviews];
        [weakSelf showPageAtIndex:[weakSelf.eachPageViewArray indexOfObject:currentController]
                    forceReLayout:true
                          animate:false];
        if(weakSelf.isInZoomMode) {
            [weakSelf.zoomOverlayController refreshZoomTargetRectWithForcibly:TRUE];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:FTPageDidChangePageTemplateNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note)
     {
        id<FTPageProtocol> currentPage = note.object;
        if(currentPage.parentDocument == weakSelf.pdfDocument) {
            id<FTPageProtocol>zoomedPage = weakSelf.zoomOverlayController.currentPage;
            [weakSelf.zoomOverlayController updateZoomOriginForCurrentPage];
            NSRange range = [weakSelf pageRangeAddingOffset:weakSelf.currentVisiblePageRange];
            NSInteger pageIndex = currentPage.pageIndex;
            [weakSelf updateContentSize];
            [weakSelf.mainScrollView forceLayoutSubviews];
            [weakSelf purgePageAtIndex:pageIndex forcibly:TRUE];

            NSInteger curPageIndex = weakSelf.currentlyVisiblePage.pageIndex;
            if(weakSelf.isInZoomMode) {
                curPageIndex = zoomedPage.pageIndex;
            }
            if(NSLocationInRange(pageIndex, range)) {
                weakSelf.currentVisiblePageRange = NSMakeRange(NSNotFound, 0);
            }
            [weakSelf _loadVisiblePages:false];
            if(weakSelf.isInZoomMode) {
                [weakSelf.zoomOverlayController refreshZoomTargetRectWithForcibly:TRUE];
                if(zoomedPage == currentPage) {
                    FTPageViewController *controller = [weakSelf.eachPageViewArray objectAtIndex:pageIndex];
                    [weakSelf.zoomOverlayController setCurrentPage:zoomedPage pageController:controller];
                }
            }
        }
    }];
}
-(void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

-(void)addObserversForPage:(id<FTPageProtocol>)page
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePageAttributes:) name:FTPageDidUpdatedPropertiesNotification object:page];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pageDidReleased:) name:FTPageDidGetReleasedNotification object:page];
}

-(void)removeObserversForPage:(id<FTPageProtocol>)page
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTPageDidGetReleasedNotification object:page];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTPageDidUpdatedPropertiesNotification object:page];
}

-(void)prepareViewToShow:(BOOL)animate
{
    self.showPageImmediately = true;
    [self.eachPageViewArray removeAllObjects];
    
    NSArray *pages = [self.pdfDocument pages];
    for (NSInteger index =0; index < pages.count;index++) {
        [self.eachPageViewArray addObject:[NSNull null]];
    }
    [self updateContentSize];
    [self showPageAtIndex:self.currentPageIndexToBeShown
            forceReLayout:YES
                  animate:animate];
    [self updateContentOffsetPercentage];
}

-(void)updateContentSize
{
    id currentScrollViewDel = self.mainScrollView.scrollViewDelegate;
    self.mainScrollView.contentInset = UIEdgeInsetsZero;
    self.mainScrollView.scrollViewDelegate = nil;
    [self.pageLayoutHelper updateContentSizeWithPageCount:self.numberOfPages];
    self.mainScrollView.scrollViewDelegate = currentScrollViewDel;
}

-(BOOL)isInZoomMode
{
    return (nil != self.zoomOverlayController);
}

-(void)showZoomPanelIfNeeded
{
    if([[self.pdfDocument localMetadataCache] zoomModeEnabled] && !self.isInZoomMode) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(zoomButtonAction) object:nil];
        [self performSelector:@selector(zoomButtonAction) withObject:nil afterDelay:0.01];
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if(nil == self.currentWindow) {
        self.currentWindow = self.view.window;
        if(![self bookScaleAnim]) {
            [self prepareViewToShow:false];
        }
        self.mainScrollView.scrollViewDelegate = self;
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(nil == self.currentWindow) {
        self.currentWindow = self.view.window;
        self.mainScrollView.scrollViewDelegate = self;
    }
    [self switchMode:[[self.pdfDocument localMetadataCache] currentDeskMode]];
    [self configureSceneNotifications];
    [self checkForExternalScreens];
    [self validateMenuItems];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(self.pdfDocument.isJustCreatedWithQuickNote == false) {
            [self showQuickCreateInfoTipIfNeeded];
        }
    });

    [self becomeFirstResponder];
    [[FTLanguageResourceManager shared] warnLanguageSelectionIfNeededOnController:self];
    [self addPageNumberLabelToView];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(performLayout)
                                               object:nil];
    if(([self applicationState] != UIApplicationStateBackground) || self.pageLayoutType == FTPageLayoutHorizontal) {
        [self performLayout];
    }
    else {
        [self performSelector:@selector(performLayout) withObject:nil afterDelay:0.01];
    }
    [[self navigationController]setNavigationBarHidden:YES animated:NO];
    [[self toolTypeContainerVc] updatePositionOnScreenSizeChange];
}

-(void)performLayout
{
    CGFloat yoffset = 0;
    if(self.playerController && [self.playerController isExpanded]) {
//        yoffset += kAudioBarHeight;
    }
    yoffset = [self topPadding];
    CGRect contentHolderRect = CGRectMake(CGRectGetMinX(self.view.bounds), yoffset, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-yoffset);
    self.contentHolderView.frame = contentHolderRect;
    
    if(!CGSizeEqualToSize(_oldSize, self.contentHolderView.bounds.size) || self.forceLayout) {
        self.forceLayout = false;
        _oldSize =  self.contentHolderView.bounds.size;
        [self updateContentSizeAndMapOffset];
        [self updatePageFrame];
    }

    [self updateActiveEmojiViewFrame];
}

-(void)updateContentSizeAndMapOffset
{
    [self updateContentSize];
    self.mainScrollView.contentOffset = [self mappedContentOffset];
}

-(void)updatePageFrame
{
    if(self.eachPageViewArray.count != self.numberOfPages) {
        return;
    }
    for (NSInteger i = 0; i < self.numberOfPages;i++) {
        FTPageViewController *pageViewController = [self.eachPageViewArray objectAtIndex:i];
        if ((NSNull*)pageViewController != [NSNull null])
        {
            CGRect frame = [self frameFor:i];
            pageViewController.view.frame = frame;
        }
    }

}

#pragma mark - orientation support -
-(void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self updateContentOffsetPercentage];
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    if(self.exportPopoverController != nil) {
        [self.exportPopoverController.presentedViewController dismissViewControllerAnimated:false completion:nil];
        self.exportPopoverController = nil;
    }
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self willBeginTransitionToSize];
    [self updateContentOffsetPercentage];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performUILayoutAfterOrientationChange) object:nil];
    self.mainScrollView.scrollViewDelegate = nil;
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self.rackViewController dismissViewControllerAnimated:true completion:nil];
    
    if (nil != self.presentedViewController && ![self.presentedViewController isKindOfClass:[MFMailComposeViewController class]]) {
        if (([self.presentedViewController isKindOfClass:[UIImagePickerController class]])){
            UIImagePickerController *controller = (UIImagePickerController*)self.presentedViewController;
            if(controller.sourceType != UIImagePickerControllerSourceTypeCamera){
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
        else if ([self.presentedViewController isKindOfClass:[UINavigationController class]]) {
            UIViewController *controller = [[(UINavigationController*)self.presentedViewController viewControllers] firstObject];
            if(![controller shouldAvoidDismissOnSizeChange]) {
                [controller dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context)
     {
        self.mainScrollView.contentOffset = [self mappedContentOffset];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self didEndTransitionToSize];
        if([self applicationState] != UIApplicationStateBackground) {
            [self performUILayoutAfterOrientationChange];
        }
        else {
            [self performSelector:@selector(performUILayoutAfterOrientationChange) withObject:nil afterDelay:0.1];
        }
    }];
}

-(void)performUILayoutAfterOrientationChange
{
    self.mainScrollView.scrollViewDelegate = self;
    [self loadVisiblePages];
}

#pragma mark - paging of view -
-(void)showPageAtIndex:(NSInteger)pdfPageIndex
         forceReLayout:(BOOL)forceRelayout
               animate:(BOOL)animate
{
    BOOL shouldAnimate = animate;
    if(forceRelayout) {
        self.currentVisiblePageRange = NSMakeRange(NSNotFound, 0);
    }
    if((self.currentlyVisiblePage.pageIndex != pdfPageIndex) || forceRelayout) {
        id currentScrollViewDel = self.mainScrollView.scrollViewDelegate;
        if(forceRelayout) {
            CGPoint point = self.mainScrollView.contentOffset;
            self.mainScrollView.scrollViewDelegate = nil;
            self.mainScrollView.contentOffset=CGPointMake(point.x-1, point.y-1);
            self.mainScrollView.scrollViewDelegate = currentScrollViewDel;
        }
        CGRect pageFrame = [self frameFor:pdfPageIndex];
        pageFrame.origin.x = MIN(pageFrame.origin.x,self.mainScrollView.contentSize.width - self.mainScrollView.frame.size.width);
        pageFrame.origin.y = MIN(pageFrame.origin.y,self.mainScrollView.contentSize.height - self.mainScrollView.frame.size.height);
        NSInteger pageDifference = (self.currentlyVisiblePage.pageIndex - pdfPageIndex);
        if (labs(pageDifference) > 1){
            shouldAnimate = NO;
        }
        if (!shouldAnimate) {
            self.mainScrollView.scrollViewDelegate = nil;
            [self.mainScrollView setContentOffset:pageFrame.origin animated:shouldAnimate];
            self.mainScrollView.scrollViewDelegate = currentScrollViewDel;
            [self _loadVisiblePages:false];
        }
        else {
            [self.mainScrollView setContentOffset:pageFrame.origin animated:shouldAnimate];
        }
        [self triggerPageChangeNotification];
    }
}

-(void)showPageAtIndex:(NSInteger)pdfPageIndex forceReLayout:(BOOL)forceRelayout
{
    [self showPageAtIndex:pdfPageIndex forceReLayout:forceRelayout animate:true];
}

-(void)loadPageViewControllerInRange:(NSRange)range
{
    if(range.location == NSNotFound) {
        return;
    }
    
    NSRange offsetRange = [self pageRangeAddingOffset:range];
    NSInteger firstPage = offsetRange.location;
    NSInteger lastPage = NSMaxRange(offsetRange);

    // Purge anything before the first page
    for (NSInteger i=0; i<firstPage; i++) {
        [self purgePageAtIndex:i];
    }

    for (NSInteger i=firstPage; i < lastPage; i++) {
        [self loadPageAtIndex:i];
    }
    
    for (NSInteger i=lastPage; i<self.eachPageViewArray.count; i++) {
        [self purgePageAtIndex:i];
    }

    NSArray *pageControllers = [self visiblePageViewControllers];
    [self updateCurrentVisiblePageControllers:pageControllers];

    [self enablePanDetection];
    [self validateMenuItems];
}

-(void)updateCurrentVisiblePageControllers:(NSArray<FTPageViewController*>*)controllers
{
    BOOL shouldWakeUpRecognition = false;
    BOOL hasUnsavedChanges = self.pdfDocument.hasAnyUnsavedChanges;
    NSMutableArray<id<FTPageProtocol>> *unloadedPages = [NSMutableArray array];
    for (FTPageViewController *eachController in self.eachPageViewArray) {
        if((id)eachController != [NSNull null]) {
            FTNoteshelfPage *page = (FTNoteshelfPage *)eachController.pdfPage;
            shouldWakeUpRecognition = shouldWakeUpRecognition || [page canRecognizeHandwriting];
            [eachController updateThumbanailInBackground:YES];

            if([controllers containsObject:eachController]) {
                eachController.isCurrent = YES;
                eachController.showPageImmediately = self.showPageImmediately;
                eachController.returningFromFinder = self.returningFromFinder;

                [eachController layoutViewsIfNeeded];
                
                [eachController.scrollView updateGestureConditions];
                [eachController setMode:self.currentDeskMode];
                
                if(!eachController.scrollView.pinchGestureRecognizer.enabled) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:eachController.scrollView selector:@selector(unlockZoom) object:nil];
                    [eachController.scrollView performSelector:@selector(unlockZoom) withObject:nil afterDelay:0.02];
                }
                
                [self addObserversForPage:page];
            }
            else {
                eachController.isCurrent = NO;
                if(nil != page) {
                    [unloadedPages addObject:page];
                    [self removeObserversForPage:page];
                    [eachController updateScrollPositionBasedOnCurrentPageViewControllerIndex];
                }
            }
        }
    }
    self.showPageImmediately=NO;
    if(self.pageLayoutType == FTPageLayoutHorizontal) {
        [self updateCurrentVisiblePageForExternalDiplay];
    }
    
    if(hasUnsavedChanges) {
        __block __weak id<FTRecognitionHelper> document = (id<FTRecognitionHelper>)self.pdfDocument;
        [self.pdfDocument saveDocumentWithCompletionHandler:^(BOOL success) {
            if(success) {
                for(id<FTPageProtocol> eachPage in unloadedPages) {
                    [eachPage unloadContents];
                }
                if(shouldWakeUpRecognition) {
                    [[document recognitionHelper] wakeUpRecognitionHelperIfNeeded];
                    [[document visionRecognitionHelper] wakeUpVisionRecognitionHelperIfNeeded];
                }
            }
        }];
    }
}

-(NSArray<FTPageViewController*>*)visiblePageViewControllers
{
    return [self pageControllersInRange:self.currentVisiblePageRange];
}

-(NSArray<FTPageViewController*>*)visiblePageViewControllersWithOffset
{
    NSRange pageRange = [self pageRangeAddingOffset:self.currentVisiblePageRange];
    if(pageRange.location == NSNotFound) {
        return [self visiblePageViewControllers];
    }
    return [self pageControllersInRange:pageRange];
}

-(NSArray<FTPageViewController*>*)pageControllersInRange:(NSRange)range
{
    NSMutableArray *pageControllers = [NSMutableArray array];
    if(range.location != NSNotFound) {
        for(NSInteger index = range.location;index < NSMaxRange(range);index++) {
            if ([self.eachPageViewArray count] > index) { //TODO: Mahesh - Added condition for resolving crash, when swiping from bottom , for page creating
                FTPageViewController *controller = [self.eachPageViewArray objectAtIndex:index];
                if((id)controller != [NSNull null]) {
                    [pageControllers addObject:controller];
                }
            }
        }
    }
    return pageControllers;
}


- (FTPageViewController *_Nullable)pageController:(CGPoint)atPoint
{
    FTPageViewController *controller = nil;
    NSArray<FTPageViewController*> *controllers = [self visiblePageViewControllers];
    for(FTPageViewController *eachController in controllers) {
        if(CGRectContainsPoint(eachController.view.frame, atPoint)) {
            controller = eachController;
            break;
        }
    }
    return controller;
}

- (FTPageViewController *_Nullable)pageControllerFor:(id<FTPageProtocol> _Nonnull)page {
    FTPageViewController *controller = nil;
    NSArray<FTPageViewController*> *controllers = [self visiblePageViewControllersWithOffset];
    for(FTPageViewController *eachController in controllers) {
        if(eachController.pdfPage == page) {
            controller = eachController;
            break;
        }
    }
    return controller;
}

- (FTPageViewController *_Nullable)firstPageController;
{
    NSArray<FTPageViewController*> *visiblePagesVC = self.visiblePageViewControllers;
    CGRect visibleBounds = self.mainScrollView.visibleRect;
    __block FTPageViewController *pageController = nil;
    
    [visiblePagesVC enumerateObjectsUsingBlock:^(FTPageViewController *obj, NSUInteger idx, BOOL *stop) {
        CGRect pageRect = [obj.view frame];
        if(pageRect.origin.y < CGRectGetMidY(visibleBounds)) {
            pageController = obj;
        }
    }];
    if(nil == pageController) {
        pageController = [self.visiblePageViewControllers firstObject];
    }
    return pageController;
}

-(id<FTPageProtocol>)currentlyVisiblePage
{
    return [self firstPageController].pdfPage;
}

-(void)updateCurrentVisiblePageForExternalDiplay {
    if(nil != self.currentWindow) {
        self.extDisplayID = [[FTWhiteboardDisplayManager shared] setPageWithPage:self.currentlyVisiblePage
                                                                        onWindow:self.currentWindow
                                                            presentationDelegate:self];
    }
}

-(void)purgeAllPages
{
    for(NSInteger index=0;index<self.eachPageViewArray.count;index++) {
        [self purgePageAtIndex:index forcibly:TRUE];
    }
    self.currentVisiblePageRange = NSMakeRange(NSNotFound, 0);
}

-(void)purgePageAtIndex:(NSInteger)pageIndex forcibly:(BOOL)forcibly {
    if (pageIndex < 0 || pageIndex >= self.eachPageViewArray.count) {
        // If it's outside the range of what we have to display, then do nothing
        return;
    }
    
    // Remove a page from the scroll view and reset the container array
    FTPageViewController *pageViewController = [self.eachPageViewArray objectAtIndex:pageIndex];
    if ((NSNull*)pageViewController != [NSNull null]) {
        BOOL shouldPurge = (self.pageLayoutType == FTPageLayoutVertical) ? false : true;
        if(forcibly || (self.pageLayoutType == FTPageLayoutVertical
                        && self.zoomOverlayController.currentPageController != pageViewController)) {
            shouldPurge = true;
        }
        if(shouldPurge) {
            [NSObject cancelPreviousPerformRequestsWithTarget:pageViewController.scrollView selector:@selector(unlockZoom) object:nil];
            
            [self removeObserversForPage:pageViewController.pdfPage];
            
            [pageViewController.scrollView lockZoom];
            [pageViewController willMoveToParentViewController:nil];
            [pageViewController.view removeFromSuperview];
            [pageViewController removeFromParentViewController];
            [self.eachPageViewArray replaceObjectAtIndex:pageIndex withObject:[NSNull null]];
        }
    }
}

-(void)purgePageAtIndex:(NSInteger)pageIndex
{
    [self purgePageAtIndex:pageIndex forcibly:false];
}

-(void)loadPageAtIndex:(NSInteger)pageIndex
{
    if (pageIndex < 0 || pageIndex >= self.eachPageViewArray.count) {
        // If it's outside the range of what we have to display, then do nothing
        return;
    }
    
    // Load an individual page, first seeing if we've already loaded it
    FTPageViewController *pageViewController = [self.eachPageViewArray objectAtIndex:pageIndex];
    
    CGRect frame = [self frameFor:pageIndex];
    
    if (((NSNull*)pageViewController == [NSNull null]) && (pageIndex < [[self.pdfDocument pages] count]))
    {
        pageViewController = [[FTPageViewController alloc] initWithPage:[[self.pdfDocument pages] objectAtIndex:pageIndex] delegate:self];
        [self addChildViewController:pageViewController];
        [self.mainScrollView addPageView:pageViewController.view];
        [pageViewController didMoveToParentViewController:self];
        [self.eachPageViewArray replaceObjectAtIndex:pageIndex withObject:pageViewController];
    }
    
    pageViewController.view.frame = frame;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:pageViewController.scrollView selector:@selector(unlockZoom) object:nil];
    [pageViewController.scrollView lockZoom];
}

-(void)lazyLoadPDFPages
{
    NSRange pageRange = [self pageRangeAddingOffset:self.currentVisiblePageRange];
    if(pageRange.location == NSNotFound) {
        return;
    }

    for(NSInteger i = pageRange.location;i < NSMaxRange(pageRange);i++) {
        FTPageViewController *controller = [self.eachPageViewArray objectAtIndex:i];
        if((id)controller != [NSNull null]) {
            [controller loadPage];
            [controller.scrollView setNeedsLayout];
        }
    }
    if(self.pageLayoutType == FTPageLayoutHorizontal) {
        [self.zoomOverlayController setCurrentPage:self.firstPageController.pdfPage
                                    pageController:self.firstPageController];
    }
}

- (void)_loadVisiblePages:(BOOL)lazily {
    // First, determine which page is currently visible
    NSRange range = [self visiblePageRange];
    if(NSEqualRanges(range, self.currentVisiblePageRange)) {
        [self updateCurrentPageIndex];
        return;
    }
    self.currentVisiblePageRange = range;
    if(range.location != NSNotFound) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(lazyLoadPDFPages) object:nil];
        [self loadPageViewControllerInRange:range];
        if(lazily) {
            [self performSelector:@selector(lazyLoadPDFPages) withObject:nil afterDelay:0.1];
        }
        else {
            [self lazyLoadPDFPages];
        }
    }
    [self updateCurrentPageIndex];
}

-(void)updateCurrentPageIndex {
    [self updateContentOffsetPercentage];
    NSInteger curPageIndex = [[self currentlyVisiblePage] pageIndex];
    NSInteger prevStoredIndex = [[self.pdfDocument localMetadataCache] lastViewedPageIndex];
    if(curPageIndex != prevStoredIndex){
        [[self.pdfDocument localMetadataCache] setLastViewedPageIndex:curPageIndex];
        NSString *currentPageString = [NSString stringWithFormat:@"page %ld of %ld",curPageIndex+1,self.numberOfPages];
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, currentPageString);
    }
}

-(NSInteger)numberOfPages
{
    return self.pdfDocument.pages.count;
}

-(NSRange)visiblePageRange
{
    NSArray<NSNumber*> *pages = [self.pageLayoutHelper pagesIn:self.mainScrollView.visibleRect];
    NSRange range = NSMakeRange(NSNotFound, 0);
    if(pages.count > 0) {
        NSInteger minPageIndex = pages.firstObject.integerValue;
        NSInteger maxPageIndex = pages.firstObject.integerValue;
        for(NSNumber *eachNum in pages) {
            minPageIndex = MIN(minPageIndex, eachNum.integerValue);
            maxPageIndex = MAX(maxPageIndex, eachNum.integerValue);
        }
        if(maxPageIndex >= self.eachPageViewArray.count) {
            maxPageIndex = MIN(maxPageIndex,self.eachPageViewArray.count-1);
        }
        NSInteger firstPage = minPageIndex;
        NSInteger lastPage = maxPageIndex;
        range = NSMakeRange(firstPage, lastPage-firstPage+1);
    }
    return range;
}

-(NSRange)pageRangeAddingOffset:(NSRange)currentRange
{
    NSRange range = currentRange;
    if(range.location != NSNotFound) {
        NSInteger startIndex = range.location;
        NSInteger endIndex = NSMaxRange(range);
        
        NSInteger firstPage = MAX(startIndex - 1,0);
        NSInteger lastPage = MIN(endIndex,self.eachPageViewArray.count-1);
        
        range = NSMakeRange(firstPage, lastPage-firstPage+1);
    }
    return range;
}

- (void)loadVisiblePages {
    [self _loadVisiblePages:true];
}

- (NSInteger)getNewPageInsertIndex {
    
    NSInteger index = self.currentlyVisiblePage.pageIndex+1;
    CGPoint point = self.mainScrollView.contentOffset;
    if (self.addNewpageMode == FTRefreshMode) {
        if (self.pageLayoutType == FTPageLayoutHorizontal) {
            if (point.x > 0) {
                index = [self numberOfPages];
            } else {
                index = 0;
            }
        } else {
            if (point.y > 0) {
                index = [self numberOfPages];
            } else {
                index = 0;
            }
        }
    } else if (self.addNewpageMode == FTFinderPageMode) {
        index = [self numberOfPages];
    }
    return  index;
}

#pragma mark - UIScrollView Delegate
-(void)scrollViewScrollComplete {
    [self loadVisiblePages];
    if (self.pageLayoutType == FTPageLayoutVertical) {
        self.isPageScrollingByUser = false;
        [self handlePageChange];

        NSArray<FTPageViewController*> *visiblePages = [self visiblePageViewControllers];
        for(FTPageViewController *eachPage in visiblePages) {
            [eachPage.scrollView setNeedsLayout];
            [eachPage.scrollView layoutIfNeeded];
        }
    }
    [self triggerPageChangeNotification];
    if(self.pageLayoutHelper.layoutType == FTPageLayoutHorizontal) {
        [self setCurrentPageNoToPageNumberLabel];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (self.pageLayoutType == FTPageLayoutHorizontal) {
        [self handlePageChange];
    }
    [self scrollViewScrollComplete];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate) {
        [self scrollViewScrollComplete];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if(self.pageLayoutType == FTPageLayoutVertical) {
        [self scrollViewScrollComplete];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.pageLayoutType == FTPageLayoutVertical) {
        self.previousVisiblePageIndex = self.currentlyVisiblePage.pageIndex;
        self.isPageScrollingByUser = true;
    }
    NSArray<FTPageViewController*>* visiblePageControllers = [self visiblePageViewControllers];
    for(FTPageViewController *eachPageVC in visiblePageControllers) {
        [eachPageVC startAcceptingTouches:false];
    }
    [FTQuickPageNavigatorViewController showPageNavigatorOnController:self];
    //    [self scrollViewDidBeginScrolling];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(self.pageLayoutHelper.layoutType == FTPageLayoutVertical) {
        [self setCurrentPageNoToPageNumberLabel];
    }
    if(!self.mainScrollView.isZoomingInProgress && self.pageLayoutHelper.layoutType == FTPageLayoutVertical) {
        [self loadVisiblePages];
        NSArray *eachPageController = [self visiblePageViewControllers];
        for(FTPageViewController *controller in eachPageController) {
            [controller setContentOffset:scrollView.contentOffset];
        }
        if (self.isPageScrollingByUser) {
            [self handlePageChange];
        }
        else {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(triggerPageChangeNotification) object:nil];
            [self performSelector:@selector(triggerPageChangeNotification) withObject:nil afterDelay:0.1];
        }
        [self updateCurrentVisiblePageForExternalDiplay];
        if (self.isPageScrollingByUser) {
            [self _scrollViewDidScrollWithScrollView:scrollView];
        }
    }
}

#pragma mark - saveChanges -
-(void)saveChangesOnCompletion:(void (^)(BOOL success) )completion
           shouldCloseDocument:(BOOL)shouldClose
       shouldGenerateThumbnail:(BOOL)generateThumbnail {
    [self saveChangesOnCompletion:completion
              shouldCloseDocument:shouldClose
                    waitUntilSave: false
          shouldGenerateThumbnail:generateThumbnail];
}

-(void)saveChangesOnCompletion:(void (^)(BOOL success) )completion
           shouldCloseDocument:(BOOL)shouldClose
                 waitUntilSave:(BOOL)waitUntilDone
       shouldGenerateThumbnail:(BOOL)generateThumbnail
{
    [[self.pdfDocument localMetadataCache] saveMetadataCache];
    
    NSArray<FTPageViewController*> *visiblePageController = self.visiblePageViewControllers;

    id<FTDocumentProtocol>documentToSave = self.pdfDocument;
    NSURL *docURL = documentToSave.URL;
    FTDocumentOpenToken *token = self.openDocToken;
    
    void (^blocktoExecute)(void) = ^{
        FTENPublishManager *evernotePublishManager = [FTENPublishManager shared];
        if([evernotePublishManager isSyncEnabledForDocumentUUID:self.shelfItemManagedObject.documentUUID]) {
            [FTENPublishManager recordSyncLog:[NSString stringWithFormat:@"User is saving notebook: %@", self.shelfItemManagedObject.title]];
            
            [evernotePublishManager updateSyncRecordForShelfItemAtURL:self.shelfItemManagedObject.URL withDocumentUUID:[documentToSave documentUUID] andEnSyncEnabled:true];
            [evernotePublishManager updateSyncRecordForShelfItemAtURL:self.shelfItemManagedObject.URL withDeleteOption:true andAccountType:EvernoteAccountTypeEvernoteAccountUnknown];
        }
        
        if(![documentToSave hasAnyUnsavedChanges]) {
            if(shouldClose) {
                [[FTNoteshelfDocumentManager shared] closeDocumentWithDocument:documentToSave token:token onCompletion:completion];
            }
            else {
                if(completion) {
                    completion(true);
                }
            }
            return;
        }
        
        if(generateThumbnail) {
            for(FTPageViewController *eachController in visiblePageController) {
                [eachController updateThumbanailInBackground:TRUE];
            }
        }

        if (!waitUntilDone) {
            [self documentWillStartSaving:documentToSave];
            if(nil != completion) {
                completion(true);
            }
        }
        
        BOOL shouldGenerateThumbnail = [documentToSave shouldGenerateCoverThumbnail];
        UIBackgroundTaskIdentifier task = [self startBackgroundTask];
        
        void(^continueSaving)(BOOL, UIImage*) = ^(BOOL coverPageUpdated, UIImage* coverImage){
            void (^onCompletionBlock)(BOOL) = ^(BOOL success){
                if(coverPageUpdated) {
                    [[FTURLReadThumbnailManager sharedInstance] addImageToCacheWithImage:coverImage url:docURL];
                    [FTRecentEntries updateImageInGroupContainerForUrl:docURL];
                }
                [documentToSave resetPageModificationStatus];
                if (waitUntilDone && (nil != completion)) {
                    completion(success);
                }
                [self endBackgroundTask:task];
                if(shouldClose) {
                    [self postDocumentUpdateNotification];
                }
            };

            if(shouldClose) {
                [[FTNoteshelfDocumentManager shared] saveAndCloseWithDocument:documentToSave
                                                                        token:self.openDocToken
                                                                 onCompletion:^(BOOL success) {
                    [[FTCloudBackUpManager shared] startPublish];
                    if(nil != onCompletionBlock) {
                        onCompletionBlock(success);
                    }
                }];
            }
            else {
                [documentToSave saveDocumentWithCompletionHandler:onCompletionBlock];
            }
        };
        
        if(shouldGenerateThumbnail) {
            [self coverImage:documentToSave
                  background:!waitUntilDone
                onCompletion:^(UIImage *image) {
                documentToSave.shelfImage = image;
                continueSaving(true, image);
            }];
        }
        else {
            continueSaving(false, nil);
        }
    };
    
    if(shouldClose) {
        [self canMoveToShelf:^(BOOL success) {
            if(success) {
                self.mainScrollView.scrollViewDelegate = nil;
                blocktoExecute();
            }
            else {
                if(completion){
                    completion(false);
                }
            }
        }];
    }
    else {
        blocktoExecute();
    }
}


-(void)coverImage:(id<FTDocumentProtocol>)document
       background:(BOOL)inBackground
     onCompletion:(void (^)(UIImage *image))completion
{
        if(inBackground) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self coverImage:document
                      background:false
                    onCompletion:^(UIImage *image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(image);
                    });
                }];
            });
        }
        else {
            UIImage *newImage = [(id<FTDocumentCoverPage>)document generateCoverImage];
            completion(newImage);
        }
}

-(UIBackgroundTaskIdentifier)startBackgroundTask
{
    __block UIBackgroundTaskIdentifier task = UIBackgroundTaskInvalid;
    task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you.
        // stopped or ending the task outright.
        [[UIApplication sharedApplication] endBackgroundTask:task];
    }];
    return task;
}

-(void)endBackgroundTask:(UIBackgroundTaskIdentifier)task
{
    if(task != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:task];
    }
}

#pragma mark - desktoolbar menu items -
-(void)delayedSave: (FTNotebookBackAction)backAction with: (NSString *)title
{
    FTLoadingIndicatorViewController *loadingIndicator;
    
    
    BOOL isRequiredLoader = YES;
    isRequiredLoader = NO;//[self.pdfDocument hasAnyUnsavedChanges] ? YES : NO;

    NSString *fileName = self.shelfItemManagedObject.URL.lastPathComponent.stringByDeletingPathExtension;
    if(backAction == FTSaveAction && [title isEqualToString:fileName]) {
        backAction = FTNormalAction;
    }
    isRequiredLoader = (backAction == FTSaveAction);
    
    if (isRequiredLoader) {
        loadingIndicator = [FTLoadingIndicatorViewController showOnMode:FTLoadingIndicatorStyleActivityIndicator from:[self loadingPresentController]
                                                               withText:NSLocalizedString(@"Saving", @"Saving...") andDelay:0];
    }
    
    [self logBookInformationWithIsOpen:false];
    
    [self cancelAllThumbnailGeneration];
    
    NSArray *visiblePageControllers = [self visiblePageViewControllers];
    [visiblePageControllers enumerateObjectsUsingBlock:^(FTPageViewController  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.scrollView.shouldCreateViewAfterZooming = NO;
    }];
    [self normalizeAndEndEditingAnnotation:YES];
    
    //Pressure Stylus related
    [self unregisterViewForTouchEvents:NO];
#if !TARGET_OS_MACCATALYST
    [PressurePenEngine sharedPressurePenEngine].delegate = nil;
#endif
    //IF the action is delete, do not save directly delete and close
    // If the action is save and no rename to make then save and exit as in production
    //if the action is save and rename then wait till save complete , wait till rename and then exit
    
    [self saveChangesOnCompletion:^(BOOL success) {
        //***************************************************
        // Core Spotlight registration
        //***************************************************
        FTDocumentItemSpotLightWrapper *object = [[FTDocumentItemSpotLightWrapper alloc] initWithDocumentItem:self.shelfItemManagedObject.documentItem];
        [[FTSearchIndexManager sharedManager] updateSearchIndex:object completion:nil];
        //***************************************************
        
        void (^callBack)(void) = ^ {
            [self closeDocumentWithShelfItemManagedObject:self.shelfItemManagedObject animate:true onCompletion: ^{
                
            }];
            [FTiRateManager logEvent];
            if (loadingIndicator) {
                [loadingIndicator hide:nil];
            }
            [[FTENPublishManager shared] startPublishing];
        };
        if(backAction == FTSaveAction) {
            [self renameShelfItemWithTitle:title onCompletion: ^(BOOL success) {
                callBack();
            }];
        }
        else if(backAction == FTDeletePermanentlyAction || backAction == FTMoveToTrashAction) {
            [self deleteShelfItem:(backAction == FTDeletePermanentlyAction)];
            callBack();
        }
        else {
            callBack();
        }
    }
              shouldCloseDocument:true
                    waitUntilSave:isRequiredLoader
          shouldGenerateThumbnail:YES];
}

#pragma mark - Button actions -
-(void) backToShelfButtonAction: (FTNotebookBackAction)backAction with: (NSString*)title {
    if(savingInProgress) {
        FTLogError(@"multi_close",nil);
        return;
    }
    [self canMoveToShelf:^(BOOL canMove) {
        if(canMove){
            self->savingInProgress = true;
            FTCLSLog(@"PDF Document close");

            [FTiRateManager logEvent];

            NSArray *visiblePageControllers = [self visiblePageViewControllers];
            [visiblePageControllers enumerateObjectsUsingBlock:^(FTPageViewController  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.scrollView.delegate = nil;
                [obj unZoomIfNeededWithAnimate:YES completionBlock:nil];
            }];
            self.mainScrollView.scrollViewDelegate = nil;
            [self.mainScrollView setZoomScale:self.mainScrollView.minimumZoomScale animated:false];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.001 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self delayedSave:backAction with: title];
            });
            
        }
    }];
}

-(void)clearPageButtonAction
{
    [self normalizeAndEndEditingAnnotation:YES];
    [self.firstPageController clearPage];
}

-(void)undoButtonAction
{
    [self normalizeAndEndEditingAnnotation:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:FTWillPerformUndoRedoActionNotification object:self.undoManager];
    [self.undoManager undo];
}

-(void)redoButtonAction
{
    [self normalizeAndEndEditingAnnotation:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:FTWillPerformUndoRedoActionNotification object:self.undoManager];
    [self.undoManager redo];
}
-(void)shapesButtonAction
{
    if (!self.shapesToolEnabled) {
        [[self.pdfDocument localMetadataCache] setShapeDetectionEnabled:![[self.pdfDocument localMetadataCache] shapeDetectionEnabled]];
    }
    [self switchMode:kDeskModeShape];
}
-(void)penButtonAction
{
    [self switchMode:kDeskModePen];
}

-(void)laserButtonAction {
    [self switchMode:kDeskModeLaser];
}

-(void)markerButtonAction
{
    [self switchMode:kDeskModeMarker];
}

-(void)eraserButtonAction
{
    [self switchMode:kDeskModeEraser];
}

-(void)lassoButtonAction
{
    //    [self trackEraserToolSelectionEventIfNeeded];
    [self switchMode:kDeskModeClipboard];
}


-(void)iconsButtonAction
{
    [self switchMode:kDeskModeStickers];
}
-(void)presenterButtonAction{
    [self switchMode:kDeskModeLaser];
}

-(void)audioButtonAction
{
    [self deselectAudioButton];
    
    __block __weak FTPDFRenderViewController *weakSelf = self;
    [FTPermissionManager isMicrophoneAvailableOnViewController:self
                                                  onCompletion:^(BOOL success) {
        if(success) {
            [weakSelf startNewRecording];
        }
    }];
}

-(void)textButtonAction
{
    if (self.currentDeskMode == kDeskModeText) {
        return;
    }
    track(@"toolbar_textmode_tapped", nil,  [NSString stringWithFormat:@"%@",[FTScreenNames textbox]]);
    [self switchMode:kDeskModeText];
}

-(void)readOnlyButtonAction{
    self.readOnlyModeisOn = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FTPDFReadOnlyMode" object:self.view.window userInfo:@{@"isOn" : @TRUE}];
    [(FTDocumentScrollView*)self.mainScrollView disableNewPageCreationOptions];
    [self switchMode:kDeskModeReadOnly];
}


-(void)settingsButtonAction
{
    [self normalizeAnyPresentedViewController:TRUE onCompletion:^{
        [self openSettingsPage];
    }];
}

-(void)audioAction
{
    [self didTapAudio];
}

-(void)zoomButtonAction
{
    [self normalizeAndEndEditingAnnotation:YES];
    if (self.pageLayoutType == FTPageLayoutVertical) {
        [self.mainScrollView zoom:1 animate:true completionBlock:^{
            [self delayedZoomButtonAction];
        }];
    }
    else {
        [[self firstPageController] unZoomIfNeededWithAnimate:YES completionBlock:^{
            [self delayedZoomButtonAction];
        }];
    }
}

-(void)finderButtonAction:(BOOL)animated
{
    if([self.pdfDocument pages].count > 0)
    {
        [self normalizeAndEndEditingAnnotation:YES];
        if([(FTNoteshelfPage *)(self.firstPageController.pdfPage) canRecognizeHandwriting]){
            id<FTRecognitionHelper> document = (id<FTRecognitionHelper>)self.pdfDocument;
            [[document recognitionHelper] wakeUpRecognitionHelperIfNeeded];
            [[document visionRecognitionHelper] wakeUpVisionRecognitionHelperIfNeeded];
        }
        
        [self saveDocumentIfNeeded];
        [self toggleFinder:animated];
    }
}

-(void)saveDocumentIfNeeded
{
    NSArray *visibleControllers = [self visiblePageViewControllers];
    BOOL shouldSave = false;
    for(FTPageViewController *eachController in visibleControllers) {
        shouldSave = eachController.pdfPage.isDirty;
        if(shouldSave) {
            break;
        }
    }
    if(shouldSave || self.pdfDocument.hasAnyUnsavedChanges) {
        [self.pdfDocument saveDocumentWithCompletionHandler:nil];
    }
}

#pragma mark - Mode change -
-(void)switchMode:(RKDeskMode)mode
{
    UIView *sourceView = nil;
    switch (mode) {
        case kDeskModePen:
            sourceView = [self centerPanelToolbarSourceFor:FTDeskCenterPanelToolPen];
            break;
        case kDeskModeMarker:
            sourceView = [self centerPanelToolbarSourceFor:FTDeskCenterPanelToolHighlighter];
            break;
        case kDeskModeEraser:
            sourceView = [self centerPanelToolbarSourceFor:FTDeskCenterPanelToolEraser];
            break;
        case kDeskModeClipboard: // lasso
            sourceView = [self centerPanelToolbarSourceFor:FTDeskCenterPanelToolLasso];
            break;
        case kDeskModeShape:
            sourceView = [self centerPanelToolbarSourceFor:FTDeskCenterPanelToolShapes];
            break;
        case kDeskModeLaser:
            sourceView = [self centerPanelToolbarSourceFor:FTDeskCenterPanelToolPresenter];
            break;
        default:
            break;
    }

    [super switchMode:mode sourceView:sourceView];
    [self updateMigrationInfoView];
}

-(void)openRackForMode:(RKDeskMode)mode sourceView:(UIView *)sourceView {
    [super openRackForMode:mode sourceView:sourceView];
    [self normalizeAndEndEditingAnnotation:TRUE];
}

-(void)closeRackForMode:(RKDeskMode)mode
{
    [super closeRackForMode:mode];
    if(mode == kDeskModeStickers) {
        [self.activeStickyIndicatorView.view removeFromSuperview];
        self.activeStickyIndicatorView = nil;
    }
    if(mode == kDeskModeShape){ // turning off the shape detection
        [[self.pdfDocument localMetadataCache] setShapeDetectionEnabled:FALSE];
    }
}

-(void)endActiveEditingAnnotations
{
    NSArray *visibleControllers = [self visiblePageViewControllers];
    for(FTPageViewController *eachController in visibleControllers) {
        [eachController endEditingActiveAnnotation:nil refreshView:YES];
    }
}

-(BOOL)shouldRemoveShapeEditController
{
    BOOL shouldRemoveVC = false;
    NSArray *visibleControllers = [self visiblePageViewControllers];
    for(FTPageViewController *eachController in visibleControllers) {
        if ([eachController.activeAnnotationController isKindOfClass:[FTShapeAnnotationController class]]) {
            shouldRemoveVC = true;
            break;
        }
    }
    return shouldRemoveVC;
}

-(void)changeMode:(RKDeskMode)mode
{
    if(mode != self.currentDeskMode) {
        self.lastSelectedMode = self.currentDeskMode;
        if (self.shouldRemoveShapeEditController) {
            [self endActiveEditingAnnotations];
        }
        [self showToolbarShortcutControllerIfNeededWithMode: mode];
    }
    [super changeMode:mode];
    
    switch (self.currentDeskMode)
    {
        case kDeskModePhoto:
        case kDeskModeText:
        {
            if(mode != kDeskModeText) {
                [self endActiveEditingAnnotations];
            }
        }
            break;
        default:
            break;
    }
    switch (mode) {
        case kDeskModeLaser:
        {
            [[self.pdfDocument localMetadataCache] setCurrentDeskMode:mode];
        }
            break;
        case kDeskModePen:
        case kDeskModeMarker:
        case kDeskModeShape:
        {
            [self.pdfDocument.localMetadataCache setLastPenMode:mode];
            FTRackType rackType = FTRackTypeHighlighter;
            if(mode == kDeskModePen) {
                rackType = FTRackTypePen;
            }
            if (mode == kDeskModeShape){
                rackType = FTRackTypeShape;
                if (!self.shapesToolEnabled) {
                    [[self.pdfDocument localMetadataCache] setShapeDetectionEnabled:![[self.pdfDocument localMetadataCache] shapeDetectionEnabled]];
                }
            }
        }
        case kDeskModeEraser:
        {
            [[self.pdfDocument localMetadataCache] setCurrentDeskMode:mode];
        }
            break;
            
        case kDeskModePhoto:
        case kDeskModeText:
        {
            if(mode == kDeskModeText) {
                [[self.pdfDocument localMetadataCache] setCurrentDeskMode:mode];
            }
            if(self.isInZoomMode) {
                [self zoomButtonAction];
            }
        }
            break;
        case kDeskModeClipboard:
        {
            if(self.isInZoomMode) {
                [self zoomButtonAction];
            }
        }
            break;
        case kDeskModeStickers:
        {
            if(self.isInZoomMode) {
                [self zoomButtonAction];
            }

            if(!self.activeStickyIndicatorView) {
                FTActiveStickyIndicatorViewController *indicatorController = [[FTActiveStickyIndicatorViewController alloc] init];
                self.activeStickyIndicatorView = indicatorController;
                [self addChildViewController:self.activeStickyIndicatorView];
                self.activeStickyIndicatorView.delegate = self;
                [self updateActiveEmojiViewFrame];
                [self.view addSubview:self.activeStickyIndicatorView.view];
                [indicatorController didMoveToParentViewController:self];
            }
        }
            break;

        case kDeskModeView:
        {
            [[self.pdfDocument localMetadataCache] setCurrentDeskMode:mode];
            if(self.isInZoomMode)
            {
                [self zoomButtonAction];
            }
        }
            break;
        case kDeskModeReadOnly:
        {
            self.readOnlyModeisOn = YES;
            [[self.pdfDocument localMetadataCache] setCurrentDeskMode:mode];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FTPDFReadOnlyMode" object:self.view.window userInfo:@{@"isOn" : @TRUE}];
            if(self.isInZoomMode)
            {
                [self zoomButtonAction];
            }
        }
            break;
        default:
            break;
    }
    
    if(mode != kDeskModeLaser) {
        [self.laserStrokeStorage resetAll];
    }
    
    [self enablePanDetection];
    
    NSArray<FTPageViewController*> *pageControllers = [self visiblePageViewControllers];
    [pageControllers enumerateObjectsUsingBlock:^(FTPageViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setMode:mode];
        [obj.writingView updateLowResolutionImageBackgroundView];
    }];

    if(self.isInZoomMode) {
        self.zoomOverlayController.currentDeskMode = mode;
    }
}

#pragma mark - Eraser options action
- (void)setToPreviousTool
{
    BOOL autoSelectPreviousTool = [FTUserDefaults shouldAutoSelectPreviousTool];
    if(autoSelectPreviousTool) {
        [self switchMode:(self.lastSelectedMode == kDeskModeEraser) ? kDeskModePen : self.lastSelectedMode];
    }
}

-(void)deselectAudioButton
{
    if(self.isInZoomMode){
        [self zoomButtonAction];
    }
}

-(NSArray*)audioAnnotationsForController:(FTAudioListViewController*)controller
{
    NSMutableArray *audioAnnotations = [NSMutableArray array];
    NSArray *pages = [self.pdfDocument pages];
    for (id<FTPageProtocol> eachPage in pages) {
        [audioAnnotations addObjectsFromArray:[eachPage audioAnnotations]];
    }
    return audioAnnotations;
}

-(FTAudioAnnotation*)audioAnnotationForModel:(FTAudioRecordingModel*)model
{
    FTAudioAnnotation *audioAnnotation = nil;
    NSArray *audioAnnotations = [self audioAnnotationsForController:nil];
    for (FTAudioAnnotation *eachAnn in audioAnnotations) {
        if (eachAnn.recordingModel == model) {
            audioAnnotation = eachAnn;
            break;
        }
    }
    return  audioAnnotation;
}

#pragma mark - Audio Export -
-(void)showExportForAudioAnnotation:(FTAudioAnnotation*)annotation inRect:(CGRect)rect onView:(UIView*)sourceView
{
#if !TARGET_OS_MACCATALYST
    self.audioExportIsSendingToOtherApp = false;
#endif
    FTLoadingIndicatorViewController *loadingIndicatorViewController = [FTLoadingIndicatorViewController showOnMode:FTLoadingIndicatorStyleActivityIndicator from:[self loadingPresentController] withText:NSLocalizedString(@"Exporting", @"Exporting") andDelay:0];
    [annotation prepareAnnotationForExportOnUpdate:^(float progress)
     {
        loadingIndicatorViewController.progress = progress;
    }
                                      onCompletion:^(NSURL *fileURL, NSError *error)
     {
        [loadingIndicatorViewController hide:^{
            if(!error && fileURL) {
                
#if TARGET_OS_MACCATALYST
                UIDocumentPickerViewController * controller = [[UIDocumentPickerViewController alloc] initWithURLs:@[fileURL] inMode:UIDocumentPickerModeMoveToService];
                controller.navigationItem.title = @"Noteshelf Recording";
                [self presentViewController:controller animated:true completion:nil];
#else
                self.audioShareInteractionController = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
                UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:self.audioShareInteractionController];
                navController.navigationBarHidden = YES;
                navController.modalPresentationStyle = UIModalPresentationFormSheet;
                navController.presentationController.delegate = (id<UIAdaptivePresentationControllerDelegate>)self;
                [self presentViewController: navController animated:YES completion:nil];
#endif
            }
            else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"UnexpectedError", @"Unexpected error. Please try...") message:nil preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:action];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }];
    }];
}

#pragma mark - Audio list Delegates -

-(void)didDeleteAnnotation:(FTAudioAnnotation*)annotation controller:(FTAudioListViewController*)controller
{
    [annotation setSelected:NO for:self.view.window.hash];

    BOOL hasPageVC = false;
    NSArray<FTPageViewController*> *pageControllers = [self visiblePageViewControllers];
    for(FTPageViewController *eachContorller in pageControllers) {
        if([eachContorller.pdfPage isEqual:[annotation associatedNotebookPage]]) {
            [eachContorller removeAnnotations:@[annotation] refreshView:YES];
            hasPageVC = true;
            break;;
        }
    }
    if(!hasPageVC) {
        [self removeAudioAnnotation:annotation];
    }
}

-(void)didClickOnExportButton:(FTAudioAnnotation*)annotation controller:(FTAudioListViewController*)controller
{
    [controller.navigationController dismissViewControllerAnimated:YES completion:^{
        UIButton *button = [self rightPanelSourceFor:FTDeskRightPanelToolAdd];
        [self showExportForAudioAnnotation:annotation inRect:button.bounds onView:button];
    }];
}

-(void)didClickOnAddNewRecording:(FTAudioListViewController*)controller
{
    [self audioButtonAction];
}

#pragma mark - Responder -
-(BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)paste:(id)sender {
    if(self.currentDeskMode != kDeskModeLaser) {
        [self pasteMenuAction2:sender];
    }
    else {
        [super paste:sender];
    }
}

-(void)copyPasteButtonAction:(UIView *)source {
    self.tappedPoint = CGPointZero;
    
    BOOL menuShown = false;
    if([self.firstPageController showMenu:source]) {
        menuShown = true;
        return;
    }

    if(self.currentDeskMode == kDeskModeClipboard) {
        [self changeMode:kDeskModeClipboard];
        [self showCopyPasteMenuOptions:CGRectInset(source.bounds,10,10) inView:source];
    }
    else {
        track(@"toolbar_lasso_tapped", nil,  [NSString stringWithFormat:@"%@",[FTScreenNames lasso]]);
        [self switchMode:kDeskModeClipboard sourceView:source];
    }
}

-(void)showCopyPasteMenuOptions:(CGRect)targetRect inView:(UIView*)view
{
#if !TARGET_OS_MACCATALYST
    [self becomeFirstResponder];
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    UIMenuItem *pasteMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Paste", @"Paste") action:@selector(pasteMenuAction2:)];
    UIMenuItem *newCutCopyMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"CutCopy", @"Cut / Copy") action:@selector(newCutCopyMenuAction:)];
    theMenu.menuItems = [NSArray arrayWithObjects:newCutCopyMenuItem, pasteMenuItem, nil];
    [view.window makeKeyWindow];
    [theMenu showMenuFromView:view rect:targetRect];
    track(@"lassorack_opened", nil,  [NSString stringWithFormat:@"%@",[FTScreenNames lasso]]);
#endif
}

-(void)newCutCopyMenuAction:(id)sender{
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    [theMenu hideMenu];
    track(@"lassorack_copy_tapped", nil,  [NSString stringWithFormat:@"%@",[FTScreenNames lasso]]);
}

- (void)pasteMenuAction2:(id)sender {
    [self.firstPageController performPasteOperationAt:CGPointZero];
    track(@"lassorack_paste_tapped", nil,  [NSString stringWithFormat:@"%@",[FTScreenNames lasso]]);
}

#pragma mark - Zoom Related -
-(CGFloat)zoomPanelOverlayheight
{
    return self.zoomOverlayController.view.frame.size.height;
}

-(void)delayedZoomButtonAction
{
    if(nil == self.zoomOverlayController) {
        FTCLSLog(@"Zoom Enabled");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FTAppDidEnterZoomMode object:nil];
        
        //Initiate zoom mode
        //Make sure desk mode is pen or eraser
        if (!(self.currentDeskMode == kDeskModePen
              || self.currentDeskMode == kDeskModeMarker
              || self.currentDeskMode == kDeskModeEraser
              || self.currentDeskMode == kDeskModeShape)) {
            [self switchMode:kDeskModePen];
        }

        [[self.pdfDocument localMetadataCache] setZoomModeEnabled:true];

        NSArray<FTPageViewController*> *controllers = [self visiblePageViewControllers];
        for(FTPageViewController *eachController in controllers) {
            if([eachController respondsToSelector:@selector(exitZoomMode)]) {
                [eachController enterZoomMode];
            }
        }
        
        FTZoomOverlayViewController *viewController = [FTZoomOverlayViewController zoomOverlayControllerWithDocument:self.pdfDocument renderViewController:self];
        viewController.delegate = self;
        [viewController addZoomOverlayFor:self.firstPageController.pdfPage
                           pageController:self.firstPageController];
        viewController.currentDeskMode = self.currentDeskMode;
        self.zoomOverlayController = viewController;
        [self.toolTypeContainerVc bringToFront];
        [self.toolTypeContainerVc handleZoomPanelFrameChange:self.zoomOverlayController.view.frame mode:self.zoomOverlayController.shortcutModeZoom animate:true completion: nil];
    }
    else {
        self.mainScrollView.contentInset = UIEdgeInsetsZero;
        [self.zoomOverlayController removeZoomOverlay];
        self.zoomOverlayController = nil;
        FTCLSLog(@"Zoom Disabled");
        
        [[self.pdfDocument localMetadataCache] setZoomModeEnabled:false];

        //If Zoompanel is there remove it
        [[NSNotificationCenter defaultCenter] postNotificationName:FTAppDidEXitZoomMode object:nil];
        
        NSArray<FTPageViewController*> *controllers = [self visiblePageViewControllers];
        for(FTPageViewController *eachController in controllers) {
            if([eachController respondsToSelector:@selector(exitZoomMode)]) {
                [eachController exitZoomMode];
            }
        }
        [self updateGestureConditions];
    }
    [self validateMenuItems];
}

-(void)handleSettingsDismiss
{
#if !TARGET_OS_MACCATALYST
    [[PressurePenEngine sharedPressurePenEngine] refresh];
#endif
    [self registerViewForTouchEvents];
    [self refreshActiveStylusButton];
}

-(void)refreshActiveStylusButton
{
    [self validateMenuItems];
}

#pragma mark - debug alert panel  -

-(void)showAlertWithtitle:(NSString*)title message:(NSString*)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Stickers -

-(void) stickerSelected:(UIImage *)stickerImage emojiID:(NSUInteger)emojiID
{
    [self dismissViewControllerAnimated:true completion:nil];
    [self switchMode:kDeskModeStickers];

    [self.activeStickyIndicatorView setCurrentSelectedImage:stickerImage];
}

-(void)insertClip:(UIImage *)clipImage webClipUrlString:(NSString*)clipUrlString {
    
    if (self.currentDeskMode == kDeskModeView) {
        [self penButtonAction];
    }
    
    FTPageViewController *firstPageController = [self pageController: CGPointZero];
    if(CGPointEqualToPoint(CGPointZero, CGPointZero)) {
        firstPageController = [self firstPageController];
    }
    
    if(nil == firstPageController) {
        return;
    }
    
    [[UIMenuController sharedMenuController] hideMenu];
    
    FTLoadingIndicatorViewController *indicator = [FTLoadingIndicatorViewController showOnMode:FTLoadingIndicatorStyleActivityIndicator from:self withText:@"Inserting" andDelay:0.2];
    __block CGRect modifiedFrame;
    
    UIView *contentHolderView = [firstPageController contentHolderView];
    CGRect bounds = contentHolderView.bounds;
    CGFloat pageContentScale = firstPageController.pageContentScale;
    UIImage *finalizedImage = [clipImage scaleAndRotateImageFor1x];
    if(nil == finalizedImage) {
        finalizedImage = clipImage;
    }
    
    CGRect finalFrame = [finalizedImage frameInRect:bounds
                                   capToMinIfNeeded:TRUE
                                       contentScale:pageContentScale];
    if(!CGPointEqualToPoint(CGPointZero, CGPointZero)) {
        finalFrame = CGRectSetCenter(finalFrame, CGPointZero, bounds);
    }
    modifiedFrame = finalFrame;
    
    FTWebClipAnnotationInfo *clipInfo = [[FTWebClipAnnotationInfo alloc] initWithImage:finalizedImage];
    clipInfo.scale = pageContentScale;
    clipInfo.enterEditMode = YES;
    clipInfo.boundingRect = CGRectScale(finalFrame, 1/clipInfo.scale);
    clipInfo.clipString = clipUrlString;
    [firstPageController addAnnotationWithInfo:clipInfo];
    [indicator hide:nil];
    self.pdfDocument.isDirty = true;
}

-(void)insertImages:(NSArray<UIImage *> *)pictures
             center:(CGPoint)center
       droppedPoint:(CGPoint)point
             source:(FTInsertImageSource)imageSource {

    if (self.currentDeskMode == kDeskModeView) {
        [self penButtonAction];
    }

    FTPageViewController *firstPageController = [self pageController:point];
    if(CGPointEqualToPoint(point, CGPointZero)) {
        firstPageController = [self firstPageController];
    }
    
    if(nil == firstPageController) {
        return;
    }

    if(nil != self.droppedImageView) {
        [[firstPageController contentHolderView] addSubview:self.droppedImageView];
    }

    [[UIMenuController sharedMenuController] hideMenu];
    
    self.view.userInteractionEnabled = NO;
    FTLoadingIndicatorViewController *indicator = [FTLoadingIndicatorViewController showOnMode:FTLoadingIndicatorStyleActivityIndicator from:self withText:@"Inserting" andDelay:0.2];
    
    BOOL canEnterIntoEditMode = [pictures count] > 1 ? NO : YES;
    
    [self getImageAnnotations:pictures contentHolderView:firstPageController center:center editMode:canEnterIntoEditMode source:imageSource completionHandler:^(NSArray<FTImageAnnotationInfo *> *info, NSArray *rectInfo, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.view.userInteractionEnabled = YES;
            [indicator hide:nil];
            [info enumerateObjectsUsingBlock:^(FTImageAnnotationInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(nil != self.droppedImageView) {
                    self.droppedImageView.hidden = NO;
                    self.droppedImageView.frame = [[rectInfo objectAtIndex:idx] CGRectValue];
                    [self.droppedImageView removeFromSuperview];
                    self.droppedImageView = nil;
                    [firstPageController addAnnotationWithInfo:obj];
                }
                else {
                    [firstPageController addAnnotationWithInfo:obj];
                }
            }];
        });
    }];
}

- (void)getImageAnnotations:(NSArray<UIImage *> *)images
          contentHolderView:(FTPageViewController*)pageViewController
                     center:(CGPoint)center
                   editMode:(BOOL) canEdit
                     source:(FTInsertImageSource)imageSource
          completionHandler:(void (^)(NSArray<FTImageAnnotationInfo *>* info,NSArray * rectInfo, NSError* error))completionBlock
{
    
    NSMutableArray<FTImageAnnotationInfo*> * info =  [NSMutableArray<FTImageAnnotationInfo*> new];
    __block CGRect modifiedFrame;
    NSMutableArray *frameInfo = [NSMutableArray new];

    UIView *contentHolderView = [pageViewController contentHolderView];
    CGRect bounds = contentHolderView.bounds;
    CGFloat pageContentScale = pageViewController.pageContentScale;

    BOOL canEnterIntoEditMode = [images count] > 1 ? NO : YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if(imageSource == FTInsertImageSourceCamera) {
                UIImageWriteToSavedPhotosAlbum(obj, nil, nil, nil);
            }
            
            UIImage *finalizedImage = [obj scaleAndRotateImageFor1x];
            if(nil == finalizedImage) {
                finalizedImage = obj;
            }
            
            CGRect finalFrame = [finalizedImage frameInRect:bounds
                                           capToMinIfNeeded:TRUE
                                               contentScale:pageContentScale];
            if(!CGPointEqualToPoint(center, CGPointZero)) {
                finalFrame = CGRectSetCenter(finalFrame, center, bounds);
            }
            if (idx != 0) {
                modifiedFrame.origin = CGPointMake(modifiedFrame.origin.x + 15, modifiedFrame.origin.y + 15);
                modifiedFrame.size = finalFrame.size;
                finalFrame = modifiedFrame;
            } else {
                modifiedFrame = finalFrame;
            }

            FTImageAnnotationInfo *imageInfo = [[FTImageAnnotationInfo alloc] initWithImage:finalizedImage];
            if (imageSource == FTInsertImageSourceSticker) {
                imageInfo = [[FTStickerAnnotationInfo alloc] initWithImage:finalizedImage];
            }
            imageInfo.scale = pageContentScale;
            imageInfo.source = imageSource;
            imageInfo.enterEditMode = canEnterIntoEditMode;
            imageInfo.boundingRect = CGRectScale(finalFrame, 1/imageInfo.scale);
            [info addObject:imageInfo];
            [frameInfo addObject:[NSValue valueWithCGRect:finalFrame]];
            
            //This is being released in mode switcher
            NSString *source=nil;
            
            switch (imageSource) {
                case FTInsertImageSourceCamera:
                    source=@"Camera";
                    break;
                case FTInsertImageSourcePhotos:
                    source=@"Photos";
                    break;
                case FTInsertImageSourceClipart:
                    source=@"Clipart";
                    break;
                case FTInsertImageSourceInsertFrom:
                    source = @"InsertFrom";
                    break;
                case FTInsertImageSourceUnSplash:
                    source = @"UnSplash";
                    break;
                case FTInsertImageSourceDrop:
                    source=@"Drop";
                    break;
                case FTInsertImageSourceSticker:
                    source=@"Sticker";
                    break;
            }
            
            track(@"insert_image", @{@"source":source}, @"NB_AddNew");
        }];
        if (info.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.pdfDocument.isDirty = true;
                completionBlock(info,frameInfo,nil);
            });
        }
    });
}

#pragma mark - Read only/ Not view highlighter -

-(void)validateMenuItems
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FTValidateToolBarNotificationName object:self.view.window];
}

#pragma mark - close opened racks -
-(void)normalizeAndEndEditingAnnotation:(BOOL)endEditing
{
    if(endEditing) {
        [self endActiveEditingAnnotations];
    }
    //override if needed.
    switch (self.currentDeskMode) {
        case kDeskModePhoto:
        {
            [self switchMode:kDeskModePen];
        }
            break;
            
        case kDeskModeClipboard:
        {
            NSArray *visibleControllers = [self visiblePageViewControllers];
            for(FTPageViewController *eachController in visibleControllers) {
                [eachController normalizeLassoView];
            }
        }
            break;
            
        default:
            break;
    }
    
}

#pragma mark - Helpers -
-(void)refreshUIforInsertedPagesAtIndex:(NSUInteger)insertionIndex
                                  count:(NSUInteger)numPagesAdded
                          forceReLayout:(BOOL)forceReLayout
{
    [self updateContentSize];
    
    if(numPagesAdded == 0) {
        //Store the old frame and target rect of zoom manager view
        [self purgePageAtIndex:insertionIndex];//index check is within the function
    }
    else {
        [self purgePageAtIndex:insertionIndex+numPagesAdded];//index check is within the function
    }
    [self loadPageAtIndex:insertionIndex];
    [self showPageAtIndex:insertionIndex forceReLayout:forceReLayout];
    [self becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FTDocumentGetReloaded" object:nil];
}

-(void)refreshUIForNonVisiblePageAtIndex:(NSUInteger)pageIndex {
    [self updateContentSize];
    [self purgePageAtIndex:pageIndex];
    [self loadPageAtIndex:pageIndex];
}

#pragma mark - OpenIn insert document -

-(void)insertNewPageFromItem:(NSURL*)url
                onCompletion:(void (^ _Nullable)(BOOL))completion
{
    NSInteger index = [self getNewPageInsertIndex];
    FTLoadingIndicatorViewController *loading = [FTLoadingIndicatorViewController showOnMode:FTLoadingIndicatorStyleActivityIndicator
                                                                                        from:self
                                                                                    withText:NSLocalizedString(@"Importing", @"Importing")
                                                                                    andDelay:0];
    FTImportItem *item = [[FTImportItem alloc] initWithItem:url];
    [self insertFileItem:item
                 atIndex:index
            onCompletion:^(BOOL success, NSError * _Nullable error)
     {
        [loading hide:nil];
        if (!success) {
            [error showAlertFrom:self];
        }
        else {
            [self showPageAtIndex:index forceReLayout:true];
        }
        if(completion) {
            completion(success);
        }
    }];
}

#pragma mark - Insert Page -
-(void)insertEmptyPageAbove:(id<FTPageProtocol>)page {
    NSInteger index = page.pageIndex;
    if(index == 0) {
        [self insertEmptyPageAtIndex:index];
    }
    else {
        FTCLSLog(@"Page inserted by right pull");
        id<FTPageProtocol> newPage = [self.pdfDocument insertPageAbovePage:page];
        if(nil != newPage) {
            NSInteger index = newPage.pageIndex;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showPageAtIndex:index forceReLayout:false];
            });
        }
    }
}

-(void)insertEmptyPageBelow:(id<FTPageProtocol>)page {
    FTCLSLog(@"Page inserted by right pull");
    id<FTPageProtocol> newPage = [self.pdfDocument insertPageBelowPage:page];
    if(nil != newPage) {
        NSInteger index = newPage.pageIndex;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showPageAtIndex:index forceReLayout:false];
        });
    }
}

-(void)insertEmptyPageAtIndex:(NSInteger)index
{
    if(index == 0) {
        FTCLSLog(@"Page inserted by left pull");
        id delegate = self.mainScrollView.scrollViewDelegate;
        self.mainScrollView.scrollViewDelegate = nil;
        [UIView animateWithDuration:0.2 animations:^{
            self.mainScrollView.contentOffset = CGPointZero;
        } completion:^(BOOL finished) {
            self.mainScrollView.scrollViewDelegate = delegate;
            [self.pdfDocument insertPageAtIndex:index];
            dispatch_async(dispatch_get_main_queue(), ^{
                CGRect pageFrame = [self frameFor:1];
                CGPoint newContentOffset = pageFrame.origin;
                if(newContentOffset.x + self.mainScrollView.frame.size.width > self.mainScrollView.contentSize.width) {
                    newContentOffset.x = self.mainScrollView.contentSize.width - self.mainScrollView.frame.size.width;
                }
                if(newContentOffset.x < 0) {
                    newContentOffset.x = 0;
                }

                self.mainScrollView.contentOffset = newContentOffset;
                [self showPageAtIndex:index forceReLayout:true];
            });
        }];
    }
    else {
        FTCLSLog(@"Page inserted by right pull");
        [self.pdfDocument insertPageAtIndex:index];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showPageAtIndex:index forceReLayout:false];
        });
    }
}

#pragma mark - auxilary button -
-(void)didChangePageAttributes:(NSNotification*)notificaion
{
    [self validateMenuItems];
}

-(void)auxiliaryNavigatorTurnPrevious
{
    NSInteger currentPage = self.currentlyVisiblePage.pageIndex;
    --currentPage;
    if(currentPage >= 0)
    {
        [self showPageAtIndex:currentPage forceReLayout:NO];
    }
}

-(void)auxiliaryNavigatorTurnNext
{
    NSInteger currentPage = self.currentlyVisiblePage.pageIndex;
    ++currentPage;
    if(currentPage < self.numberOfPages) {
        
        [self showPageAtIndex:currentPage forceReLayout:NO];
    }
}

-(void)enteringEditMode:(NSNotification*)inNotification
{
    if(inNotification.object == self) {
        FTAnnotation *annotation = [inNotification.userInfo objectForKey:@"annotation"];
        //Exit from zoom mode except for shapes
        if(self.isInZoomMode && annotation.annotationType != FTAnnotationTypeShape) {
            [self zoomButtonAction];
        }
    }
}

#pragma mark - Clipboard Methods - Lasso View Delegate -
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
    if(traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular && traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
    {
        return controller.presentationStyle;
    }
    //TODO:Lasso
    //    if(!lassoView.isSelectionActive){
    //        return controller.presentationStyle;
    //    }
    return UIModalPresentationNone;
}

#pragma mark - PressurePenEngine Delegate Methods -
-(void)updateGestureConditions
{
    [self enablePanDetection];
    NSArray *visiblePageControllers = [self visiblePageViewControllers];
    [visiblePageControllers enumerateObjectsUsingBlock:^(FTPageViewController  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.scrollView updateGestureConditions];
    }];
    [self.zoomOverlayController updateGestureConditions];
}

-(void)registerViewForTouchEvents
{
    if(self.isInZoomMode) {
        [self.zoomOverlayController registerViewForTouchEvents];
    }
    else {
        NSArray *visibleControllers = [self visiblePageViewControllers];
        [visibleControllers enumerateObjectsUsingBlock:^(FTPageViewController   * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj registerViewForTouchEvents];
        }];
    }

}

-(void)unregisterViewForTouchEvents:(BOOL)setToDefault;
{
    if(self.isInZoomMode) {
        [self.zoomOverlayController unregisterViewForTouchEvents:setToDefault];
    }
    else {
        NSArray *visibleControllers = [self visiblePageViewControllers];
        [visibleControllers enumerateObjectsUsingBlock:^(FTPageViewController   * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj unregisterViewForTouchEvents:setToDefault];
        }];
    }
}

-(void)pressurePenAvailable:(NSString *)stylusName
{
    [self registerViewForTouchEvents];
    [self refreshActiveStylusButton];
}

-(void)pressurePenNotAvailable:(NSString *)stylusName
{
    [self unregisterViewForTouchEvents:YES];
    [self refreshActiveStylusButton];
}

-(void)pressurePenConnected:(NSString *)stylusName
{
    [self registerViewForTouchEvents];

    BOOL shouldShowConnectedMessage = YES;
    //For Pencil since we have the kiss to pair view in popover we need not show connected message
    if(([stylusName hasPrefix:@"Pencil"] && [self isStylusOptionsScreenOpen]) || [stylusName hasPrefix:@"Hex3"])
        shouldShowConnectedMessage = NO;
    
    if([self isStylusOptionsScreenOpen])
        shouldShowConnectedMessage = NO;
    
    if(shouldShowConnectedMessage)
    {
        NSString *loaderText = [NSString stringWithFormat:NSLocalizedString(@"StylusNameConnected", @"%@ Connected"), stylusName];
        FTLoadingIndicatorViewController *loadingIndicatorViewController = [FTLoadingIndicatorViewController showOnMode:FTLoadingIndicatorStyleJustText from:self withText:loaderText andDelay:0];
        [loadingIndicatorViewController hideAfterDelay:1.0];

    }
    [self refreshActiveStylusButton];
}

-(void)pressurePenDisconnected:(NSString *)stylusName
{
    [self unregisterViewForTouchEvents:YES];

    BOOL shouldShowDisConnectedMessage = YES;
    //For Pencil since we have the kiss to pair view in popover we need not show disconnected message if popover is visible
    if(([stylusName hasPrefix:@"Pencil"] && [self isStylusOptionsScreenOpen]) || [stylusName hasPrefix:@"Hex3"])
        shouldShowDisConnectedMessage = NO;
    
    if([self isStylusOptionsScreenOpen])
        shouldShowDisConnectedMessage = NO;
    
    if(shouldShowDisConnectedMessage)
    {
        NSString *loaderText = [NSString stringWithFormat:NSLocalizedString(@"StylusNameDisconnected", @"%@ Disconnected"), stylusName];
        FTLoadingIndicatorViewController *loadingIndicatorViewController = [FTLoadingIndicatorViewController showOnMode:FTLoadingIndicatorStyleJustText from:self withText:loaderText andDelay:0];
        [loadingIndicatorViewController hideAfterDelay:1.0];
    }
    [self refreshActiveStylusButton];
}

-(void)pressurePenEnabled:(NSString *)stylusName
{
    [self registerViewForTouchEvents];
    [self refreshActiveStylusButton];
}

-(void)pressurePenDisabled:(NSString *)stylusName
{
    [self unregisterViewForTouchEvents:YES];
    [self refreshActiveStylusButton];
}

-(void)pressurePenShowMessage:(NSString *)message
{
    if(![self isStylusOptionsScreenOpen]) {
        FTLoadingIndicatorViewController *loadingIndicatorViewController = [FTLoadingIndicatorViewController showOnMode:FTLoadingIndicatorStyleJustText from:self withText:message andDelay:0];
        [loadingIndicatorViewController hideAfterDelay:2.0];
    }
}

// TODO: Need to confirm this for removal(Narayana)
//-(void)incrementPenColor:(int)increment
//{
//    [self normalizeAndEndEditingAnnotation:YES];
//
//    if (self.currentDeskMode != kDeskModePen && self.currentDeskMode != kDeskModeMarker) {
//        [self switchMode:kDeskModePen];
//    }
//    NSUserActivity *activity = self.view.window.windowScene.userActivity;
//
//    FTRackData *rack = [[FTRackData alloc] initWithType:FTRackTypePen userActivity:activity];
//    if (self.currentDeskMode == kDeskModeMarker) {
//        rack = [[FTRackData alloc] initWithType:FTRackTypeHighlighter userActivity:activity];
//    }
//
//    if(increment == -1)
//    {
//        //previous pen
//        [rack selectPreviousColor];
//    }
//    else
//    {
//        //next Pen
//        [rack selectNextColor];
//    }
//
//    [self validateMenuItems];
//}

-(void)pressurePenButtonAction:(RKAccessoryButtonAction)actionToPerform
{
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

            // TODO: Need to confirm this for removal(Narayana)
//        case kAccessoryButtonActionNextColor:
//
//            [self incrementPenColor:1];
//            buttonAction = @"Button: Pen Color Increment";
//
//            break;
//        case kAccessoryButtonActionPrevColor:
//
//            [self incrementPenColor:-1];
//            buttonAction = @"Button: Pen Color Decrement";
//            break;
        case kAccessoryButtonActionNextPage:
            [self auxiliaryNavigatorTurnNext];
            buttonAction = @"Button: Next Page";
            break;
        case kAccessoryButtonActionPrevPage:
            [self auxiliaryNavigatorTurnPrevious];
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
            FTCLSLog([NSString stringWithFormat:@"PDF: Pressure Pen Button Action %@",buttonAction]);
        }

    }
    @catch (NSException *exception) {
        
    }
    /*********** Log to Crashlytics **************/
}

-(void)didSuggestEnablingGestures
{
    NSArray *visiblePageControllers = [self visiblePageViewControllers];
    [visiblePageControllers enumerateObjectsUsingBlock:^(FTPageViewController  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.scrollView didSuggestEnablingGestures];
    }];
    [self enablePanDetection];

}
-(void)didSuggestDisablingGestures
{
    NSArray *visiblePageControllers = [self visiblePageViewControllers];
    [visiblePageControllers enumerateObjectsUsingBlock:^(FTPageViewController  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.scrollView didSuggestDisablingGestures];
    }];
    [self disablePanDetection];
}

#pragma mark - FTDeskToolbarDelegate -

-(NSString*)applePencilMessageDefaultOption
{
    switch(UIPencilInteraction.preferredTapAction) {
        case UIPencilPreferredActionSwitchEraser:
            return NSLocalizedString(@"OptionEraser", comment: @"Eraser");
        case UIPencilPreferredActionSwitchPrevious:
            return NSLocalizedString(@"OptionLastUsedTool", comment: @"Previous Tool");
        case UIPencilPreferredActionShowColorPalette:
            return NSLocalizedString(@"OptionColorPalette", comment: @"Show Colors");
        default:
            return NSLocalizedString(@"ButtonActionNone", comment: @"None");
    }
}

-(RKDeskMode)lastSelectedPenMode
{
    return  [self.pdfDocument.localMetadataCache lastPenMode];
}

- (void)didReceivePencilInteraction:(FTApplePencilInteractionType)action NS_AVAILABLE_IOS(12.1)
{
    if (self.currentDeskMode == kDeskModeReadOnly){
        return;
    }
    if(self.applePencilDoubleTapMsgShown) {
        return;
    }
    BOOL applePencilMessageDisplayed = [[NSUserDefaults standardUserDefaults] boolForKey:APPLE_PENCIL_MESSAGE_DISPLAYED];
    if(!applePencilMessageDisplayed) {
        self.applePencilDoubleTapMsgShown = true;
        [self normalizeAnyPresentedViewController:YES onCompletion:nil];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:APPLE_PENCIL_MESSAGE_DISPLAYED];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSMutableString * message = (NSMutableString*)NSLocalizedString(@"ApplePencilFeatureInfo", @"ApplePencilFeatureInfo");
        NSString * replacementString = [self applePencilMessageDefaultOption] ;
        message = [[message stringByReplacingOccurrencesOfString:@"SelectedTool" withString:replacementString] mutableCopy];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];

        __weak FTPDFRenderViewController *weakSelf = self;
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action)
                                   {
            weakSelf.applePencilDoubleTapMsgShown = false;
        }];

        [alert addAction:okAction];

        UIAlertAction *openSettings = [UIAlertAction actionWithTitle:@"Open Settings"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action)
                                       {
            weakSelf.applePencilDoubleTapMsgShown = false;
            [weakSelf showStylusSettings];
        }];
        [alert addAction:openSettings];

        [self presentViewController:alert
                           animated:YES
                         completion:nil];
        return;
    }

    BOOL isPencilEnabled = [NSUserDefaults isApplePencilEnabled];
    if(!isPencilEnabled) {
        [NSUserDefaults setApplePencilEnable:YES];
#if !TARGET_OS_MACCATALYST
        [[PressurePenEngine sharedPressurePenEngine] refresh];
#endif
    }

    UIViewController *presentedViewController = self.presentedViewController;
    if([presentedViewController isKindOfClass:[UINavigationController class]]) {
        presentedViewController = [[(UINavigationController*)presentedViewController viewControllers] firstObject];
    }
    FTRackType rackType = [self presentedRackTypeFor:presentedViewController];

    switch(action) {
        case FTApplePencilInteractionTypeEraser:
            if(self.currentDeskMode == kDeskModeEraser) {
                if(rackType != FTRackTypeEraser) {
                    [self normalizeAnyPresentedViewController:YES onCompletion:nil];
                    if(self.currentDeskMode != self.lastSelectedMode) {
                        if(self.lastSelectedMode == kDeskModeClipboard) {
                            UIView *lasso = [self centerPanelToolbarSourceFor: FTDeskCenterPanelToolLasso];
                            [self copyPasteButtonAction:lasso];
                        }
                        else {
                            [self switchMode:self.lastSelectedMode];
                        }
                    }
                    else {
                        [self penButtonAction];
                    }
                    [self validateMenuItems];
                }
            }
            else {
                [self normalizeAnyPresentedViewController:YES onCompletion:nil];
                [self eraserButtonAction];
            }
            break;
        case FTApplePencilInteractionTypePreviousTool:
            [self normalizeAnyPresentedViewController:YES onCompletion:nil];
            if(self.currentDeskMode != self.lastSelectedMode) {
                if(self.lastSelectedMode == kDeskModeClipboard) {
                    UIView *lasso = [self centerPanelToolbarSourceFor: FTDeskCenterPanelToolLasso];
                    [self copyPasteButtonAction:lasso];
                }else {
                    [self switchMode:self.lastSelectedMode];
                }
            }
            else if(self.currentDeskMode != kDeskModePen) {
                [self penButtonAction];
            }
            [self validateMenuItems];
            break;
        case FTApplePencilInteractionTypeShowColors:
            if(self.currentDeskMode != kDeskModePen &&
               self.currentDeskMode != kDeskModeMarker &&
               self.currentDeskMode != kDeskModeShape &&
               self.currentDeskMode != kDeskModeLaser) {
                [self normalizeAnyPresentedViewController:YES onCompletion:nil];
                [self penButtonAction];
                [self penButtonAction]; // It is needed to call this method twice to display color palette
            }
            else {
                if(rackType == FTRackTypePen ||
                   rackType == FTRackTypeHighlighter ||
                   rackType == FTRackTypeShape ||
                   rackType == FTRackTypePresenter) {
                    [self normalizeAnyPresentedViewController:YES onCompletion:nil];
                }
                else {
                    [self normalizeAnyPresentedViewController:YES onCompletion:nil];
                    if (self.currentDeskMode == kDeskModeMarker){
                        [self markerButtonAction];
                    }
                    else if (self.currentDeskMode == kDeskModePen) {
                        [self penButtonAction];
                    }
                    else if (self.currentDeskMode == kDeskModeShape) {
                        [self shapesButtonAction];
                    }
                    else if (self.currentDeskMode == kDeskModeLaser) {
                        [self presenterButtonAction];
                    }
                }
            }
            break;
        case FTApplePencilInteractionTypeDistractionFree:
            [[NSNotificationCenter defaultCenter] postNotificationName:FTToggleToolbarModeNotificationName object:nil];
            break;
        default:
            break;
    }
}

-(void)normalizeAnyPresentedViewController:(BOOL)animate onCompletion:(void (^ _Nullable)(void))completion
{
    if (self.presentedViewController) {
        if([self.presentedViewController isKindOfClass:[UINavigationController class]]) {
          UIViewController *childViewController = [[(UINavigationController*)self.presentedViewController viewControllers] firstObject];
            if([childViewController isKindOfClass:[FTFinderTabBarController class]]) {
                return;
            }
        }
        [self.presentedViewController dismissViewControllerAnimated:animate completion:completion];
    }
    else {
        if(nil != completion) {
            completion();
        }
    }
}

-(NSString *)notebookTitle
{
    return self.shelfItemManagedObject.title;
}

-(BOOL)canUndo
{
    return [self.undoManager canUndo];
}

-(BOOL)canRedo
{
    return [self.undoManager canRedo];
}

-(void)undo
{
    [self undoButtonAction];
}

-(void)redo
{
    [self redoButtonAction];
}

-(BOOL)shapesToolEnabled
{
    return [[self.pdfDocument localMetadataCache] shapeDetectionEnabled];
}

-(BOOL)zoomModeEnabled
{
    return self.isInZoomMode;
}

#pragma mark - Audio -
-(void)startNewRecording
{
    AVAudioSessionRecordPermission permission = [[AVAudioSession sharedInstance] recordPermission];
    
    if(permission == AVAudioSessionRecordPermissionUndetermined) {
        __weak __block FTPDFRenderViewController *weakSelf = self;
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(granted){
                    [weakSelf startNewRecording];
                }
            });
        }];
        return;
    }
    else if(permission == AVAudioSessionRecordPermissionDenied) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                       message:NSLocalizedString(@"AudioRecord_Permission_Message", @"AudioRecord_Permission_Message")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alert addAction:okAction];
        
        UIAlertAction *openSettings = [UIAlertAction actionWithTitle:@"Open Settings"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action)
                                       {
                                           [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                                                              options:[NSDictionary dictionary]
                                                                    completionHandler:nil];
                                       }];
        [alert addAction:openSettings];
        
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
        return;
    }
    
    self.view.userInteractionEnabled = NO;

    FTPageViewController *firstPageController = [self firstPageController];
    if(nil == firstPageController) {
        return;
    }
    UIView *contentHolderView = [firstPageController contentHolderView];
    id<FTPageProtocol> page =  firstPageController.pdfPage;
    
    FTAudioAnnotationInfo *info = [[FTAudioAnnotationInfo alloc] initWithPage:page];
    CGFloat offSet = self.mainScrollView.contentOffset.y;
    CGRect frame = contentHolderView.frame;
    if (self.currentToolBarState != FTScreenModeShortCompact) {
        CGFloat kStartingOffset = 24;
        if (self.pageLayoutType == FTPageLayoutVertical) {
            kStartingOffset = [self deskToolBarHeight] + 8; //extra offset to avoid touching audio icon to toolBar
        }
        frame.origin.y = kStartingOffset;
    }
    info.visibleRect = frame;
    info.scale = firstPageController.pageContentScale;
    [firstPageController addAnnotationWithInfo:info];
    self.view.userInteractionEnabled = YES;
}

-(void)pageDidReleased:(NSNotification*)notification
{
    id<FTPageProtocol> page = notification.object;
    [self removeObserversForPage:page];
}

#pragma mark - UIDocumentInteractionControllerDelegate -
#if !TARGET_OS_MACCATALYST
- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    if(!self.audioExportIsSendingToOtherApp) {
        self.audioShareInteractionController = nil;
    }
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    self.audioExportIsSendingToOtherApp = true;
}

-(void) documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    self.audioExportIsSendingToOtherApp = false;
    self.audioShareInteractionController = nil;
}
#endif

#pragma mark - FTDocumentDelegate methods -
-(NSRange)visiblePageRamge
{
    return [self pageRangeAddingOffset:self.currentVisiblePageRange];
}

- (void)documentWillStartSaving:(id<FTDocumentProtocol>)document {
    [self.shelfItemManagedObject setTempFileModificationDate:[NSDate date]];
}

-(void)documentDidGetRenamed:(FTDocument *)document
{
    [self normalizeAndEndEditingAnnotation:YES];
    [self documentDidGetReloaded:document];
}

- (void)documentDidReceiveConflict:(FTDocument*)document conflictingVersions:(NSArray*)conflictingVersions
{
    FTCLSLog([NSString stringWithFormat:@"Document in conflict, versions %ld",conflictingVersions.count]);
    
    [self showConflict:document];
}

- (void)documentDidDelete:(FTDocument *)document {
    FTCLSLog(@"Document is deleted");
    FTAudioSession *session = [FTAudioSessionManager sharedSession].activeSession;
    if(session.audioSessionState == AudioStateRecording) {
        FTAudioRecordingModel *model = session.audioRecording;
        FTAudioRecordingModel *playerModel = [self.playerController recordingModel];
        if([playerModel.fileName isEqualToString:model.fileName]){
            [session stopRecording];
        }
    }

    [UIAlertController showAlertWithTitle:NSLocalizedString(@"FileIsDeleted", @"File is deleted") message:@"" from:self withCompletionHandler:^{
        [self closeDocument];
    }];
}

- (void)documentDidResolveConflict:(FTDocument*)document
{
    if(nil != self.conflictViewController) {
        [self.conflictViewController dismissViewControllerAnimated:true completion:nil];
        self.conflictViewController = nil;
    }
}

- (void)documentWillGetReloaded:(FTDocument*)document onCompletion:(void(^)(void))completionBLock
{
    FTCLSLog(@"Document Will Reloaded");
    self.mainScrollView.contentOffset = self.mainScrollView.contentOffset;
    self.currentPageIndexToBeShown = self.currentlyVisiblePage.pageIndex;
    [self updateContentOffsetPercentage];
    NSArray *visibleControllers = [self visiblePageViewControllers];
    if(visibleControllers.count > 0) {
        NSMutableArray *itemsToClose = [NSMutableArray arrayWithArray:visibleControllers];
        void (^blockToCall)(FTPageViewController *controller) = ^(FTPageViewController *controller){
            [itemsToClose removeObject:controller];
            if(itemsToClose.count == 0) {
                self.view.window.userInteractionEnabled = true;
                if(completionBLock) {
                    completionBLock();
                }
            }
        };
        dispatch_async(dispatch_get_main_queue(), ^{
            self.view.window.userInteractionEnabled = false;
            [self normalizeAndEndEditingAnnotation:YES];
            [visibleControllers enumerateObjectsUsingBlock:^(FTPageViewController  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if([obj conformsToProtocol:@protocol(FTDocumentClosing)]) {
                    [(id<FTDocumentClosing>)obj startClosingProcessAndNotify:^(BOOL success) {
                        blockToCall(obj);
                    }];
                }
                else {
                    blockToCall(obj);
                }
            }];
        });
    }
    else {
        if(completionBLock) {
            completionBLock();
        }
    }
}

-(void)documentDidGetReloaded:(FTDocument *)document
{
    FTCLSLog(@"Document Did Reloaded");
    [self clearSearchOptionsInfo];
    [self purgeAllPages];
    
    self.currentVisiblePageRange = NSMakeRange(NSNotFound, 0);
    self.currentPageIndexToBeShown = CLAMP(self.currentPageIndexToBeShown, 0, self.numberOfPages-1);
    if(self.pageLayoutType == FTPageLayoutVertical) {
        FTScrollViewPageOffset *currentOffset = self.contentOffsetPercentage;
        [self prepareViewToShow:false];
        self.contentOffsetPercentage = currentOffset;
        self.mainScrollView.contentOffset = [self mappedContentOffset];
        if(self.zoomOverlayController) {
            [self.zoomOverlayController setCurrentPage:self.firstPageController.pdfPage
                                        pageController:self.firstPageController];
        }
    }
    else {
        [self prepareViewToShow:false];
    }
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
        self.conflictViewController = [FTCloudDocumentConflictScreen conflictViewControllerForDocument:self.pdfDocument documentItem:[self.shelfItemManagedObject documentItem]];
        self.conflictViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:self.conflictViewController animated:YES completion:nil];
    }
}

- (void)documentDidGetSecurityUpdate {
    FTCLSLog(@"Document's security is updated");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIAlertController showAlertWithTitle:NSLocalizedString(@"PasswordUpdated", @"Password Updated") message:@"" from:self withCompletionHandler:^{
            [self closeDocument];
        }];
    });
}

#pragma mark - Custom
- (void)closeDocument {
    [self logBookInformationWithIsOpen:false];
    [self closeDocumentWithShelfItemManagedObject:self.shelfItemManagedObject animate:true onCompletion:nil];
}

#pragma mark - Universal Settings -
-(void)closeAudioPopover
{
    BOOL isAudioPopoverOpen = [self.view.window.rootViewController.presentedViewController isKindOfClass:[FTAudioListViewController class]];
    if(isAudioPopoverOpen && !self.view.window.rootViewController.presentedViewController.isBeingDismissed) {
        [self.view.window.rootViewController.presentedViewController dismissViewControllerAnimated:true completion:nil];
    }
}

-(void)documentDidMoved:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray  *pages = self.pdfDocument.pages;
        for (id<FTPageProtocol> eachPage in pages){
            [eachPage unloadContents];
        }
        FTRenderingProperties *properties = [[FTRenderingProperties alloc] init];
        properties.renderImmediately = true;
        NSArray *visibleController = [self visiblePageViewControllers];
        for(FTPageViewController *eachContorller in visibleController) {
            [eachContorller.writingView reloadTilesInRect:eachContorller.scrollView.visibleRect
                                               properties:properties];
        }
        if(self.isInZoomMode) {
            [self.zoomOverlayController refreshView];
        }
    });
}

- (void)checkForExternalScreens
{
    __weak __block FTPDFRenderViewController *weakSelf = self;
    if(self.view.window) {
        self.extDisplayID = [[FTWhiteboardDisplayManager shared] setPageWithPage:weakSelf.currentlyVisiblePage\
                                                    onWindow:weakSelf.view.window
                                                            presentationDelegate:self];
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:FTExternalDisplayDidConnectedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note)
     {
        weakSelf.extDisplayID = [[FTWhiteboardDisplayManager shared] setPageWithPage:weakSelf.currentlyVisiblePage
                                                                            onWindow:weakSelf.view.window
                                                                presentationDelegate:weakSelf];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:[FTWhiteboardDisplayManager didRecieveTouchOnPage]
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note)
     {
        FTPageViewController *controller = (FTPageViewController*)note.object;
        UIWindow *currentWindow = weakSelf.view.window;
        id<FTPageProtocol>page = controller.pdfPage;
        if(nil != page
           && nil != currentWindow
           && currentWindow == controller.view.window) {
            weakSelf.extDisplayID = [[FTWhiteboardDisplayManager shared] setPageWithPage:page
                                                                                onWindow:currentWindow
                                                                    presentationDelegate:weakSelf];
        }
    }];
}
#pragma mark - For current page number
-(void)addPageNumberLabelToView
{
    self.pageNumberLabel = [[FTPageNumberView alloc] initWithFrame:CGRectMake(16, 16, 51, 26) page:self.currentlyVisiblePage];
    [self.view addSubview:self.pageNumberLabel];
    [self.view bringSubviewToFront:self.pageNumberLabel];
    [self showPageNumberLabel];
}
-(void) showPageNumberLabel {
    [self.pageNumberLabel setHidden:NO];
    self.pageNumberLabel.alpha = 1.0;
    [UIView animateWithDuration:2.0 animations:^{
        self.pageNumberLabel.alpha = 0.0;
    }];
}
-(void) setCurrentPageNoToPageNumberLabel {
    [self.pageNumberLabel setCurrentPage:self.currentlyVisiblePage];
    [self showPageNumberLabel];
}
#pragma mark - FTActiveStickerIndicatorView -
- (void)activeStickyIndicatorViewDidTapCloseWithIndicatorView:(FTActiveStickyIndicatorViewController * _Nonnull)indicatorView
{
    [self switchMode:self.previousDeskMode];
    [self.activeStickyIndicatorView.view removeFromSuperview];
    self.activeStickyIndicatorView = nil;
}

-(void)activeStickyIndicatorViewDidTapEmojiWithIndicatorView:(FTActiveStickyIndicatorViewController * _Nonnull)indicatorView
{
    if (nil != self.activeStickyIndicatorView.activeStickerImageView) {
        [self showStickyScreenWithSourceView:self.activeStickyIndicatorView.activeStickerImageView];
    }
}

-(void)updateActiveEmojiViewFrame
{
    if(nil == self.activeStickyIndicatorView) {
        return;
    }
    CGFloat edgeInset = 66;
    CGFloat minY = edgeInset;
    CGFloat activeViewWidth = 115.0f;
    CGFloat activeViewHeight = 44.0f;
    
    if(self.playerController && [self.playerController isExpanded]) {
        minY += kAudioBarHeight;
    }
    self.activeStickyIndicatorView.view.frame = CGRectMake(CGRectGetWidth(self.view.bounds) - (edgeInset + activeViewWidth), minY, activeViewWidth, activeViewHeight);
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if([keyPath isEqualToString:APPLE_PENCIL_ENABLED]) {
        [self updateGestureConditions];
    }
}

#pragma mark - FTEraserRackControllerDelegate
- (void)didChooseClearPage:(FTEraserRackViewController *)rackViewController {
    [rackViewController dismissViewControllerAnimated:YES completion:^{
        [self clearPageButtonAction];
        switch (self.pdfDocument.localMetadataCache.lastPenMode) {
            case kDeskModePen:
                [self penButtonAction];
                break;
            case kDeskModeMarker:
                [self markerButtonAction];
                break;
            case kDeskModeShape:
                [self shapesButtonAction];
                break;
            default:
                break;
        }
    }];
}

#pragma mark - FTLassoRackDelegate
-(void)pasteFromClipBoard {
    [self paste:nil];
}

-(CGFloat)zoomModeMaxZoomScale
{
    return 6.0f;
}

-(CGFloat)zoomModeMinZoomScale
{
    return 1.5f;
}

-(void)updateMigrationInfoView
{
    RKDeskMode mode = self.currentDeskMode;
    BOOL shouldClose = false;
    if((mode == kDeskModeEraser || mode == kDeskModeClipboard)) {
        BOOL isMigratedNotebook = [self.currentlyVisiblePage.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isReadonly == true"]].count > 0;
        
        if(isMigratedNotebook) {
            if(self.migrationInfoView.isHidden) {
                self.migrationInfoView.hidden = false;
                CGRect frame = self.migrationInfoView.frame;
                CGRect startFrame = frame;
                startFrame.origin.y = -startFrame.size.height;
                CGRect endFrame = frame;
                endFrame.origin.y = 0;
                self.migrationInfoView.frame = startFrame;
                [UIView animateWithDuration:0.2 animations:^{
                    self.migrationInfoView.frame = endFrame;
                }];
            }
        }
        else {
            shouldClose = true;
        }
    }
    else {
        shouldClose = true;
    }
    
    if(self.migrationInfoView && !self.migrationInfoView.isHidden && shouldClose) {
        CGRect endFrame = self.migrationInfoView.frame;
        endFrame.origin.y = -endFrame.size.height;
        [UIView animateWithDuration:0.2 animations:^{
            self.migrationInfoView.frame = endFrame;
        } completion:^(BOOL finished) {
            self.migrationInfoView.hidden = true;
        }];
    }
}

#pragma mark - Normal Mode Scroll Scale -
-(void)setContentScaleInNormalMode:(CGFloat)inContentScaleInNormalMode pageController:(FTPageViewController*)controller
{
    if(self.contentScaleInNormalMode != inContentScaleInNormalMode) {
        self.contentScaleInNormalMode = inContentScaleInNormalMode;
        if (nil != controller) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FTContentScaleHasBeenChanged" object:self.view.window userInfo:@{@"zoomedPageController" : controller}];
        }
    }
}

-(UIViewController*)loadingPresentController
{
    UIViewController *presentController = [self parentViewController];
    if(presentController == nil) {
        presentController = self;
    }
    return presentController;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if(gestureRecognizer == self.fourFingerGesture || self.fourFingerGesture == otherGestureRecognizer) {
        return true;
    }
    return false;
}
@end

@implementation FTPDFRenderViewController (Accessibility)
-(void)performAccessibiltyUIUpdate
{
    UIView *button = nil;
    switch (self.currentDeskMode) {
        case kDeskModePen:
            button = [self centerPanelToolbarSourceFor:FTDeskCenterPanelToolPen];
            break;
        case kDeskModeMarker:
            button = [self centerPanelToolbarSourceFor:FTDeskCenterPanelToolHighlighter];
            break;
        case kDeskModeEraser:
            button = [self centerPanelToolbarSourceFor:FTDeskCenterPanelToolEraser];
            break;
        case kDeskModeText:
            button = [self centerPanelToolbarSourceFor:FTDeskCenterPanelToolTextMode];
            break;
        default:
            break;
    }
    if(button) {
        NSString * notificationInfo = @"";
        id<FTDocumentLocalMetadataCacheProtocol> localData = [self.pdfDocument localMetadataCache];
        if(self.isInZoomMode) {
            notificationInfo = [notificationInfo stringByAppendingString:@"Selected Zoom"];
        }

        if([localData shapeDetectionEnabled]) {
            notificationInfo = [notificationInfo stringByAppendingString:@"Selected Shape"];
        }
        if(notificationInfo.length > 0) {
            __weak UIButton *weakButton = button;
            [[NSNotificationCenter defaultCenter] addObserverForName:UIAccessibilityAnnouncementDidFinishNotification
                                                              object:nil
                                                               queue:nil
                                                          usingBlock:^(NSNotification * _Nonnull note)
             {
                 UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, weakButton);
             }];
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,notificationInfo);
        }
        else {
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, button);
        }
    }
}

-(BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction
{
    BOOL isScrollingLeft = false;
    if(direction == UIAccessibilityScrollDirectionLeft) {
        isScrollingLeft = true;
    }
    else if(direction == UIAccessibilityScrollDirectionRight) {
        isScrollingLeft = false;
    }
    else {
        return false;
    }
    
    NSInteger currentPage = self.currentlyVisiblePage.pageIndex;
    NSInteger newCurrentPage = currentPage;
    if(isScrollingLeft) {
        newCurrentPage = newCurrentPage + 1;
        newCurrentPage = MIN(newCurrentPage, self.numberOfPages-1);
    }
    else {
        newCurrentPage = newCurrentPage - 1;
        newCurrentPage = MAX(newCurrentPage, 0);
    }
    
    if(newCurrentPage != currentPage) {
        [self showPageAtIndex:newCurrentPage forceReLayout:false animate:true];
    }
    return true;
}

@end


@implementation FTPDFRenderViewController (Audio)

- (void)addPlayerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAudioPlayer:) name:FTAudioSessionAskedToAddPlayerNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAudioPlayer:) name:FTAudioSessionAskedToRemovePlayerNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exportAudioAnnotation:) name:FTAudioAnnotationExportNotification object:nil];
}

-(void)exportAudioAnnotation:(NSNotification*)notification
{
    FTPageViewController *pageCOntroller = nil;
    FTAudioAnnotation *annotation = [notification.userInfo objectForKey:@"annotation"];
    NSArray *visiblePageContrllers = [self visiblePageViewControllers];
    for(FTPageViewController *eachController in visiblePageContrllers) {
        if(eachController.pdfPage == annotation.associatedNotebookPage) {
            pageCOntroller = eachController;
            break;;
        }
    }
    if(nil != pageCOntroller) {
        UIView *contentHolderView = [pageCOntroller contentHolderView];
        id<FTDocumentProtocol> notificationPostedDoc = [[annotation associatedNotebookPage] parentDocument];
        if(self.pdfDocument.hash != notificationPostedDoc.hash) {
            return;
        }
        CGRect rect = [[notification.userInfo objectForKey:@"frame"] CGRectValue];
        [self showExportForAudioAnnotation:annotation inRect:rect onView:contentHolderView];
    }
}

-(void)addAudioPlayer:(NSNotification*)notification
{
    NSUInteger windowHash = [[notification.userInfo objectForKey:FTRefreshWindowKey] unsignedIntegerValue];
    NSUInteger currentWindowHassh = self.view.window.hash;
    
    FTAudioRecordingModel *model = (FTAudioRecordingModel*)notification.object;
    id<FTDocumentProtocol> notificationPostedDoc = [[model.representedObject associatedNotebookPage] parentDocument];
    if(windowHash != currentWindowHassh || self.pdfDocument.hash != notificationPostedDoc.hash) {
        return;
    }
    AudioSessionState state = [[notification.userInfo valueForKey:FTAudioSessionEventNotificationKey] integerValue];
    
    if(!self.playerController) {
        [self createAudioPlayerForModel:model audioState:state];
        [self.playerController animateView:0.3f state:state];
    } else {
        if(![self isSameHasAudioControlModel:model]){
            [self.playerController resetControllerForState:state];
            
            self.playerController.recordingModel = model;
            self.playerController.annotation = [self audioAnnotationForModel:model];
            [self.playerController fadeAnimation:state];
        }
        else{
            if(state == AudioStateRecording){
                [self.playerController recordAudio];
            }
            else{
                [self.playerController playAudio];
            }
        }
    }
}

-(void)removeAudioPlayer:(NSNotification*)notification
{
    FTAudioRecordingModel *model = (FTAudioRecordingModel*)notification.object;
    id<FTDocumentProtocol> notificationPostedDoc = [[model.representedObject associatedNotebookPage] parentDocument];
    if(self.pdfDocument.hash != notificationPostedDoc.hash) {
        return;
    }
    if(model.representedObject.uuid == self.playerController.recordingModel.representedObject.uuid) {
        [self audioPlayerDidClose:self.playerController];
    }
}

-(void)createAudioPlayerForModel:(FTAudioRecordingModel*)recordingModel audioState:(AudioSessionState)state
{
    FTAudioPlayerController *playerController = [[FTAudioPlayerController alloc] initWithNibName:@"FTAudioPlayerController" bundle:nil];
    self.playerController = playerController;
    self.playerController.delegate = self;
    self.playerController.recordingModel = recordingModel;
    self.playerController.annotation = [self audioAnnotationForModel:recordingModel];
    
    CGRect tempFrame = self.playerController.view.frame;
    tempFrame.origin.y = [self deskToolBarHeight] + 8.0;
    tempFrame.size.width = CGRectGetWidth(self.view.frame);
    self.playerController.view.frame = tempFrame;

    [self addChildViewController:self.playerController];
    [self setOverrideTraitCollection:self.traitCollection forChildViewController:self.playerController];
    [self.view addSubview:self.playerController.view];

    [UIView animateWithDuration:0.15 animations:^(void){
        [self expandContentHolderViewForAudioController:false];
    }];
    
    [self.playerController resetControllerForState:state];
    
    
}

- (UITraitCollection *)overrideTraitCollectionForChildViewController:(UIViewController *)childViewController
{
    if(childViewController == self.playerController) {
        return self.traitCollection;
    }
    return [super overrideTraitCollectionForChildViewController:childViewController];
}

-(void)expandContentHolderViewForAudioController:(BOOL)animate {
    CGRect frame = self.contentHolderView.frame;
    if(animate) {
        [UIView animateWithDuration:0.15
                         animations:^{
                             self.contentHolderView.frame = frame;
                             [self updateActiveEmojiViewFrame];
                         } completion:^(BOOL finished){
                             [self.zoomOverlayController updateZoomAreaTargetRect];
                         }];
    }
    else {
        self.contentHolderView.frame = frame;
        [self updateActiveEmojiViewFrame];
    }
}

-(void)collapseContentHolderViewForAudioController {
    [UIView animateWithDuration:0.1f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        [self updateActiveEmojiViewFrame];
        self.contentHolderView.frame = self.view.bounds;
    } completion:^(BOOL finished) {
        if(self.isInZoomMode) {
            [self.zoomOverlayController updateZoomAreaTargetRect];
        }
    }];
}

-(BOOL)isSameHasAudioControlModel:(FTAudioRecordingModel *)model
{
    BOOL isSame = NO;
    FTAudioRecordingModel *playerModel = [self.playerController recordingModel];
    if([playerModel.fileName isEqualToString:model.fileName]){
        isSame = YES;
    }
    return isSame;
}

#pragma mark - FTAudioPlayerControllerProtocol
- (void)audioPlayerDidClose:(FTAudioPlayerController *)controller
{
    [self.playerController resetControllerForState:AudioStateNone];
    
    CGRect frame = self.playerController.view.frame;
    frame.size.height = 0.0;
    UIViewController *currentPlayer = self.playerController;
    self.playerController = nil;
    [UIView animateWithDuration:0.1 animations:^(void){
        currentPlayer.view.frame = frame;
    } completion:^(BOOL finished){
        [currentPlayer.view removeFromSuperview];
        [currentPlayer removeFromParentViewController];
    }];
    
    [self collapseContentHolderViewForAudioController];
    [self updateActiveEmojiViewFrame];
    [self endActiveEditingAnnotations];
}
- (void)audioPlayer:(FTAudioPlayerController *)controller navigateToAnnotation:(FTAudioAnnotation *)audioAnnotation
{
    [self showPageAtIndex:audioAnnotation. associatedPage.pageIndex forceReLayout: false];
}

- (void)audioPlayer:(FTAudioPlayerController *)controller goToRecordings:(FTAudioAnnotation *)audioAnnotation
{
    [self goToRecordingsWith:audioAnnotation];
}

- (void)audioPlayer:(FTAudioPlayerController *)controller deleteAnnotation:(FTAudioAnnotation *)audioAnnotation;
{
    [self didDeleteAnnotation:audioAnnotation controller:nil];
    [NSNotificationCenter.defaultCenter postNotificationName:FTAudioSessionAskedToRemovePlayerNotification object:audioAnnotation.recordingModel];
}

- (void)audioPlayer:(FTAudioPlayerController*)controller didChangeTitle:(NSString *)title forAnnotation:(FTAudioAnnotation*)annotation;
{
    annotation.audioFileName = title;
}

- (void)audioPlayerDidExpand:(FTAudioPlayerController *)controller
{
    [self expandContentHolderViewForAudioController:true];
}

- (void)audioPlayerDidCollapse:(FTAudioPlayerController *)controller
{
    [self collapseContentHolderViewForAudioController];
}

-(NSUndoManager*)undoManager
{
    if(self.currentDeskMode == kDeskModeLaser) {
        return self.laserStrokeStorage.undoManager;
    }
    return self.pdfDocument.undoManager;
}

-(void)setNeedsLayoutForcibly
{
    self.forceLayout = true;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self _loadVisiblePages:false];
}

@end

@implementation FTPDFRenderViewController (ZoomRelated)

-(FTPageLayout)pageLayoutType
{
    return self.pageLayoutHelper.layoutType;
}

- (void)zoomOverlayNavigateToPage:(id<FTPageProtocol> _Nonnull)page {
    NSInteger newIndex = [page pageIndex];
    [UIView animateWithDuration:0.2 animations:^{
        [self showPageAtIndex:newIndex forceReLayout:false animate:false];
    }];
}

-(void)zoomPanelUndoTapped{
    [self undoButtonAction];
}

-(void)zoomPanelRedoTapped{
    [self redoButtonAction];
}

-(void)zoomPanelDidTapOnPalmRest
{
    [self zoomButtonAction];
}

-(void)zoomPanelDidChangeTool:(RKDeskMode)deskMode
{
    BOOL shouldValidate = true;
    switch (deskMode) {
        case kDeskModePen:
            if(self.currentDeskMode != kDeskModePen) {
                [self penButtonAction];
                shouldValidate = false;
            }
            break;
        case kDeskModeMarker:
            if(self.currentDeskMode != kDeskModeMarker) {
                [self markerButtonAction];
                shouldValidate = false;
            }
            break;
        case kDeskModeEraser:
            if(self.currentDeskMode != kDeskModeEraser) {
                [self eraserButtonAction];
                shouldValidate = false;
            }
            break;
        case kDeskModeShape:
            if(self.currentDeskMode != kDeskModeShape) {
                [self shapesButtonAction];
                shouldValidate = false;
            }
            break;
        default:
            break;
    }
    if(shouldValidate) {
        [self validateMenuItems];
    }
}

- (void)zoomOverlayScrollToTargetRect:(CGRect)targetRect pageController:(FTPageViewController *)pageController
{
    UIScrollView *scrollView;
    UIView *contentView;
    if(self.pageLayoutType == FTPageLayoutHorizontal) {
        scrollView = pageController.scrollView;
        contentView = pageController.contentHolderView;
        targetRect = [scrollView convertRect:targetRect fromView:contentView];
    }
    else {
        scrollView = self.mainScrollView;
        contentView = self.mainScrollView.contentHolderView;
        targetRect = [scrollView convertRect:targetRect fromView:pageController.contentHolderView];
    }
    
    //Check if the the target rect is completely visible or not.
    CGPoint contentOffset = scrollView.contentOffset;
    CGFloat scrollViewHeight = scrollView.frame.size.height;
    CGFloat accessoryViewHeight = scrollView.contentInset.bottom;
    
    CGFloat availableScrollHeight = scrollViewHeight-accessoryViewHeight;
    
    CGRect bounds = contentView.frame;
    CGFloat contentHeight = MIN(scrollView.contentSize.height,bounds.origin.y+bounds.size.height);
    if(contentOffset.y + availableScrollHeight > contentHeight) {
        contentOffset.y = contentHeight - availableScrollHeight;
    }
    contentOffset.y = MAX( contentOffset.y,0);
    if(CGRectGetMaxY(targetRect) > (contentOffset.y+availableScrollHeight)) {
        contentOffset.y = CGRectGetMaxY(targetRect)-(availableScrollHeight);
    }
    
    if(CGRectGetMinY(targetRect) < contentOffset.y) {
        contentOffset.y = CGRectGetMinY(targetRect);
    }
    
    [scrollView setContentOffset:contentOffset animated:true];
}

-(void)zoomOverlayDidChangePanelFrame:(CGRect)frame pageController:(FTPageViewController * _Nullable)pageController {
    if(self.pageLayoutType == FTPageLayoutHorizontal) {
        [pageController setAccessoryViewHeight: frame.size.height];
    }
    else {
        self.mainScrollView.contentInset = UIEdgeInsetsMake(0, 0, frame.size.height, 0);
    }
    [self.toolTypeContainerVc handleEndDragOfZoomPanel:frame mode:self.zoomOverlayController.shortcutModeZoom];
}

-(void)zoomOverlayWillChangePanelFrame:(CGRect)frame {
    [self.toolTypeContainerVc handleZoomPanelFrameChange: frame mode:self.zoomOverlayController.shortcutModeZoom animate:false completion: nil];
}

@end
