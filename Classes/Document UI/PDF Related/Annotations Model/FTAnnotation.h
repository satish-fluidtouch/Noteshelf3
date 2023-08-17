//
//  FTAnnotation.h
//  PDFAnnotation
//
//  Created by Ashok Prabhu on 15/3/13.
//  Copyright (c) 2013 FluidTouch.biz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "FTUtils.h"
#import "FTPrivateProtocols.h"

@protocol FTPageProtocol;
@protocol FTCopying;

@import NSMetalRender;

@interface FTAnnotation : NSObject <NSCoding,FTCopying,FTDeleting,FTTransformScale>
{
    CGRect _boundingRect;
    NSString *_uuid;
    CGFloat _currentScale;
}

@property (assign) BOOL forceRender;
@property(nonatomic,assign)  CGRect boundingRect;
@property (nonatomic,strong) NSString *uuid;
@property(nonatomic,assign)  BOOL hidden;
@property(nonatomic,assign)  BOOL selected;
@property CGPoint offset;
@property (nonatomic,weak) id<FTPageProtocol> associatedPage;
@property (assign) CGFloat currentScale;
@property(nonatomic,assign)  BOOL copyMode;
@property (nonatomic,assign) NSTimeInterval modifiedTimeInterval;
@property (nonatomic,assign) NSTimeInterval createdTimeInterval;
@property (nonatomic,assign) BOOL isEditingInProgress;
@property (nonatomic,assign) BOOL isReadonly;
@property (nonatomic,assign) NSInteger version;
@property (nonatomic,assign) BOOL disableUndoManagement;

@property (nonatomic,readonly) CGRect renderingRect;

@property (nonatomic,readonly) FTAnnotationType annotationType;

-(instancetype)initWithPage:(id<FTPageProtocol>)page;

-(NSArray *)resourceFileNames;

-(void)renderInContext:(CGContextRef)context scale:(CGFloat)scale;

- (BOOL)intersectsPath:(CGPathRef)inSelectionPath withScale:(CGFloat)scale withOffset:(CGPoint)selectionOffset;

-(BOOL)allowsResize;

-(BOOL)allowsCopyPaste;

-(BOOL)saveContents;
-(void)loadContents;
-(void)unloadContents;

-(BOOL)allowsEditing;

-(BOOL)isPointInside:(CGPoint)point;

+(NSInteger)defaultAnnotationVersion;
@end
