//
//  FTAnnotation.m
//  PDFAnnotation
//
//  Created by Ashok Prabhu on 15/3/13.
//  Copyright (c) 2013 FluidTouch.biz. All rights reserved.
//

#import "FTAnnotation.h"
#import "FTStroke.h"
#import "FTImageAnnotation.h"
#import "FTStickyImageAnnotation.h"
#import "FTTextAnnotation.h"
#import "Noteshelf-Swift.h"

@implementation FTAnnotation

@synthesize boundingRect = _boundingRect;
@synthesize hidden;
@synthesize selected;
@synthesize offset;
@synthesize associatedPage;
@synthesize uuid = _uuid;
@synthesize currentScale = _currentScale;
@synthesize copyMode;
@synthesize version;

-(instancetype)initWithPage:(id<FTPageProtocol>)page
{
    self = [self init];
    if(self) {
        self.associatedPage = page;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        _currentScale = 0;
        _isReadonly = false;
        self.version = [self.class defaultAnnotationVersion];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_uuid forKey:@"uuid"];
    [aCoder encodeBool:_isReadonly forKey:@"isReadonly"];
    [aCoder encodeInteger:self.version forKey:@"version"];
}

-(id)initWithCoder:(NSCoder*)aDecoder
{
    self=[super init];
    if(self)
    {
        _uuid = [aDecoder decodeObjectForKey:@"uuid"];
        _isReadonly = [aDecoder decodeBoolForKey:@"isReadonly"];
        self.version = [aDecoder decodeIntegerForKey:@"version"];
    }
    return self;
}

#pragma mark boundingRect
-(void)setBoundingRect:(CGRect)boundingRect
{
    if(!CGRectEqualToRect(_boundingRect, boundingRect))
    {
        _boundingRect = boundingRect;
    }
}

-(void)renderInContext:(CGContextRef)context scale:(CGFloat)scale
{
    
}

- (BOOL)intersectsPath:(CGPathRef)inSelectionPath withScale:(CGFloat)scale withOffset:(CGPoint)selectionOffset
{
    //Subclasses should override this returning appropriate value
    return NO;
}

-(FTAnnotationType)annotationType
{
    return FTAnnotationTypeNone;
}

-(BOOL)allowsResize
{
    return NO;
}

-(BOOL)allowsEditing
{
    return NO;
}

-(BOOL)allowsCopyPaste
{
    return YES;
}

-(BOOL)saveContents
{
    return YES;
}

-(CGRect)renderingRect
{
    return self.boundingRect;
}

-(void)unloadContents
{
    
}

-(void)loadContents
{
    
}

-(NSArray *)resourceFileNames
{
    return nil;
}

-(void)deepCopyAnnotation:(id<FTPageProtocol>)toPage onCompletion:(void (^)(FTAnnotation * _Nonnull))onCompletion
{
    onCompletion(self);
}

-(void)willDelete
{
    
}

#pragma mark - FTTransformScale -
-(void)applyTransformScale:(CGFloat)scale
{
    
}

-(BOOL)isPointInside:(CGPoint)point
{
    return CGRectContainsPoint(self.boundingRect, point);
}

+(NSInteger)defaultAnnotationVersion
{
    return 4;
}

@end
