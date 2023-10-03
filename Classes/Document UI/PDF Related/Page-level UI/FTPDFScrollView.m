//
//  FTPDFScrollView.m
//  PDFAnnotation
//
//  Created by Amar Udupa on 15/3/13.
//  Copyright (c) 2013 FluidTouch.biz. All rights reserved.
//

#import "FTPDFScrollView.h"
#import <QuartzCore/QuartzCore.h>
#import "FTPDFRenderViewController.h"
#import "FTPanGestureRecognizer.h"

#import "FTTouchGestureRecognizer.h"
#import "Noteshelf-Swift.h"

#define ENABLE_INSTANCE_COUNTER 0

#if ENABLE_INSTANCE_COUNTER
static int instanceCounter=0;
#endif

NSString *const FTZoomRenderViewDidFinishSizing = @"FTZoomRenderViewDidFinishSizing";
NSString *const FTZoomRenderViewDidFinishMoving = @"FTZoomRenderViewDidFinishMoving";

extern float distanceBetweenPoints2(CGPoint a, CGPoint b);

//While changing to 12x consider old GPUs which do not support argument buffers.
const CGFloat _maxZoomScale = 6.0f;
const CGFloat _minZoomScale = 1.0f;

const CGFloat _oomModeMaxZoomScale = 6.0f;
const CGFloat _zoomModeMinZoomScale = 1.0f;

@interface FTPDFScrollView()
{
    CGFloat previousScrollviewScale;
    RKDeskMode currentMode;
    CGFloat _PDFScale;

    BOOL _isZooming;
    BOOL _isScrolling;

    CGSize previousContentSize;
    CGRect oldVisibleRect;
    
    NSInteger scaleJumpWhilePinch;
    
    CGFloat _zoomFactor;
    
    BOOL _zoomBoxIsScrolling;

}

@property (weak)FTSelectionHighlightView *searchHighlightView;
@property (weak)FTPageViewController *parentViewController;

@property (readwrite,assign) FTRenderMode mode;
@property (weak) id<FTPageProtocol> pdfPage;

@property (weak) IBOutlet UIImageView *backgroundImageView;
@property (weak) IBOutlet UIImageView *shadowImageView;
@property (weak) IBOutlet UIView *contentHolderView;
@property (weak) IBOutlet UIImageView *pageIndexView;

@property (strong,readwrite) FTWritingViewController *drawingContentController;

@property (nonatomic, strong) FTPanGestureRecognizer *panGesture;

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureReuiredToFail;
@property (nonatomic, strong) FTTouchGestureRecognizer *toucheGestureRecognizer;

@property (strong) FTPageFooterView *footerView;
@property (strong) FTPageNumberView *pageNumberLabel;
@property (strong) UIView *snapshotView;

@end

@implementation FTPDFScrollView

@synthesize pdfPage;
@synthesize parentViewController;
@synthesize isZoomingInProgress = _isZoomingInProgress;
@synthesize contentHolderView;
@synthesize pageIndexView;
@synthesize accessoryViewHeight;
@synthesize mode = _mode;
@synthesize isIntroScreen = _isIntroScreen;
@synthesize isProgramaticallyZooming;

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        self.showsVerticalScrollIndicator = false;
        self.showsHorizontalScrollIndicator = false;
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        // Initialization code
#if !TARGET_OS_MACCATALYST
        self.translatesAutoresizingMaskIntoConstraints = false;
#endif
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame mode:(FTRenderMode)inMode
{
    self = [self initWithFrame:frame];
    if(self) {
        previousScrollviewScale = 1.0f;
        self.mode = inMode;
        self.scrollsToTop = false;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
parentViewController:(FTPageViewController*)controller
           withPage:(id<FTPageProtocol>)page
               mode:(FTRenderMode)inMode
{
    self = [self initWithFrame:frame];
    if (self) {
#if ENABLE_INSTANCE_COUNTER
        NSLog(@"FTPDFScrollView init- %d",++instanceCounter);
#endif
        self.mode = inMode;
        previousScrollviewScale = 1;
        parentViewController = controller;
        CGFloat currentScale = [self currentZoomScale];
        self.clipsToBounds = NO;
        self.scrollsToTop = false;
        
        self.backgroundColor = [UIColor clearColor];
        self.delaysContentTouches = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.panGestureRecognizer.minimumNumberOfTouches = 2;
        self.panGestureRecognizer.maximumNumberOfTouches = 2;
        self.delegate = self;
        
        self.maximumZoomScale = self.maxZoomScale;
        self.minimumZoomScale = self.minZoomScale;

        self.automaticallyAdjustsScrollIndicatorInsets = false;
        
        if(inMode == FTRenderModeDefault) {
            self.maximumZoomScale = self.maximumZoomScale/currentScale;
            self.minimumZoomScale = self.minimumZoomScale/currentScale;
        }
        
        self.shouldCreateViewAfterZooming = YES;
        
        
        self.pdfPage = page;
        
        [self initializeWithPDFPage:page];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableGestures:) name:FTPDFEnableGestures object:self.window];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableGestures:) name:FTPDFDisableGestures object:self.window];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePageNumberViewVisibility:) name:@"FTPDFReadOnlyMode" object:nil];
        [self addSearchObserver];
        
        [self.panGestureRecognizer addTarget:self action:@selector(didEndScrollViewPanning:)];
        [self.pinchGestureRecognizer addTarget:self action:@selector(didEndScrollViewZooming:)];
    }
    return self;
}

-(BOOL)bounces {
    BOOL bounces = [super bounces];
    if(self.mode == FTRenderModeDefault) {
        if(self.parentViewController.layoutType == FTPageLayoutVertical) {
            bounces = true;
        }
        else {
            bounces = false;
        }
    }
    else {
        self.bounces = true;
    }
    return true;
}

-(CGFloat)maxZoomScale {
    return [FTPDFScrollView maxZoomScale:self.mode];
}

-(CGFloat)minZoomScale {
    return [FTPDFScrollView minZoomScale:self.mode];
}

-(void)setZoomFactor:(CGFloat)inzoomFactor
{
    _zoomFactor = inzoomFactor;
}

-(CGFloat)zoomFactor
{
    return _zoomFactor;
}

-(void)populateViewHeirarchy:(CGRect)frame
{
    UIView *contentView = [[UIView alloc] initWithFrame:frame];
    contentView.clipsToBounds = true;
    [self addSubview:contentView];
    self.contentHolderView = contentView;

    CGRect bounds = self.contentHolderView.bounds;
    UIImageView *shadowImgView = [[UIImageView alloc] initWithFrame:CGRectInset(bounds, -10, -10)];
    shadowImgView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.shadowImageView = shadowImgView;
    [self.contentHolderView addSubview:shadowImgView];
    
    UIImageView *pageIndView = [[UIImageView alloc] initWithFrame:bounds];
    pageIndView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    pageIndView.backgroundColor=[UIColor clearColor];
    self.pageIndexView = pageIndView;
    self.pageIndexView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentHolderView addSubview:self.pageIndexView];
    [self updateThumnailbgColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.contentHolderView.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    imageView.hidden = true;
    self.backgroundImageView = imageView;
    [self.contentHolderView addSubview:self.backgroundImageView];
    self.pageNumberLabel = [[FTPageNumberView alloc] initWithFrame:CGRectMake(16, 16, 51, 26) page:self.pdfPage];
    [self addSubview:self.pageNumberLabel];
    [self bringSubviewToFront:self.pageNumberLabel];
    if (self.writingView.currentDrawingMode == kDeskModeReadOnly){
        [self showPageNumberInReadOnlyMode];
    }else{
        [self.pageNumberLabel setHidden:YES];
    }
}

-(void)updateThumnailbgColor{
    if ((self.pdfPage.templateInfo.isTemplate) && (nil != (id<FTPageBackgroundColorProtocol>)self.pdfPage)){
        id<FTPageBackgroundColorProtocol> pageColorProtocol = (id<FTPageBackgroundColorProtocol>)self.pdfPage;
        __weak FTPDFScrollView *weakSelf = self;
        if ([pageColorProtocol respondsToSelector:@selector(pageBackgroundColorOnCompletion:)]){
            [pageColorProtocol pageBackgroundColorOnCompletion:^(UIColor * _Nullable color) {
                if(color != nil){
                    weakSelf.pageIndexView.backgroundColor = color;
                }
            }];
        }
    }
}

-(void)initializeWithPDFPage:(id<FTPageProtocol>)page
{
    previousScrollviewScale = 1;
    CGRect viewBounds = self.bounds;
    CGRect aspectRect = self.pdfPage.pdfPageRect;
    [self aspectPageRect:&aspectRect scale:nil];
    if(nil == self.contentHolderView) {
        [self populateViewHeirarchy:aspectRect];
    }
    self.contentHolderView.frame = aspectRect;
    UIImage *shadowImage = [[UIImage imageNamed:@"pageShadow"] resizableImageWithCapInsets:UIEdgeInsetsMake(10,10,10,10)  resizingMode:UIImageResizingModeStretch];
    self.shadowImageView.image = [shadowImage imageWithTintColor:[UIColor colorNamed:@"bgColor"]];
    
    __weak FTPDFScrollView *weakSelf = self;
    [[page thumbnail] thumbnailImageOnUpdate:^(UIImage * _Nullable image, NSString * _Nonnull uuidString) {
        weakSelf.pageIndexView.image = image;
    }];

    self.panGesture = [[FTPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    self.panGesture.delegate = self;
    self.panGesture.cancelsTouchesInView = NO;
    self.panGesture.delaysTouchesEnded = NO;
    [self addGestureRecognizer:self.panGesture];
    [self.panGestureRecognizer requireGestureRecognizerToFail:self.panGesture];

    self.pinchGestureReuiredToFail = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureNotified:)];
    self.pinchGestureReuiredToFail.cancelsTouchesInView = NO;
    self.pinchGestureReuiredToFail.delegate = self;
    [self addGestureRecognizer:self.pinchGestureReuiredToFail];
    [self.pinchGestureRecognizer requireGestureRecognizerToFail:self.pinchGestureReuiredToFail];
    
    if(self.mode != FTRenderModeExternalScreen) {
        self.footerView = [[FTPageFooterView alloc] initWithFrame:CGRectMake(0, viewBounds.size.height-[FTPageFooterView footerHeight], viewBounds.size.width, [FTPageFooterView footerHeight])];
        [self.contentHolderView addSubview:self.footerView];
        [self.footerView setCurrentPage:page];
    }

    if(self.mode == FTRenderModeDefault) {
        FTSelectionHighlightView *higView = [[FTSelectionHighlightView alloc] initWithFrame:self.contentHolderView.bounds];
        higView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.contentHolderView addSubview:higView];
        self.searchHighlightView = higView;
    }
    
    self.panGesture.allowedTouchTypes = @[@(UITouchTypeDirect)];
    self.panGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeDirect)];
    self.pinchGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeDirect)];
    self.pinchGestureReuiredToFail.allowedTouchTypes = @[@(UITouchTypeDirect)];
    self.toucheGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeDirect)];
}

-(void)dealloc{
#if ENABLE_INSTANCE_COUNTER
    NSLog(@"FTPDFScrollView: dealloc %d",--instanceCounter);
#endif
    self.delegate = nil;
    [self.drawingContentController.view removeFromSuperview];
    self.drawingContentController = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performLayout) object:nil];
    if(nil == self.window) {
        return;
    }
    if([self applicationState] == UIApplicationStateBackground) {
        [self performSelector:@selector(performLayout) withObject:nil afterDelay:0.01];
    }
    else {
        [self performLayout];
    }
}

-(void)performLayout
{
    if(self.isZooming && self.zoomScale <= self.minimumZoomScale) {
        return;
    }

    [self centerContentHolderView:self.contentHolderView];

    if(!self.writingView.zooming) {
        FTRenderingProperties *properties = [[FTRenderingProperties alloc] init];
        properties.renderImmediately = YES;
        properties.cancelPrevious = YES;
        [self.drawingContentController releaseTilesNotInRect:[self visibleRect] extraTilesCount:EXTRA_STATIC_TILES];
        [self.drawingContentController loadTilesInRect:[self visibleRect] properties:properties];
        [self.drawingContentController removeTilesMarkedAsShouldRemove];
    }
    if(self.mode == FTRenderModeDefault && self.writingView.isCurrentPage) {
        self.parentViewController.lassoSelectionView.frame = [self visibleRect];
    }
    
    CGRect bounds = self.contentHolderView.bounds;
    CGFloat scale = [self.writingView scale];
    self.footerView.frame = CGRectMake(0, bounds.size.height-[FTPageFooterView footerHeight]*scale, bounds.size.width, [FTPageFooterView footerHeight]*scale);
    self.footerView.hidden = [self shouldHidePageFooter];
    if (self.writingView.currentDrawingMode == kDeskModeReadOnly){
        [self.pageNumberLabel setCurrentPage:self.pdfPage];
        [self showPageNumberInReadOnlyMode];
    }else{
        [self.pageNumberLabel setHidden:YES];
    }
}

-(void) showPageNumberInReadOnlyMode {
    [self.pageNumberLabel setHidden:NO];
    self.pageNumberLabel.alpha = 1.0;
    [UIView animateWithDuration:2.0 animations:^{
        self.pageNumberLabel.alpha = 0.0;
    }];
}
-(BOOL)shouldHidePageFooter
{
    if(self.shouldHideFooter) {
        return YES;
    }
    
    if((nil != self.pdfPage) && (self.pdfPage.templateInfo.footerOption == FTPageFooterOptionShow)) {
        return NO;
    }
    return YES;
}

#pragma mark
-(void)setAccessoryViewHeight:(NSInteger)newAccessoryViewHeight
{
    if(self.contentInset.bottom != newAccessoryViewHeight)
    {
        self.contentInset = UIEdgeInsetsMake(0, 0, newAccessoryViewHeight, 0);
    }
}

-(void)setPDFPage:(id<FTPageProtocol>)inPdfPage layoutForcibly:(BOOL)forcibly
{
    if((self.pdfPage != inPdfPage) || forcibly) {
        [self removeSearchObserver];
        self.pdfPage = inPdfPage;
        [self addSearchObserver];
    }

    if(nil == self.writingView) {
        if(nil == self.contentHolderView) {
            [self initializeWithPDFPage:inPdfPage];
        }
        self.backgroundImageView.hidden = YES;
        self.drawingContentController = [[FTWritingViewController alloc] init];
        self.drawingContentController.mode = self.mode;
        [self.parentViewController addChildViewController:self.drawingContentController];
        self.drawingContentController.isIntroScreen = self.isIntroScreen;
        self.drawingContentController.scrollView = self;
        self.drawingContentController.view.frame = self.contentHolderView.bounds;
        [self.contentHolderView insertSubview:self.drawingContentController.view belowSubview:self.backgroundImageView];

        if(self.mode == FTRenderModeDefault && self.parentViewController.isInZoomMode) {
            [self.parentViewController enterZoomMode];
        }
        
        self.toucheGestureRecognizer = [[FTTouchGestureRecognizer alloc] initWithTarget:self action:@selector(multifingerGesture:)];
        self.toucheGestureRecognizer.cancelsTouchesInView = NO;
        self.toucheGestureRecognizer.delaysTouchesEnded = NO;
        self.toucheGestureRecognizer.delegate = self;
        [self.pinchGestureReuiredToFail requireGestureRecognizerToFail:self.toucheGestureRecognizer];
        [self.drawingContentController.view addGestureRecognizer:self.toucheGestureRecognizer];
        [self unlockZoom];
    }

    if( (self.writingView.pageToDisplay != inPdfPage) || forcibly) {
        CGSize currentSize = self.writingView.pageToDisplay.pdfPageRect.size;
        CGSize newSize = inPdfPage.pdfPageRect.size;
        self.writingView.pageToDisplay = inPdfPage;
        [self.footerView setCurrentPage:inPdfPage];
        __weak FTPDFScrollView *weakSelf = self;
        [[inPdfPage thumbnail] thumbnailImageOnUpdate:^(UIImage * _Nullable image, NSString * _Nonnull uuidString) {
            weakSelf.pageIndexView.image = image;
        }];
        [self layoutWritingView];
        
        if(CGSizeEqualToSize(currentSize, newSize) || forcibly) {
            [self setNeedsLayout];
            [self layoutIfNeeded];
        }
    }
}

-(void)setMode:(FTRenderMode)mode
{
    _mode = mode;
    if(self.mode != FTRenderModeDefault) {
        [self removeSearchObserver];
    }
}

#pragma mark zoom
-(void)setContentOffset:(CGPoint)contentOffset
{
    RKDeskMode mode = self.writingView.currentDrawingMode;
    BOOL shouldUpdate = false;
    if(!self.isZoomingInProgress) {
        if ((self.mode == FTRenderModeDefault) && self.contentInset.bottom > 0) {
            shouldUpdate = (mode == kDeskModeText || self.parentViewController.isInZoomMode);
        }
        else if(self.mode == FTRenderModeZoom) {
            shouldUpdate = true;
        }
    }
    
    if(shouldUpdate) {
        CGSize adjustContentSize = [self adjustContentSize];
        CGFloat availableheight = CGRectGetHeight(self.frame)-self.contentInset.bottom;
        if(contentOffset.y + availableheight > adjustContentSize.height) {
            contentOffset.y = adjustContentSize.height - availableheight;
        }
    }
    [super setContentOffset:contentOffset];
}

-(CGRect)visibleRect
{
    CGPoint origin = self.contentOffset;
    CGSize size = self.frame.size;
    CGRect writingViewFrame = self.contentHolderView.frame;
    size.width = floorf(MIN(CGRectGetWidth(writingViewFrame), size.width));
    size.height = floorf(MIN(CGRectGetHeight(writingViewFrame), size.height));
    CGRect visibleRect = CGRectZero;
    visibleRect.origin = origin;
    visibleRect.size = size;
    
    if(self.mode == FTRenderModeDefault &&
       self.parentViewController.layoutType == FTPageLayoutVertical) {
        visibleRect = [self.parentViewController.delegate.mainScrollView visibleRect];
        visibleRect = [self convertRect:visibleRect fromView:self.parentViewController.delegate.mainScrollView.contentHolderView];
       
        visibleRect.origin.y = MAX(visibleRect.origin.y,0);
        visibleRect.origin.x = MAX(visibleRect.origin.x,0);

        CGFloat scrollHeight = MIN(self.frame.size.height, visibleRect.size.height);
        CGFloat scrollWidth = MIN(self.frame.size.width, visibleRect.size.width);
        
        CGFloat contentHeight = MAX(self.contentSize.height, scrollHeight);
        CGFloat contentWidth = MAX(self.contentSize.width, scrollWidth);
        
        if(CGRectGetMaxY(visibleRect) > contentHeight) {
            visibleRect.origin.y = contentHeight - scrollHeight;
        }
        if(CGRectGetMaxX(visibleRect) > contentWidth) {
            visibleRect.origin.x = contentWidth - scrollWidth;
        }
        visibleRect.size = CGSizeMake(scrollWidth, scrollHeight);
    }
    CGRect rectToReturn = visibleRect;
    if(self.mode == FTRenderModeDefault &&
       self.parentViewController.layoutType == FTPageLayoutHorizontal) {
        CGFloat insetY = MIN(self.contentOffset.y, self.parentViewController.delegate.deskToolBarHeight);
        rectToReturn = CGRectInset(rectToReturn, 0, -insetY);
    }
    return rectToReturn;
}

-(CGFloat)zoom
{
    return [self currentZoomScale];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if(self.mode == FTRenderModeZoom) {
        return YES;
    }
    else if(self.parentViewController.isInZoomMode && (gestureRecognizer == self.pinchGestureRecognizer || gestureRecognizer == self.pinchGestureReuiredToFail)) {
        return NO;
    }
    BOOL value = [self.parentViewController.delegate canAcceptTouchFor:gestureRecognizer];
    return value;
}

#if TEST_MAJOR_RADIUS
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if(touch.majorRadius >= majorRadiusThresholdForGestures) {
        return NO;
    }
    return YES;
}
#endif

-(void)lockZoom
{
    self.toucheGestureRecognizer.enabled = NO;
    self.pinchGestureRecognizer.enabled = NO;
    self.pinchGestureReuiredToFail.enabled = NO;
}

-(BOOL)allowsFreeGestureConditions {
    BOOL allowsFreeScroll = false;
    if(self.mode == FTRenderModeZoom) {
        allowsFreeScroll = [NSUserDefaults isApplePencilEnabled];
    }
    else  if(self.mode == FTRenderModeDefault) {
        allowsFreeScroll = [self.parentViewController.delegate allowsFreeGestureConditions];
    }
    return allowsFreeScroll;
}

-(void)unlockZoom
{
    if([self allowsFreeGestureConditions]) {
        self.toucheGestureRecognizer.enabled = NO;
    }
    else {
        if(self.toucheGestureRecognizer) {
            self.toucheGestureRecognizer.enabled = YES;
        }
    }
    self.pinchGestureReuiredToFail.enabled = YES;
    self.pinchGestureRecognizer.enabled = YES;
    [self.pinchGestureRecognizer requireGestureRecognizerToFail:self.pinchGestureReuiredToFail];
}

-(void)resetProperties
{
    _isZooming = _isScrolling = NO;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if(self.mode == FTRenderModeDefault &&
       self.parentViewController.layoutType == FTPageLayoutVertical) {
        return nil;
    }
    [self.parentViewController endEditingActiveAnnotation:nil refreshView:TRUE];
    return self.contentHolderView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [self.writingView willBeginZooming];
    [self.parentViewController endEditingActiveAnnotation:nil refreshView:TRUE];
    [[self controller] normalizeLassoView];
    [self disableUndoGestures];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (self.isProgramaticallyZooming){
        [scrollView centerContentHolderView:self.contentHolderView];
    }
}

-(void)completedScrolling
{
    [(id)self.writingView performSelector:@selector(updateLowResolutionImageBackgroundView) withObject:nil afterDelay:0.001];
    [self.parentViewController startAcceptingTouches:YES];
    _isScrolling = NO;
    [self unlockZoom];
    [[self controller] normalizeLassoView];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self enableGestures:nil];
    if(self.mode==FTRenderModeZoom && !_isZooming) {
        //If zoom mode, inform the viewcontroller to reposition the zoom rectangle
        [[NSNotificationCenter defaultCenter] postNotificationName:FTZoomRenderViewDidFinishMoving object:self.window];
    }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self completedScrolling];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(!decelerate)
    {
        [self completedScrolling];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if(self.mode==FTRenderModeZoom) {
        CGPoint offset = scrollView.contentOffset;
        offset.x = MAX(offset.x, 0);
        offset.x = MIN(offset.x, scrollView.contentSize.width-scrollView.frame.size.width);
        
        offset.y = MAX(offset.y, 0);
        offset.y = MIN(offset.y, scrollView.contentSize.height-scrollView.frame.size.height);
        
        *targetContentOffset = offset;
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _isScrolling = YES;
    [self.writingView updateLowResolutionImageBackgroundView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self completedScrolling];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    self.isProgramaticallyZooming = FALSE;
    BOOL shouldEnable = NO;
    [self enableUndoGestures];
    if(!self.shouldCreateViewAfterZooming) {
        self.isZoomingInProgress = NO;
        return;
    }
    
    if(_isZoomingInProgress) {
        CGFloat prevScale = [self currentZoomScale];
        CGFloat currentScale = prevScale*scale;
        
        //This should be outside the below if statement
        if(prevScale != currentScale) {
            [self setCurrentZoomScale:currentScale];

            currentScale = currentScale;
            
            self.minimumZoomScale = self.minimumZoomScale/scale;
            self.maximumZoomScale = self.maximumZoomScale/scale;

            CGRect frame = self.contentHolderView.frame;
            frame.origin = CGPointZero;
            
            self.contentHolderView.transform = CGAffineTransformIdentity;
            self.contentHolderView.frame = frame;

            CGFloat scale = [self zoomScaleOfPDF]*currentScale;
            [self.writingView setScale:scale];
            
            [self.footerView applyScale:scale];
            
            [self.writingView didEndZooming:currentScale];
            [self didChangeSearchResults:nil];
            FTCLSLog(@"PDF Page Zoomed");

            shouldEnable = YES;
            
            if(self.mode==FTRenderModeZoom) {
                //If zoom mode, inform the viewcontroller to resize the zoom rectangle
                [[NSNotificationCenter defaultCenter] postNotificationName:FTZoomRenderViewDidFinishSizing object:self.window userInfo:@{@"zoomFactor":[NSNumber numberWithFloat:currentScale]}];
            }
            
        }
        else if(self.mode==FTRenderModeZoom) {
            //If zoom mode, inform the viewcontroller to resize the zoom rectangle
            [[NSNotificationCenter defaultCenter] postNotificationName:FTZoomRenderViewDidFinishMoving object:self.window];
        }
        self.isZoomingInProgress = NO;
    }
    
    [self setNeedsLayout];
    [self.parentViewController startAcceptingTouches:YES];
    
    if(shouldEnable || !_isScrolling) {
        [self enableGestures:nil];
    }
    
    [[self controller] normalizeLassoView];
    
    if(self.scrollViewDidCompleteZoomBlock) {
        self.scrollViewDidCompleteZoomBlock();
        self.scrollViewDidCompleteZoomBlock=nil;
    }
}

#pragma mark orientation

-(void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated forceLoad:(BOOL)force
{
    if(animated) {
        CGRect visibleRectbeforeScroll = [self visibleRect];
        _isScrolling = YES;
        [UIView animateWithDuration:0.2 animations:^{
            [super scrollRectToVisible:rect animated:NO];
        } completion:^(BOOL finished) {
            self->_isScrolling = NO;
            CGRect visibleRectafterScroll = [self visibleRect];
            if(
               !CGRectEqualToRect(visibleRectafterScroll, visibleRectbeforeScroll)
               || !self.writingView.isCurrentPage
               || force
               ) {
                [self setNeedsLayout];
                [self layoutIfNeeded];
            }
        }];
    }
    else {
        [super scrollRectToVisible:rect animated:animated];
        if(force) {
            [self setNeedsLayout];
            [self layoutIfNeeded];
        }
    }
}

-(void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated
{
    [self scrollRectToVisible:rect animated:animated forceLoad:NO];
}

-(void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
    if(animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [super setContentOffset:contentOffset animated:NO];
        } completion:^(BOOL finished) {
        }];
    }
    else {
        [super setContentOffset:contentOffset animated:animated];
    }
}

-(void)willBeginInterfaceOrientation
{
    self.drawingContentController.orientationChanging = YES;
    [[self controller] normalizeLassoView];
    if(self.writingView.isCurrentPage) {
        if(([self applicationState] != UIApplicationStateBackground) && nil != self.drawingContentController.view.window) {
            self.snapshotView = [self.contentHolderView snapshotViewAfterScreenUpdates:TRUE];
            [self.snapshotView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
            [self.contentHolderView addSubview: self.snapshotView];
        }
    }
    previousContentSize = self.contentSize;
    oldVisibleRect = self.visibleRect;
}

-(UIImage*)contentImage {
    CGFloat aspect = THUMBNAIL_SIZE.width/THUMBNAIL_SIZE.height;
    CGFloat width = MIN(self.contentHolderView.frame.size.width,self.frame.size.width);
    CGFloat heigth = width/aspect;
    
    CGSize size = CGSizeMake(width, heigth);
    UIImage *image = [FTPDFExportView snapshotForPage:self.writingView.pageToDisplay
                                                 size:size
                                          screenScale:[UIScreen mainScreen].scale
                               shouldRenderBackground:YES];
    return  image;
}

-(void)didEndInterfaceOrientation
{
    if(nil != self.snapshotView) {
        [self.snapshotView removeFromSuperview];
    }
    self.drawingContentController.orientationChanging = NO;
    self.backgroundImageView.hidden = true;
    oldVisibleRect = CGRectZero;
    previousContentSize = CGSizeZero;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

-(void)layoutWritingView
{
    if(nil == self.pdfPage) {
        return;
    }
    
    [self.writingView updateLowResolutionImageBackgroundView];

    CGRect pageRect = self.pdfPage.pdfPageRect;
    
    CGRect aspectRect = pageRect;
    CGFloat scale = 1;
    [self aspectPageRect:&aspectRect scale:&scale];

    CGFloat zoomRefScale = [self zoomScaleOfPDF];
    _PDFScale = [self.pdfPage pdfscaleInRect:aspectRect];

    CGFloat currentZoomScale = [self currentZoomScale];
    if(self.mode == FTRenderModeDefault) {
        CGFloat maxVal = self.maxZoomScale/currentZoomScale;
        CGFloat minVal = self.minZoomScale/currentZoomScale;
        self.maximumZoomScale = maxVal;
        self.minimumZoomScale = minVal;
    }

    pageRect.size = CGSizeMake(pageRect.size.width*scale*currentZoomScale, pageRect.size.height*scale*currentZoomScale);

    CGFloat width = (pageRect.size.width);
    CGFloat height = (pageRect.size.height);

    pageRect.size = CGSizeMake(width, height);
    pageRect.origin.x = MAX(roundf((CGRectGetWidth(self.bounds) - width)*0.5),0);
    pageRect.origin.y = MAX(roundf((CGRectGetHeight(self.bounds) - height)*0.5),0);

    CGFloat writingScale = zoomRefScale*currentZoomScale;

    self.writingView.zoomScale = [self bgTextureZoomScale];
    self.writingView.pdfInitialScale = _PDFScale;
    self.writingView.scale = writingScale;
    
    [self.footerView applyScale:writingScale];

    self.contentHolderView.frame = pageRect;

    CGSize contentSize = [self adjustContentSize];
    if(self.mode != FTRenderModeZoom) {
        contentSize.height+=self.accessoryViewHeight;
    }
    
    self.contentSize = contentSize;

    [self.writingView reset:(self.mode != FTRenderModeDefault)];

    [self mapVisibleRect:oldVisibleRect
      withOldContentSize:previousContentSize
                 newSize:contentSize];
    
    [self didChangeSearchResults:nil];
}

-(CGSize)adjustContentSize
{
    CGSize contentSize = self.contentHolderView.frame.size;
    CGSize scrollSzie = self.frame.size;

    CGSize finalSize = contentSize;
    finalSize.width = MAX(contentSize.width, scrollSzie.width);
    finalSize.height = MAX(contentSize.height, scrollSzie.height);
    return finalSize;
}

-(void)mapVisibleRect:(CGRect)inOldVisibleRect withOldContentSize:(CGSize)oldSize newSize:(CGSize)newSize
{
    CGRect newFrame = self.frame;
    CGRect newVisibleRect = CGRectZero;
    newVisibleRect.size = newFrame.size;
    newVisibleRect.size.height = newFrame.size.height - self.contentInset.bottom;
    newVisibleRect.origin.x = (inOldVisibleRect.origin.x)*(newSize.width/oldSize.width);
    newVisibleRect.origin.y = (inOldVisibleRect.origin.y)*(newSize.height/oldSize.height);
    if(oldSize.width!=0 && oldSize.height!=0) {
        [self scrollRectToVisible:newVisibleRect animated:NO forceLoad:NO];
    }
}

-(CGFloat)zoomScaleOfPDF
{
    CGSize normalModeSize = [self.pdfPage pageReferenceViewSize];
    
    CGRect pageRect = self.pdfPage.pdfPageRect;
    CGRect aspectFitRect = pageRect;
    
    [self aspectPageRect:&aspectFitRect scale:nil];
    
    CGFloat zoomScale = aspectFitRect.size.width/normalModeSize.width;
    return zoomScale;
}

-(void)didSuggestDisablingGestures
{
    [self disableGestures:nil];
}

-(void)didSuggestEnablingGestures
{
    [self updateGestureConditions];
}


-(void)handlePanGesture:(FTPanGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateFailed) {
        if(!_isZoomingInProgress && !_isScrolling)
        {
            if(!CGSizeEqualToSize(self.contentSize, self.frame.size) || (gesture.recognitionType == FTPanRecognitionTypeSingleFinger) || self.contentInset.bottom > 0)
            {
                [self disablePinchDetection];
            }

        }
    }
}

-(void)enablePinchDetection
{
//    if(self.mode == FTRenderModeZoom) {
//        return;
//    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disablePinchDetection) object:nil];
    [self unlockZoom];
}

-(void)enablePanDetection
{
    if([self allowsFreeGestureConditions]) {
        self.panGestureRecognizer.minimumNumberOfTouches = 1;
        self.panGesture.maxNumberOfTouches = 0;
    }
    else {
        self.panGestureRecognizer.minimumNumberOfTouches = 2;
        self.panGesture.maxNumberOfTouches = 2;
    }
    self.panGesture.enabled = YES;
    self.panGestureRecognizer.enabled = YES;
    [self.panGestureRecognizer requireGestureRecognizerToFail:self.panGesture];

    FTPageViewController *pageViewController = self.parentViewController;
    [pageViewController.delegate enablePanDetection];
}

-(void)disablePinchDetection
{
    [self lockZoom];
}

-(void)disablePanDetection{
    
    self.panGesture.enabled = NO;
    self.panGestureRecognizer.enabled = NO;
    FTPageViewController *pageViewController = self.parentViewController;
    [pageViewController.delegate disablePanDetection];
}

-(void)disableUndoGestures{
    FTPageViewController *pageViewController = self.parentViewController;
    [pageViewController.delegate disableUndoGestures];
}

-(void)enableUndoGestures{
    FTPageViewController *pageViewController = self.parentViewController;
    [pageViewController.delegate enableUndoGestures];
}

-(void)updateGestureConditions
{
    [self enableGestures:nil];
    [self resetProperties];
}

CGPoint lastPoint1,lastPoint2;
-(void)pinchGestureNotified:(UIPinchGestureRecognizer*)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            scaleJumpWhilePinch = 0;
            lastPoint2 = lastPoint1 = CGPointZero;
            if(recognizer.numberOfTouches == 0) {
                return;
            }
            lastPoint1 = [recognizer locationOfTouch:0 inView:self];
            if(recognizer.numberOfTouches > 1) {
                lastPoint2 = [recognizer locationOfTouch:1 inView:self];
            }
            [self performSelector:@selector(disablePinchDetection) withObject:nil afterDelay:0.5];
        }
            break;
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateRecognized:
        {
            if(recognizer.numberOfTouches == 0) {
                return;
            }
            CGPoint currentPoint1 = [recognizer locationOfTouch:0 inView:self];
            CGPoint currentPoint2 = CGPointZero;
            if(recognizer.numberOfTouches > 1) {
                currentPoint2 = [recognizer locationOfTouch:1 inView:self];
            }
            if(CGPointEqualToPoint(lastPoint2, CGPointZero)) {
                return;
            }
            CGFloat distanceBetweenPoint1 = distanceBetweenPoints2(currentPoint1, lastPoint1);
            CGFloat distanceBetweenPoint2 = distanceBetweenPoints2(currentPoint2, lastPoint2);
            BOOL shouldZoom = NO;
            if(distanceBetweenPoint2 >= 10 &&
               distanceBetweenPoint1 >= 10 ) {
                shouldZoom = YES;
            }
            scaleJumpWhilePinch++;
            if((fabs(recognizer.scale-1) > 0.3) && shouldZoom && (scaleJumpWhilePinch > 3))
            {
                if(!_isScrolling && !_isZoomingInProgress)
                {
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disablePinchDetection) object:nil];
                    self.isZoomingInProgress = YES;
                    self.pinchGestureReuiredToFail.enabled = NO;
                    self.panGesture.enabled = NO;
                    FTCLSLog(@"PDF Page Zoomed");
                    lastPoint1 = lastPoint2 = CGPointZero;
                }
            }
        }
            break;
        default:
            break;
    }
}
-(void)multifingerGesture:(UIGestureRecognizer*)gesture
{
    if(gesture.state == UIGestureRecognizerStateFailed)
    {

    }
    else
    {
        [self disablePinchDetection];
    }
}

-(void)delayedDisableAllGestures
{
    [self disableGestures:nil];
}

-(void)disableGestures:(NSNotification*)notification
{
    [self disablePinchDetection];
    [self disablePanDetection];
}

-(void)enableGestures:(NSNotification*)notification
{
    [self enablePinchDetection];
    [self enablePanDetection];
}
-(void)updatePageNumberViewVisibility:(NSNotification*)notification {
    
    if (![self isSameSceneWindow:self.window notification:notification]){
        return;
    }
    if ([notification.userInfo[@"isOn"] boolValue]){
        [self showPageNumberInReadOnlyMode];
    }else{
        [self.pageNumberLabel setHidden:YES];
    }
}
-(BOOL)isSameSceneWindow:(UIWindow*)window  notification:(NSNotification*) notification {
    if (window == (UIWindow *)notification.object){
        return YES;
    }
    return NO;
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if([NSUserDefaults isApplePencilEnabled] && (self.isDragging || self.isDecelerating)) {
        for (UITouch *eachTouch in touches) {
            if(eachTouch.type == UITouchTypePencil) {
                CGPoint offset = self.contentOffset;
                [self setContentOffset:offset animated:NO];
                break;
            }
        }
    }
}

-(void)addSearchObserver
{
    if(self.mode == FTRenderModeDefault) {
        NSString *newNotificationName = [@"DidChangeSearchResults_" stringByAppendingString:self.pdfPage.uuid];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeSearchResults:) name:newNotificationName object:nil];
    }
}

-(void)removeSearchObserver
{
    if(nil != self.pdfPage) {
        NSString *oldNotificationName = [@"DidChangeSearchResults_" stringByAppendingString:self.pdfPage.uuid];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:oldNotificationName object:nil];
    }
}

-(void)didChangeSearchResults:(NSNotification*)notification
{
    id<FTWritingProtocol> view = self.writingView;
    CGFloat writingScale = [self.writingView scale];
    if(
       (nil != view) &&
        (self.mode == FTRenderModeDefault)
        && [self.pdfPage conformsToProtocol:@protocol(FTPageSearchProtocol)]
       ) {
        id<FTPageSearchProtocol> page = (id<FTPageSearchProtocol>)self.pdfPage;
        CGFloat scale = [self.pdfPage pdfscaleInRect:self.searchHighlightView.bounds];
        [self.searchHighlightView renderSearchItemsWithItems:page.searchingInfo.searchItems
                                                    pdfScale:scale
                                             annotationScale:writingScale];
        
    }
}

-(CGFloat)bgTextureZoomScale {
    if(self.parentViewController.layoutType == FTPageLayoutVertical) {
        CGFloat scale = previousScrollviewScale;
        if(self.mode == FTRenderModeDefault) {
            scale = [[self.parentViewController.delegate mainScrollView] zoomFactor];
        }
        return MAX(scale,1);
    }
    else {
        return [self currentZoomScale];
    }
}

-(void)setCurrentZoomScale:(CGFloat)inScale
{
    if(self.mode == FTRenderModeDefault) {
        [self.parentViewController.delegate setContentScaleInNormalMode:inScale pageController:self.parentViewController];
    }
    else {
        previousScrollviewScale = inScale;
    }
}

-(CGFloat)currentZoomScale
{
    CGFloat scale = previousScrollviewScale;
    if(self.mode == FTRenderModeDefault) {
        scale = self.parentViewController.delegate.contentScaleInNormalMode;
    }
    return MAX(scale,1);
}
    
-(FTPageViewController*)controller
{
    return (FTPageViewController*)[self.writingView pageContentDelegate];
}

-(id<FTWritingProtocol>)writingView
{
    return self.drawingContentController;
}
    
-(void)setIsIntroScreen:(BOOL)isIntroScreen
{
    _isIntroScreen = isIntroScreen;
    self.drawingContentController.isIntroScreen = self.isIntroScreen;
}
-(BOOL)isIntroScreen
{
    return _isIntroScreen;
}
    
- (void)setIsZoomingInProgress:(BOOL)isZooming
{
    _isZoomingInProgress = isZooming;
    self.writingView.zooming = isZooming;
}
    
-(BOOL)isZoomingInProgress
{
    return _isZoomingInProgress;
}

-(void)zoomTo:(CGPoint)zoomPoint scale:(CGFloat)inScale animate:(BOOL)animate {
    self.isProgramaticallyZooming = true;
    self.isZoomingInProgress = true;
    [super zoomTo:zoomPoint scale:inScale animate:animate];
}

-(void)aspectPageRect:(CGRect*)aspectRect scale:(CGFloat*)scale
{
    CGRect pageRect = self.pdfPage.pdfPageRect;
    CGRect aspectFitPageRect = pageRect;
    CGFloat aspectFitScale = 1;
    if(self.mode == FTRenderModeZoom) {
        aspectFitScale = self.bounds.size.width/pageRect.size.width;
        aspectFitPageRect = CGRectIntegral(CGRectScale(pageRect, aspectFitScale));
    }
    else {
        aspectFitPageRect = aspectFittedRect(pageRect, self.bounds);
        aspectFitScale = aspectFitPageRect.size.width/pageRect.size.width;
    }
    if(nil != aspectRect) {
        *aspectRect = aspectFitPageRect;
    }
    if(nil != scale) {
        *scale = aspectFitScale;
    }
}

-(void)didEndScrollViewPanning:(UIPanGestureRecognizer*)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            [self.parentViewController startAcceptingTouches:NO];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self.parentViewController startAcceptingTouches:YES];
            break;
        default:
            break;
    }
}

-(void)didEndScrollViewZooming:(UIPinchGestureRecognizer*)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            [self.parentViewController startAcceptingTouches:NO];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self.parentViewController startAcceptingTouches:YES];
            break;
        default:
            break;
    }
}

+(CGFloat)maxZoomScale:(FTRenderMode)mode {
    if(mode == FTRenderModeZoom) {
        return  _oomModeMaxZoomScale;
    }
    return  _maxZoomScale;
}

+(CGFloat)minZoomScale:(FTRenderMode)mode {
    if(mode == FTRenderModeZoom) {
        return  _zoomModeMinZoomScale;
    }
    return  _minZoomScale;
}

- (BOOL)isScrolling {
    if(self.mode == FTRenderModeZoom) {
        return [super isScrolling] || _zoomBoxIsScrolling;
    }
    if(self.parentViewController.layoutType == FTPageLayoutVertical) {
        return [self.parentViewController.delegate.mainScrollView isScrolling];
    }
    return [super isScrolling];
}

-(void)setZoomBoxIsScrolling:(BOOL)isScrolling {
    if (self.mode == FTRenderModeZoom) {
        _zoomBoxIsScrolling = isScrolling;
    }
}
@end
