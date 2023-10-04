//
//  FTPDFScrollView.h
//  PDFAnnotation
//
//  Created by Amar Udupa on 15/3/13.
//  Copyright (c) 2013 FluidTouch.biz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTWritingViewProtocol.h"

@class FTWritingViewController;

typedef  void (^ScrollViewDidCompleteZoom)(void);

extern NSString *const FTZoomRenderViewDidFinishSizing;
extern NSString *const FTZoomRenderViewDidFinishMoving;

@protocol FTPageProtocol;

@class FTPageViewController,ShelfItem;
@class FTSelectionHighlightView;

@interface FTPDFScrollView : UIScrollView <UIScrollViewDelegate,UIGestureRecognizerDelegate>

@property (strong)ScrollViewDidCompleteZoom scrollViewDidCompleteZoomBlock;
@property (readonly) CGFloat zoom;
@property (assign) BOOL isZoomingInProgress;
@property (weak,readonly) UIView *contentHolderView;
@property (assign) BOOL shouldCreateViewAfterZooming; //default is yes
@property (readonly,weak) UIImageView *pageIndexView;
@property (nonatomic,assign) NSInteger accessoryViewHeight; //Content height of the scroll view will be incremented by this value.
@property (nonatomic, readonly) FTRenderMode mode;
@property (nonatomic,assign) BOOL shouldHideFooter;
@property (assign) BOOL isIntroScreen;
@property (assign) BOOL isProgramaticallyZooming;

@property (assign,readonly) CGFloat maxZoomScale;
@property (assign,readonly) CGFloat minZoomScale;

- (instancetype)initWithFrame:(CGRect)frame mode:(FTRenderMode)inMode;

- (instancetype)initWithFrame:(CGRect)frame
parentViewController:(FTPageViewController*)controller
           withPage:(id<FTPageProtocol>)page
               mode:(FTRenderMode)inMode;

-(void)setPDFPage:(id<FTPageProtocol>)inPdfPage layoutForcibly:(BOOL)forcibly;
-(CGRect)visibleRect;

-(void)lockZoom;
-(void)unlockZoom;

-(void)willBeginInterfaceOrientation;
-(void)layoutWritingView;
-(void)didEndInterfaceOrientation;

-(void)didSuggestEnablingGestures;
-(void)didSuggestDisablingGestures;

-(void)disableNewPageOptionsForReadOnlyMode;
-(void)enableNewPageOptionsForReadOnlyMode;

-(CGFloat)zoomScaleOfPDF;
-(void)updateGestureConditions;

-(id<FTWritingProtocol>)writingView;

+(CGFloat)maxZoomScale:(FTRenderMode)mode;
+(CGFloat)minZoomScale:(FTRenderMode)mode;

-(void)setZoomBoxIsScrolling:(BOOL)isScrolling;
@end
