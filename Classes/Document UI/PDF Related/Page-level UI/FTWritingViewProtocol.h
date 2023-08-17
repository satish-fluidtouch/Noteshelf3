//
//  FTWritingViewProtocol.h
//  Noteshelf
//
//  Created by Amar on 14/08/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

#ifndef FTWritingViewProtocol_h
#define FTWritingViewProtocol_h

@import FTRenderKit;

@class FTPenSet,FTRenderingProperties;
@protocol FTPageProtocol,FTPageContentDelegate,FTPageAnnotationHandler;

@protocol FTPenAttributesProviderDelegate <NSObject>

-(FTPenSet*)penAttributes;
-(RKDeskMode)currentDeskMode;

@end

@protocol FTWritingProtocol <NSObject>

@property(assign) CGFloat scale;
@property(assign) CGFloat pdfInitialScale;
@property(assign) CGFloat zoomScale;
@property(weak) id<FTPageProtocol> pageToDisplay;
@property(assign) FTRenderMode mode;
@property(assign) RKDeskMode currentDrawingMode;
@property(weak) id<FTPageContentDelegate,FTPageAnnotationHandler> pageContentDelegate;
@property (assign) BOOL isCurrentPage;
@property (assign) BOOL loadingFirstTime;
@property (assign) BOOL zooming;
@property (assign) BOOL isIntroScreen;
@property (weak) id<FTPenAttributesProviderDelegate> penAttributesProvider;
@property (assign) CGRect bounds;

-(void)waitUntilComplete;
-(void)cancelCurrentStroke;
-(void)reset:(BOOL)forcibly;
-(void)registerViewForTouchEvents;
-(void)unregisterViewForTouchEvents:(BOOL)setToDefault;

-(void)performEraseAction:(CGPoint)erasePoint
               eraserSize:(NSInteger)eraserSize
               touchPhase:(UITouchPhase)phase;

-(void)didEndZooming:(CGFloat)scale;
-(void)willBeginZooming;
-(void)willEnterZoomMode;
-(void)didExitZoomMode;

-(void)reloadTilesInRect:(CGRect)rect properties:(FTRenderingProperties*)properties;
-(void)removeTilesMarkedAsShouldRemove;
-(void)releaseTilesNotInRect:(CGRect)rect extraTilesCount:(NSInteger)tilesCount;

-(void)updateLowResolutionImageBackgroundView;
-(BOOL)isPDFTextSelected;

@end

@protocol FTLassoProtocol <NSObject>

-(void)moveSelectedAnnotations:(NSArray*)annotations offset:(CGPoint)offset  refreshForcibly:(BOOL)forcibly;
-(void)lassoDidMovedByOffset:(CGPoint)offset;
//annotations is generally nil, but only while copy-paste operation, this will not be nil.
-(void)finalizeSelectionByAddingAnnotations:(NSArray* _Nullable)annotations;

@end

#endif /* FTWritingViewProtocol_h */
