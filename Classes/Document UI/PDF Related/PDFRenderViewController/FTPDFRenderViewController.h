//
//  FTPDFRenderViewController.h
//  Noteshelf
//
//  Created by Amar Udupa on 7/3/13.
//
//

#import <UIKit/UIKit.h>
#import "FTBaseRenderViewController.h"
#import "FTAudioListViewController.h"
#import <Foundation/Foundation.h>
#import "FTWritingViewProtocol.h"

typedef enum : NSInteger {
    FTShowPWDStateNone,
    FTShowPWDStateAlert,
    FTShowPWDStateShow,
    FTShowPWDStateNotNeeded
}FTShowPWDState;

typedef enum : NSInteger {
    FTNormalMode,
    FTRefreshMode,
    FTFinderPageMode
}FTAddNewPageMode;

typedef enum: NSInteger  {
    FTNormalAction,
    FTSaveAction,
    FTDeletePermanentlyAction,
    FTMoveToTrashAction
}FTNotebookBackAction;


@protocol FTDocumentProtocol,FTApplePencilInteractionProtocol;
#if !TARGET_OS_MACCATALYST
@protocol PressurePenEngineDelegate;
#endif
@protocol FTDeskToolbarDelegate;
@protocol FTPageLayouter;

@class FTAnnotation,FTDroppingViewController;
@class FTDocumentOpenInfo,FTImportAction, FTImportFileHandler,FTDocumentOpenToken;
@class FTActiveStickyIndicatorViewController,FTFinderSearchOptions;
@class FTPageViewController;
@class FTSmartProgressView,FTExportProgressManager;
@class FTDocumentScrollView;
@class FTZoomOverlayViewController;
@class FTQuickPageNavigatorViewController;
@class FTToolTypeShortcutContainerController;

@protocol FTPenRackSelectDelegate;
@protocol FTEraserRackControllerDelegate;
@class FTScrollViewPageOffset;
@class FTLaserStrokeStorage;
@class FTShortcutExecuter;
@protocol FTFinderNotifier;

#if !TARGET_OS_MACCATALYST
@interface FTPDFRenderViewController : FTBaseRenderViewController <UIPopoverPresentationControllerDelegate,UINavigationControllerDelegate,PressurePenEngineDelegate,FTDeskToolbarDelegate,FTAudioListViewControllerDelegtes,FTApplePencilInteractionProtocol, FTPenRackSelectDelegate, FTEraserRackControllerDelegate> {
}
#else
@interface FTPDFRenderViewController : FTBaseRenderViewController
<UIPopoverPresentationControllerDelegate,
UINavigationControllerDelegate,
FTDeskToolbarDelegate,
FTAudioListViewControllerDelegtes,
FTApplePencilInteractionProtocol,
FTPenRackSelectDelegate,
FTEraserRackControllerDelegate> {}
#endif

@property (strong) FTScrollViewPageOffset *contentOffsetPercentage; //internal

@property (assign) BOOL addedObserverOnScene;

@property (weak) id openCloseDocumentDelegate;
@property (weak) id textToolbarDelegate;
@property (weak,readonly) FTZoomOverlayViewController *zoomOverlayController;

@property (nullable, strong) NSString *currentSceneID;
@property (strong) FTDocumentOpenToken *openDocToken;

@property (assign,readonly) CGFloat contentScaleInNormalMode;
@property (assign) BOOL insertingPhotoAsPage;
@property (assign) BOOL isNewPageFromTemplate;
@property (assign) BOOL returningFromFinder;
@property (assign) CGPoint lastOffset;
@property (assign) NSTimeInterval lastOffsetCapture;
@property (assign,readonly) BOOL isZoomAreaUpdating;

@property (strong,readonly) id<FTDocumentProtocol> pdfDocument;
@property (strong) NSMutableArray<FTAnnotation*> *selectedAnnotations;
@property (assign) BOOL showPageImmediately;

@property (strong) id<FTPageLayouter> pageLayoutHelper;

@property (strong) FTDocumentScrollView *mainScrollView;
@property (weak) UITapGestureRecognizer *twoFingerUndoGesture;
@property (weak) UITapGestureRecognizer *threeFingerRedoGesture;

@property (weak) UIView *contentHolderView;
@property (strong) FTQuickPageNavigatorViewController *pageNavigatorController;

@property (weak) FTDroppingViewController *dropViewController;
@property (weak) UIImageView *droppedImageView;

@property (readwrite, nonatomic) NSInteger pageSwipingCounter;
@property (readwrite, nonatomic) NSInteger previousVisiblePageIndex;
//Target
@property (strong) FTImportFileHandler *importFileHandler;
@property (strong) UIPopoverPresentationController *exportPopoverController;
@property (assign) BOOL isCurrentPageTargetted;

//DocumentEntity
@property (strong) FTImportAction *importTarget;
@property (strong) FTExportProgressManager *exportManager;

@property (weak) FTActiveStickyIndicatorViewController *activeStickyIndicatorView;
@property (weak) FTToolTypeShortcutContainerController *toolTypeContainerVc;

//FinderRestoration
@property (nonatomic, strong) FTFinderSearchOptions *finderSearchOptions;

//Password Related
@property(assign) FTShowPWDState shouldShowPwdScreenOnBecomeActive;
@property(assign) BOOL savingInProgress;
@property(assign) BOOL isAskedForPassword; //To avoid showing, multiple times Bio-Metric at the same time
@property(assign) NSTimeInterval goingToBackgroundAt;
@property(strong) UIWindow *blurWindow;

@property (weak) UIView *penrackToolTipView;

//Page Insertion
@property(assign) FTAddNewPageMode addNewpageMode;

@property (strong) FTLaserStrokeStorage *laserStrokeStorage;
@property (strong) FTShortcutExecuter *executer;
@property (nonatomic,weak) id<FTFinderNotifier> finderNotifier;
@property (strong) NSMutableArray *eachPageViewArray;

-(id)initWithDocumentInfo:(FTDocumentOpenInfo*)documentInfo;

-(void)normalizeAndEndEditingAnnotation:(BOOL)endEditing;
-(void)endActiveEditingAnnotations;

-(void)enablePanDetection;
-(void)disablePanDetection;
-(void)disableUndoGestures;
-(void)enableUndoGestures;

-(void)insertEmptyPageAtIndex:(NSInteger)index;
-(void)insertEmptyPageAbove:(id<FTPageProtocol>)page;
-(void)insertEmptyPageBelow:(id<FTPageProtocol>)page;

-(void)invalidateReadingTimer;
-(void)showZoomPanelIfNeeded;
-(void)penButtonAction;
-(void)markerButtonAction;
-(void)eraserButtonAction;
-(void)shapesButtonAction;
-(void)textButtonAction;
-(void)presenterButtonAction;
-(void)lassoButtonAction;
-(void)delayedZoomButtonAction;
-(void)settingsButtonAction;
-(void)finderButtonAction:(BOOL)animated;
-(void)performLayout;
-(void)normalizeAnyPresentedViewController:(BOOL)animate onCompletion:(void (^ _Nullable)(void))completion;

-(void)insertImages:(NSArray<UIImage *> *)pictures center:(CGPoint)center droppedPoint:(CGPoint)point  source:(FTInsertImageSource)imageSource;
-(void)insertClip:(UIImage *)clipImage webClipUrlString:(NSString*)clipUrlString;

-(void)audioButtonAction;
-(void)insertNewPageFromItem:(NSURL*)item onCompletion:(void (^ _Nullable)(BOOL))completion;

-(void)refreshUIforInsertedPagesAtIndex:(NSUInteger)insertionIndex
                                  count:(NSUInteger)numPagesAdded
                          forceReLayout:(BOOL)forceReLayout;
-(void)refreshUIForNonVisiblePageAtIndex:(NSUInteger)pageIndex;

-(BOOL)allowsFreeGestureConditions;

-(void)pasteMenuAction2:(id)sender;
-(void)newCutCopyMenuAction:(id)sender;

// eraser option action
-(void)setToPreviousTool;

-(void)minimizeFavToolBarIfNeeded;

//FTPDFRenderViewController_Extension
-(void) backToShelfButtonAction: (FTNotebookBackAction)backAction with: (NSString*)title;
-(void)updateAnnotationWithColor:(UIColor*_Nonnull)color
                  forAnnotations:(NSArray<FTAnnotation*>*_Nonnull)annotations;
-(void)clearPageButtonAction;
-(void)zoomButtonAction;
-(void)handleSettingsDismiss;
-(void)showPageAtIndex:(NSInteger)index forceReLayout:(BOOL)forceRelayout;

-(NSInteger)numberOfPages;
-(id<FTPageProtocol>_Nullable)currentlyVisiblePage;

-(CGFloat)zoomPanelOverlayheight;
-(BOOL)isInZoomMode;

-(NSInteger)getNewPageInsertIndex;

-(void)showPageAtIndex:(NSInteger)pdfPageIndex
         forceReLayout:(BOOL)forceRelayout
               animate:(BOOL)animate;
-(void)setContentScaleInNormalMode:(CGFloat)inContentScaleInNormalMode pageController:(FTPageViewController*)controller;
-(void)validateMenuItems;

@end

@interface FTPDFRenderViewController (Internal)

- (void)precreateZoomModeTextureForPageAtIndex:(NSInteger)pdfPageIndex;
- (NSArray<FTPageViewController*>* _Nonnull)visiblePageViewControllers;
- (NSArray<FTPageViewController*>* _Nonnull)visiblePageViewControllersWithOffset;
- (FTPageViewController *_Nullable)firstPageController;
- (FTPageViewController *_Nullable)pageController:(CGPoint)atPoint;
- (FTPageViewController *_Nullable)pageControllerFor:(id<FTPageProtocol> _Nonnull)page;
-(void)laserButtonAction;
-(void)readOnlyButtonAction;
-(void)setNeedsLayoutForcibly;
-(void)updateContentSize;

#if TARGET_OS_MACCATALYST
-(void)undoButtonAction;
-(void)redoButtonAction;
#endif
@end
