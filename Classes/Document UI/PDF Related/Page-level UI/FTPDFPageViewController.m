//
//  FTPDFPageViewController.m
//  Noteshelf
//
//  Created by Amar Udupa on 22/3/13.
//
//

#import "FTPDFPageViewController.h"
#import "FTPDFScrollView.h"
#import "PDFRenderView.h"
#import "FTPDFRenderViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "FTImageTransformerContainerView.h"
#import "FTPDFExportView.h"
#import "FTCloudBackUpManager.h"
#import "Noteshelf-Swift.h"

@import NSMetalRender;

@interface FTPDFPageViewController ()
{
    CGSize currentViewSize;
    BOOL keyboardShown;
    CGRect targetRectToScroll;
    CGFloat zoomPanelPreviousHeight;

}

//@property (strong) FTPDFScrollView *scrollView;
@property (assign) RKDeskMode deskMode;
@property (assign) BOOL forciblySet;
@property(weak,readwrite) id<FTPageProtocol> pdfPage;

@end

@implementation FTPDFPageViewController

@synthesize scrollView = _scrollView;
@synthesize pdfPage = _pdfPage;
@synthesize delegate;
@synthesize deskMode;
@synthesize forciblySet;

@synthesize isCurrent;
@synthesize pageIndexView;
@synthesize showPageImmediately;
@synthesize returningFromFinder;
@synthesize zoomManagerView;


-(instancetype)initWithPage:(id<FTPageProtocol>)page delegate:(FTPDFRenderViewController*)controller
{
    self = [super initWithNibName:nil bundle:nil];
    if(self)
    {
        _pdfPage = page;
        delegate = controller;
    }
    return self;
}

-(void)loadView
{
    UIView *mainView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    mainView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleRightMargin;
    mainView.clipsToBounds = YES;
    self.view = mainView;
    
    _scrollView = [[FTPDFScrollView alloc] initWithFrame:mainView.bounds
                                    parentViewController:self
                                                withPage:self.pdfPage
                                                    mode:FTRenderModeDefault];
    
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [mainView addSubview:_scrollView];
    
    currentViewSize = self.view.frame.size;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

-(void)setIsCurrent:(BOOL)isCurrentValue
{
    if(isCurrent != isCurrentValue) {
        isCurrent = isCurrentValue;
        [self.scrollView writingView].isCurrentPage = isCurrentValue;
        if(isCurrentValue) {
            [self refreshSearchResults];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(self.showPageImmediately)
    {
        [self loadPDFPage:nil];
        if(self.returningFromFinder)
        {
            self.scrollView.writingView.loadingFirstTime = false;
            self.returningFromFinder=NO;
        }
//        self.showPageImmediately=NO;
    }
//    else
//    {
//        
//        //add delay here as we dont want to render the page if user is moving quickly between pages
//        [self performSelector:@selector(loadPDFPage:) withObject:nil afterDelay:1];
//        
//    }
#if TARGET_OS_SIMULATOR
    self.scrollView.openGLWritingView.cancelRendering=NO;
#endif
}

-(UIImageView*)pageIndexView
{
    return self.scrollView.pageIndexView;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //If showPageImmediately is set to YES, mark it as NO as it has been already handled in viewWillAppear call.
    if(self.showPageImmediately)
    {
        self.showPageImmediately=NO;
    }
    else
    {
        //add delay here as we dont want to render the page if user is moving quickly between pages
//        [self performSelector:@selector(loadPDFPage:) withObject:nil afterDelay:1];

    }
}

-(void)viewWillLayoutSubviews
{
//    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
//        return;
//    }
    [super viewWillLayoutSubviews];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performLayout) object:nil];
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        [self performSelector:@selector(performLayout) withObject:nil afterDelay:0.01];
    }
    else {
        [self performLayout];
    }
}

-(void)performLayout
{
    if (!CGSizeEqualToSize(currentViewSize, self.view.frame.size)) {
        [self.scrollView willLayoutToOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        currentViewSize = self.view.frame.size;
    }
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)loadPDFPage:(id)sender
{
    //    self.pageIndexView.hidden=YES;
    [self.scrollView setPDFPage:self.pdfPage];
    [self.scrollView writingView].pageContentDelegate = self;
    [self.scrollView writingView].isCurrentPage = self.isCurrent;

    if(self.showPageImmediately) {
        self.scrollView.writingView.loadingFirstTime = !self.showPageImmediately;
#if TARGET_OS_SIMULATOR
        self.scrollView.openGLWritingView.shouldListenToEventsWhileRendering = false;
#endif
    }
    self.showPageImmediately = false;
    [self addObservers];
    [self updateScrollPositionBasedOnCurrentPageViewControllerIndex];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.scrollView willChangeOrientationFrom:self.interfaceOrientation to:toInterfaceOrientation];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.scrollView didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}
#pragma mark Observers
-(void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoActionDidChange:) name:NSUndoManagerDidUndoChangeNotification object:self.currentUndoManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoActionDidChange:) name:NSUndoManagerDidRedoChangeNotification object:self.currentUndoManager];
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentScaleHasBeenChanged:) name:@"FTContentScaleHasBeenChanged" object:nil];
}

#pragma mark generate image
-(UIImage*)snapshotOfViewWithSize:(CGSize)size screenScale:(CGFloat)screenScale
{
    if(CGSizeEqualToSize(size, CGSizeZero))
    {
        size = self.pdfPage.pageReferenceViewSize;
    }
#if TARGET_OS_SIMULATOR
    return [self.scrollView.openGLWritingView getSnapshotOfCurrentPageWithSize:size screenScale:screenScale];
#else
    return [FTPDFExportView snapshotForPage:self.pdfPage size:size screenScale:screenScale shouldRenderBackground:true];
#endif
}

#pragma mark --

-(RKDeskMode)currentDeskMode
{
    return self.delegate.currentDeskMode;
}

-(void)setMode:(RKDeskMode)inMode
{
    [self.scrollView writingView].currentDrawingMode = inMode;
}

-(void)mergePageChangesInBackground:(BOOL)background
              shouldUpdateThumbnail:(BOOL)shouldUpdateThumbnail
                    saveImmediately:(BOOL)saveImmediately
                       onCompletion:(void(^)(BOOL))completionBlock
{
    if(self.pdfPage == nil)
    {
        if(completionBlock)
            completionBlock(true);
        return;
    }
    [self.pdfPage thumbnail].shouldGenerateThumbnail = [[NSUserDefaults standardUserDefaults] boolForKey:[self.pdfPage uuid]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self.pdfPage uuid]];
    if(self.pdfPage.isDirty || [[self.pdfPage thumbnail] shouldGenerateThumbnail])
    {
        FTCLSLog([NSString stringWithFormat:@"saving page:%ld background:%d,save immediately:%d",(long)self.pdfPage.pageIndex,background,saveImmediately]);
        [self.pdfPage thumbnail].shouldGenerateThumbnail = YES;
        if(!shouldUpdateThumbnail && [[self.pdfPage thumbnail] shouldGenerateThumbnail])
        {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[self.pdfPage uuid]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }

        if(shouldUpdateThumbnail)
        {
            if(background)
            {
                [FTPDFExportView snapshotForPage:self.pdfPage
                                            size:THUMBNAIL_SIZE
                                     screenScale:[UIScreen mainScreen].scale
                                    onCompletion:^(UIImage *generatedImage,id<FTPageProtocol> pdfPage)
                 {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         FTCLSLog([NSString stringWithFormat:@"page saved background:%ld",(long)self.pdfPage.pageIndex]);
                         [[pdfPage thumbnail] updateThumbnail:generatedImage updatedDate:[NSDate dateWithTimeIntervalSinceReferenceDate:[self.pdfPage lastUpdated].doubleValue]];
                         [pdfPage.parentDocument saveDocumentWithCompletionHandler:completionBlock];
                     });
                 }];
            }
            else {
                [[self.pdfPage thumbnail] updateThumbnail:[self snapshotOfViewWithSize:THUMBNAIL_SIZE screenScale:[UIScreen mainScreen].scale] updatedDate:[NSDate dateWithTimeIntervalSinceReferenceDate:[self.pdfPage lastUpdated].doubleValue]];
            }
        }
        
        if(self.pdfPage.isDirty && saveImmediately)
        {
            FTCLSLog([NSString stringWithFormat:@"page saved:%ld",(long)self.pdfPage.pageIndex]);
            [self.pdfPage.parentDocument saveDocumentWithCompletionHandler:completionBlock];
        }
        else if(!background) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(completionBlock)
                    completionBlock(true);
            });
        }
        self.pdfPage.isDirty = false;
    }
    else {
        if([[self.pdfPage parentDocument] hasAnyUnsavedChanges]) {
            [[self.pdfPage parentDocument] saveDocumentWithCompletionHandler:completionBlock];
        }
        else {
            if(completionBlock)
                completionBlock(true);
        }
    }
}

-(void)unZoomIfNeededWithAnimation:(BOOL)animation completionBlock:(void (^)(void)) block
{
    [self zoomToScale:1 animated:animation completionBlock:block];

}

#pragma mark clear
-(void)clearPage
{
    if(self.pdfPage.annotations.count)
    {
        [Flurry logEvent:@"PDF Page Clear" withParameters:nil];
        FTCLSLog([NSString stringWithFormat:@"PDF Page Clear, Page:%ld", _pdfPage.pageIndex+1]);
        [self.scrollView.contentHolderView endEditingActiveAnnotation:nil refreshView:NO];
        [self removeAllAnnotations:self.pdfPage.annotations refreshView:YES];
        [(id)self.scrollView.writingView performSelector:@selector(updateLowResolutionImageBackgroundView) withObject:nil afterDelay:0.001];
        if(self.delegate.zoomPanel) {
            [(id)self.delegate.zoomPanel.zoomGLView.writingView performSelector:@selector(updateLowResolutionImageBackgroundView) withObject:nil afterDelay:0.001];
        }
    }
}

-(void)zoomButtonAction
{
    CGFloat zoom = self.scrollView.zoom;
    
    CGFloat noOfSteps = maxZoomScale/minZoomScale;
    CGFloat stepIncrement = (maxZoomScale-minZoomScale)/noOfSteps;

    NSInteger roundedZoom = roundf(zoom);
    roundedZoom = roundedZoom + roundf(stepIncrement);
    
    if(roundedZoom > maxZoomScale)
    {
        roundedZoom = minZoomScale;
    }
    [self zoomToScale:roundedZoom animated:YES];
    
    NSDictionary *fluryInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Toolbar Button",@"Action Type",
                               [NSNumber numberWithFloat:roundedZoom],@"Zoom Scale",
                               nil];
    [Flurry logEvent:@"PDF Page Zoomed" withParameters:fluryInfo timed:YES];
    FTCLSLog(@"PDF Page Zoomed");
}

-(void)zoomToScale:(CGFloat)scale animated:(BOOL)animate 
{
    [self zoomToScale:scale animated:animate completionBlock:nil];
}


-(void)zoomToScale:(CGFloat)scale animated:(BOOL)animate completionBlock:(void (^)(void)) block
{
    if(fabs(self.scrollView.zoom - scale) < 0.001)
    {
        if(block)
            block();
        return;
    }
    
    self.scrollView.isZooming = YES;
    self.scrollView.scrollViewDidCompleteZoomBlock=block;
    
    CGFloat percentageOfZoom = (scale/(maxZoomScale-minZoomScale));
    
    CGFloat maxZoom = self.scrollView.maximumZoomScale;
    CGFloat minZoom = self.scrollView.minimumZoomScale;
    
    CGFloat value = percentageOfZoom*(maxZoom-minZoom);
    
    [self.scrollView setZoomScale:value animated:animate];
    if(!animate)
    {
        if([self.scrollView.delegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)])
        {
            self.scrollView.isZooming = YES;
            [self.scrollView.delegate scrollViewDidEndZooming:self.scrollView
                                                     withView:self.scrollView.contentHolderView
                                                      atScale:value];
        }
    }

}

-(void)refreshZoomViewIfNeeded
{
    if(self.delegate.zoomPanel)
    {
        FTRenderingProperties *properties = [[FTRenderingProperties alloc] init];
        [self.delegate.zoomPanel.zoomGLView.writingView reloadTilesInRect:[self.delegate.zoomPanel.zoomGLView visibleRect]
                                                                              properties:properties];
    }

}
#pragma mark undo/redo

-(NSUndoManager*)currentUndoManager
{
    return [[self.pdfPage parentDocument] undoManager];
}

-(void)undo
{
    if(self.currentUndoManager.canUndo)
    {
        //If the current undo action name is Eraser, we would like to refresh the view after the undo is done.
        [self.scrollView.contentHolderView saveActiveAnnotationIfAny];
        BOOL shouldReloadTiles=NO;
        if([[self.currentUndoManager undoActionName] isEqualToString:@"Eraser"])
            shouldReloadTiles=YES;
        [self.currentUndoManager undo];
        if(shouldReloadTiles)
        {
            FTRenderingProperties *properties = [[FTRenderingProperties alloc] init];
            properties.pageID = [self.pdfPage uuid];
            [self.scrollView.writingView reloadTilesInRect:self.scrollView.visibleRect
                                                               properties:properties];
            [self refreshZoomViewIfNeeded];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FTRefreshExternalViewNotification object:nil];
    }
}

-(void)redo
{
    if(self.currentUndoManager.canRedo)
    {
        //If the current redo action name is Eraser, we would like to refresh the view after the redo is done.
        [self.scrollView.contentHolderView saveActiveAnnotationIfAny];
        BOOL shouldReloadTiles=NO;
        if([[self.currentUndoManager redoActionName] isEqualToString:@"Eraser"])
            shouldReloadTiles=YES;
        [self.currentUndoManager redo];
        if(shouldReloadTiles)
        {
            FTRenderingProperties *properties = [[FTRenderingProperties alloc] init];
            properties.pageID = [self.pdfPage uuid];
            [self.scrollView.writingView reloadTilesInRect:self.scrollView.visibleRect
                                                               properties:properties];
            [self refreshZoomViewIfNeeded];

        }
        [[NSNotificationCenter defaultCenter] postNotificationName:FTRefreshExternalViewNotification object:nil];
    }
}

-(BOOL)canUndo
{
   return self.currentUndoManager.canUndo;
}

-(BOOL)canRedo
{
    return self.currentUndoManager.canRedo;
}

#pragma mark - 

-(void)undoActionDidChange:(NSNotification*)notification
{
    if(!self.isCurrent)
        return;

    if(self.currentUndoManager == notification.object)
    {
        if(![self canUndo])
        {
            self.pdfPage.isDirty = NO;
        }
        else
        {
            self.pdfPage.isDirty = YES;
        }
    }
}

#pragma undomanager functions
-(void)addAnnotation:(FTAnnotation*)annotation refreshView:(BOOL)shouldRefresh
{
    if(nil == annotation) {
        return;
    }
    
    if(!annotation.disableUndoManagement) {
        [[self.currentUndoManager prepareWithInvocationTarget:self] removeAnnotation:annotation refreshView:YES];
    }
    [self.pdfPage addAnnotations:@[annotation]];
    if(shouldRefresh)
    {
        if(self.delegate.lassoView.antsView != nil) {
            [self.delegate.lassoView finalizeMove];
        }
        id<FTWritingProtocol> writingView = self.scrollView.writingView;
        FTRenderingProperties *properties = [[FTRenderingProperties alloc] init];
        properties.pageID = [annotation.associatedPage uuid];
        [writingView reloadTilesInRect:CGRectScale(annotation.renderingRect, writingView.scale)
                         properties:properties];
        [self refreshZoomViewIfNeeded];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:FTRefreshExternalViewNotification object:nil userInfo:@{FTRefreshRectKey : [NSValue valueWithCGRect:annotation.renderingRect]}];
}

-(void)removeAnnotation:(FTAnnotation*)annotation refreshView:(BOOL)shouldRefresh
{
    if(!annotation.disableUndoManagement) {
        [[self.currentUndoManager prepareWithInvocationTarget:self] addAnnotation:annotation refreshView:YES];
    }
    [self.pdfPage removeAnnotations:@[annotation]];
    [self.scrollView.contentHolderView endEditingActiveAnnotation:annotation refreshView:NO];
    if(shouldRefresh) {
        if(self.delegate.lassoView.antsView != nil) {
            [self.delegate.lassoView finalizeMove];
        }
        if(self.delegate.photoView != nil) {
            [self.delegate.photoView.delegate imageTransformerContainerViewPaste:self.delegate.photoView];
        }
        
        id<FTWritingProtocol> writingView = self.scrollView.writingView;
        FTRenderingProperties *properties = [[FTRenderingProperties alloc] init];
        properties.pageID = [annotation.associatedPage uuid];
        [writingView reloadTilesInRect:CGRectScale(annotation.renderingRect, writingView.scale)
                         properties:properties];
        [self refreshZoomViewIfNeeded];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FTRefreshExternalViewNotification object:nil userInfo:@{FTRefreshRectKey : [NSValue valueWithCGRect:annotation.renderingRect]}];
}

-(void)removeAllAnnotations:(NSArray*)annotations refreshView:(BOOL)shouldRefresh
{
     if(annotations.count)
    {
        NSArray *annotationsToRemove = annotations;
        annotationsToRemove = [annotationsToRemove filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"disableUndoManagement == false"]];

        NSArray *annotationsToAdd = [NSArray arrayWithArray:annotationsToRemove];
        if(annotationsToAdd.count > 0) {
            [[self.currentUndoManager prepareWithInvocationTarget:self] addAllAnnotations:annotationsToAdd refreshView:YES];
            [self.pdfPage removeAnnotations:annotationsToRemove];
            self.pdfPage.isDirty = YES;
            if(shouldRefresh)
            {
                if(self.delegate.lassoView.antsView != nil) {
                    [self.delegate.lassoView finalizeMove];
                }
                id<FTWritingProtocol> writingView = self.scrollView.writingView;
                FTRenderingProperties *properties = [[FTRenderingProperties alloc] init];
                properties.pageID = [self.pdfPage uuid];
                [writingView reloadTilesInRect:self.scrollView.visibleRect
                                 properties:properties];
                [self refreshZoomViewIfNeeded];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:FTRefreshExternalViewNotification object:nil userInfo:nil];
        }
    }
}

-(void)addAllAnnotations:(NSArray*)annotations refreshView:(BOOL)shouldRefresh
{
     if(annotations.count)
    {
        NSArray *annotationsToAdd = annotations;
        annotationsToAdd = [annotationsToAdd filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"disableUndoManagement == false"]];

        NSArray *annotationsToRemove = [NSArray arrayWithArray:annotationsToAdd];
        [annotationsToRemove makeObjectsPerformSelector:@selector(setHidden:) withObject:false];
        if(annotationsToRemove.count > 0) {
            [[self.currentUndoManager prepareWithInvocationTarget:self] removeAllAnnotations:annotationsToRemove refreshView:YES];
            [self.pdfPage addAnnotations:annotationsToAdd];
            self.pdfPage.isDirty = YES;
            if(shouldRefresh)
            {
                if(self.delegate.lassoView.antsView != nil) {
                    [self.delegate.lassoView finalizeMove];
                }
                id<FTWritingProtocol> writingView = self.scrollView.writingView;
                FTRenderingProperties *properties = [[FTRenderingProperties alloc] init];
                properties.pageID = [self.pdfPage uuid];
                [writingView reloadTilesInRect:self.scrollView.visibleRect
                                 properties:properties];
                [self refreshZoomViewIfNeeded];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:FTRefreshExternalViewNotification object:nil userInfo:nil];
        }
    }
}

//This is required by the undo manager in case of Eraser
-(void)updateSegment:(FTSegmentTransientStruct*)inSegmentTransient
     withErasedValue:(BOOL)inErased
{
    [[self.currentUndoManager prepareWithInvocationTarget:self]
     updateSegment:inSegmentTransient
     withErasedValue:!inErased];
    
    inSegmentTransient->erased=inErased;
}

-(void)beginEraserUndoGrouping
{
    [self.currentUndoManager beginUndoGrouping];
    [self.currentUndoManager setActionName:@"Eraser"];// This action name is checked in undo/redo method to trigger refresh of the view
}

-(void)endEraserUndoGrouping
{
    [self.currentUndoManager endUndoGrouping];
}



#pragma mark Keyboard Notification methods

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)notification
{
    if(!self.isCurrent)
        return;

    
    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [(NSValue*)(userInfo[UIKeyboardFrameEndUserInfoKey]) CGRectValue];
        
    UIViewController *rootViewController = [APP_DELEGATE rootViewController];
    
    CGRect endFrameWrtView = [rootViewController.view convertRect:endFrame toView:nil];
    CGFloat heightOfKeyboard = fabs(rootViewController.view.bounds.size.height - endFrameWrtView.origin.y);
    if(heightOfKeyboard > 0)
    {
        keyboardShown = YES;
    }
    else
    {
        keyboardShown = NO;
    }
    self.scrollView.accessoryViewHeight = heightOfKeyboard;
}


// Called when the UIKeyboardDidHideNotification is sent
- (void)keyboardWillHide:(NSNotification*)aNotification
{
    if(!self.isCurrent)
        return;

    if (!keyboardShown) return;
	
    self.scrollView.accessoryViewHeight = 0.0;

    keyboardShown = NO;
    targetRectToScroll = CGRectNull;
}

#pragma mark -
#pragma mark Zoom Mode related
-(void)updateZoomViewArea
{
    zoomPanelPreviousHeight=self.delegate.zoomPanel.frame.size.height;
    self.scrollView.accessoryViewHeight = zoomPanelPreviousHeight;
    CGFloat visibleZoomContentWidth=MIN(CGRectGetWidth(self.delegate.zoomPanel.zoomGLView.frame), CGRectGetWidth(self.delegate.zoomPanel.zoomGLView.contentHolderView.bounds));
    CGFloat visibleZoomContentHeight=MIN(CGRectGetHeight(self.delegate.zoomPanel.zoomGLView.frame), CGRectGetHeight(self.delegate.zoomPanel.zoomGLView.contentHolderView.bounds));
    
    CGFloat newX = MIN(self.zoomManagerView.targetRect.origin.x,
					   self.zoomManagerView.bounds.size.width - visibleZoomContentWidth/self.delegate.zoomPanel.zoomGLView.zoomFactor);
    newX = MAX(0, newX);
	
	CGFloat newY = MIN(self.zoomManagerView.targetRect.origin.y,
					   self.zoomManagerView.bounds.size.height - self.zoomManagerView.lineHeight);
	
	CGRect tempRect = CGRectIntegral(CGRectMake(newX, newY,
                                                visibleZoomContentWidth/self.delegate.zoomPanel.zoomGLView.zoomFactor,
                                                visibleZoomContentHeight/self.delegate.zoomPanel.zoomGLView.zoomFactor));
    
    self.zoomManagerView.targetRect = tempRect;
}

-(CGRect)getZoomRect
{
    CGFloat zoomMarginPercent = [[[self.pdfPage parentDocument] localMetadataCache] zoomLeftMargin];
    CGRect zoomRect=CGRectMake(zoomMarginPercent*0.01*self.zoomManagerView.frame.size.width, 0, 200, 100);
    return zoomRect;
}

-(void)enterZoomMode
{
    if(self.zoomManagerView)
        return;
    
    UIView *contentHolderView = self.scrollView.contentHolderView;
    if(contentHolderView) {
        self.zoomManagerView=[[FTZoomManagerView alloc] initWithFrame:self.scrollView.contentHolderView.bounds];
        self.zoomManagerView.targetRect=[self getZoomRect];
        self.zoomManagerView.delegate=self.delegate;

        [contentHolderView addSubview:self.zoomManagerView];
        self.scrollView.accessoryViewHeight=0;
        self.scrollView.scrollEnabled=YES;

        [self updateZoomViewArea];
        [self.scrollView lockZoom];
    }
}

-(void)exitZoomMode
{
    if(self.zoomManagerView) {
        self.scrollView.accessoryViewHeight=0;
        [self.zoomManagerView removeFromSuperview];
        self.zoomManagerView = nil;
        zoomPanelPreviousHeight=0;
        [self.scrollView unlockZoom];
    }
}

-(void)updateScrollPositionBasedOnCurrentPageViewControllerIndex
{
    NSInteger currentPage = self.delegate.pageController.currentPage;
    NSInteger thisPage = self.pdfPage.pageIndex;
    if(currentPage > thisPage) {
        CGPoint contentOffset = CGPointZero;
        contentOffset.x = MAX(self.scrollView.contentSize.width -CGRectGetWidth(self.scrollView.frame),0);
        [self.scrollView setContentOffset:contentOffset];
    }
    else if(currentPage < thisPage) {
        CGPoint contentOffset = CGPointZero;
        [self.scrollView setContentOffset:contentOffset];
    }
}

-(void)contentScaleHasBeenChanged:(NSNotification*)notification
{
    if(self != notification.object) {
        [self.scrollView willLayoutToOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        [self updateScrollPositionBasedOnCurrentPageViewControllerIndex];
    }
}

-(UIView*)snapshotViewAfterScreenUpdates:(BOOL)afterScreenUpdates
{
    UIView *snapshotView = nil;
    @try {
        snapshotView = [self.view snapshotViewAfterScreenUpdates:afterScreenUpdates];
    }
    @catch (NSException *exception) {
        FTCLSLog(@"Snapshot Capture Failed");
    }
    return snapshotView;
}

-(void)refreshSearchResults{
    __weak id<FTPageSearchProtocol> currentPage = (id<FTPageSearchProtocol>)self.pdfPage;
    FTFinderSearchOptions *options = self.delegate.finderSearchOptions;
    if (options.searchedKeyword != nil) {
        [currentPage seachFor:options.searchedKeyword
                         tags:@[]];
    }
}

@end
