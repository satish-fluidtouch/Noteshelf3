//
//  FTImage.m
//  PDFAnnotation
//
//  Created by Ashok Prabhu on 14/3/13.
//  Copyright (c) 2013 FluidTouch.biz. All rights reserved.
//

#import "FTImageAnnotation.h"
#import "UIImageAdditions.h"
#import "GLImageRenderingProgram.h"
#import "Noteshelf-Swift.h"
#import "CGAffineTransform_Extended.h"

@interface FTImageAnnotation() <FTCopying,FTDeleting>{
}

@end

@implementation FTImageAnnotation

@synthesize image = _image;
@synthesize transformedImage = _transformedImage;
@synthesize glTexture;
@synthesize transformMatrix = _transformMatrix;
@synthesize screenScale;

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        screenScale = [[UIScreen mainScreen] scale];
        _uuid = [FTUtils GetUUID];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        self.imageTransformMatrix = CGAffineTransformIdentity;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeCGRect:_boundingRect forKey:@"boundingRect"];
    if(self.copyMode)
    {
        [aCoder encodeObject:self.image forKey:@"image"];
        [aCoder encodeObject:self.transformedImage forKey:@"transformedImage"];
    }
    [aCoder encodeFloat:screenScale forKey:@"screenScale"];
    [aCoder encodeCGAffineTransform:_transformMatrix forKey:@"transformMatrix"];
    [aCoder encodeCGAffineTransform:_imageTransformMatrix forKey:@"imageTransformMatrix"];
}

-(id)initWithCoder:(NSCoder*)aDecoder
{
    self=[super initWithCoder:aDecoder];
    if(self)
    {
        _boundingRect = [aDecoder decodeCGRectForKey:@"boundingRect"];
        self.image = [aDecoder decodeObjectForKey:@"image"];
        self.transformedImage = [aDecoder decodeObjectForKey:@"transformedImage"];
        _transformMatrix = [aDecoder decodeCGAffineTransformForKey:@"transformMatrix"];
        _imageTransformMatrix = [aDecoder decodeCGAffineTransformForKey:@"imageTransformMatrix"];

        screenScale = [aDecoder decodeFloatForKey:@"screenScale"];
        if(screenScale == 0)
        {
            screenScale = [[UIScreen mainScreen] scale];
        }
    }
    return self;
}

-(void)deepCopyAnnotation:(id<FTPageProtocol>)toPage onCompletion:(void (^)(FTAnnotation * _Nullable))onCompletion
{
    FTImageAnnotation *annotation = [[self.class alloc] initWithPage:toPage];
    annotation.uuid = [FTUtils GetUUID];
    annotation.boundingRect = self.boundingRect;
    annotation.transformMatrix = self.transformMatrix;
    annotation.imageTransformMatrix = self.imageTransformMatrix;
    annotation.screenScale = self.screenScale;
    annotation.isReadonly = self.isReadonly;
    annotation.version = self.version;
    
    FTFileItemImage *sourceFileItem = [self imageContentFileItem];
    
    if (nil == sourceFileItem) {
        onCompletion(nil);
        return;
    }
    
    FTNoteshelfDocument *document = (FTNoteshelfDocument *)[toPage parentDocument];
    FTFileItemImage *copiedFileItem = [[FTFileItemImage alloc] initWithFileName:[annotation imageContentFileName]];
    copiedFileItem.securityDelegate = document;
    [[document resourceFolderItem] addChildItem:copiedFileItem];
    
    FTFileItemImage *trasnformmedFileItem = [self trasnformedContentFileItem];
    FTFileItemImage *copiedTrasnformmedFileItem = nil;
    NSURL *trasnformmedFileItemURL = nil;
    NSURL *copiedTrasnformmedFileItemURL = nil;
    if(nil != trasnformmedFileItem) {
        copiedTrasnformmedFileItem = [[FTFileItemImage alloc] initWithFileName:[annotation trasnformedContentFileName]];
        copiedTrasnformmedFileItem.securityDelegate = document;
        [[document resourceFolderItem] addChildItem:copiedTrasnformmedFileItem];
        trasnformmedFileItemURL = [trasnformmedFileItem fileItemURL];
        copiedTrasnformmedFileItemURL = [copiedTrasnformmedFileItem fileItemURL];
    }
    
    FTNoteshelfDocument *currentDocument = (FTNoteshelfDocument *)[[self associatedPage] parentDocument];
    if (currentDocument.isSecured || document.isSecured) {
        UIImage *image = sourceFileItem.image;
        copiedFileItem.image = image;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSFileCoordinator *cooridinator = [[NSFileCoordinator alloc] initWithFilePresenter:document];
            if(nil != trasnformmedFileItem) {
                UIImage *trasnformedImage = trasnformmedFileItem.image;
                copiedTrasnformmedFileItem.image = trasnformedImage;
                NSError *error = nil;
                [cooridinator coordinateWritingItemAtURL:copiedFileItem.fileItemURL options:NSFileCoordinatorWritingForReplacing writingItemAtURL:copiedTrasnformmedFileItem.fileItemURL options:NSFileCoordinatorWritingForReplacing error:&error byAccessor:^(NSURL * _Nonnull newURL1, NSURL * _Nonnull newURL2) {
                    [copiedFileItem saveContentsOfFileItem];
                    [copiedTrasnformmedFileItem saveContentsOfFileItem];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        onCompletion(annotation);
                    });
                }];
            }
            else {
                NSError *error = nil;
                [cooridinator coordinateWritingItemAtURL:copiedFileItem.fileItemURL options:NSFileCoordinatorWritingForReplacing error:&error byAccessor:^(NSURL * _Nonnull newURL) {
                    [copiedFileItem saveContentsOfFileItem];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        onCompletion(annotation);
                    });
                }];
            }
        });
    }
    else {
        [NSFileManager coordinatedCopyAtURL:sourceFileItem.fileItemURL
                                      toURL:copiedFileItem.fileItemURL
                               onCompletion:^(BOOL success, NSError * _Nullable error) {
                                   if(nil != trasnformmedFileItem && (nil != trasnformmedFileItemURL) && (nil != copiedTrasnformmedFileItemURL)) {
                                       [NSFileManager coordinatedCopyAtURL:trasnformmedFileItemURL
                                                                     toURL:copiedTrasnformmedFileItemURL
                                                              onCompletion:^(BOOL success, NSError * _Nullable error) {
                                                                  onCompletion(annotation);
                                                              }];
                                   }
                                   else {
                                       onCompletion(annotation);
                                   }
                               }];
    }
}

-(void)willDelete
{
    [[self imageContentFileItem] deleteContent];
    [[self trasnformedContentFileItem] deleteContent];
}

-(void)didReceiveMemoryWarning:(NSNotification *)notice
{
    [self unloadContents];
}

-(FTFileItemImage*)imageContentFileItem
{
    FTNoteshelfDocument *document = (FTNoteshelfDocument *)[self.associatedPage parentDocument];
    FTFileItemImage *imageFileItem = (FTFileItemImage *)[document.resourceFolderItem childFileItemWithName:[self imageContentFileName]];
    return imageFileItem;
}

-(FTFileItemImage*)trasnformedContentFileItem
{
    FTNoteshelfDocument *document = (FTNoteshelfDocument *)[self.associatedPage parentDocument];
    FTFileItemImage *imageFileItem = (FTFileItemImage *)[document.resourceFolderItem childFileItemWithName:[self trasnformedContentFileName]];
    return imageFileItem;
}

-(void)unloadContents
{
    @synchronized(self)
    {
        _image = nil;
        _transformedImage = nil;
        [[self imageContentFileItem] unloadContentsOfFileItem];
        [[self trasnformedContentFileItem] unloadContentsOfFileItem];
        if (self.glTexture && !applicationDidResignActive) {
            [[FTGLRenderer sharedGLRenderer] deleteOpenGLTexture:self.glTexture];
            glTexture = 0;
        }
    }
}

-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.glTexture) {
        [[FTGLRenderer sharedGLRenderer] useGLRendererContext];
        glDeleteTextures(1, &glTexture);
        glTexture = 0;
    }
    
}

#pragma mark - Getters / Setters

-(void)setImageTransformMatrix:(CGAffineTransform)imageTransformMatrix
{
    if(!CGAffineTransformEqualToTransform(imageTransformMatrix, _imageTransformMatrix)) {
        _imageTransformMatrix = imageTransformMatrix;
        self.forceRender = true;
    }
}

-(void)setBoundingRect:(CGRect)newBoundingRect{
    if(!CGSizeEqualToSize(newBoundingRect.size, _boundingRect.size)) {
        self.forceRender = true;
    }
    [super setBoundingRect:newBoundingRect];
}

-(void)setOffset:(CGPoint)offset
{
    if(!CGPointEqualToPoint(offset, CGPointZero))
    {
        CGRect strokeBoundingRect = self.boundingRect;
        strokeBoundingRect.origin = CGPointTranslate(strokeBoundingRect.origin, offset.x, offset.y);
        self.boundingRect = strokeBoundingRect;
    }
}

-(FTAnnotationType)annotationType
{
    return FTAnnotationTypeImage;
}

-(UIImage*)image
{
    if(nil == _image) {
        _image = [self imageContentFileItem].image;
    }
    return _image;
}

-(void)setImage:(UIImage *)inImage
{
    _image = inImage;
    if(nil != self.associatedPage) {
        FTNoteshelfDocument *document = (FTNoteshelfDocument *)[self.associatedPage parentDocument];
        FTFileItemImage *imageFileItem = [self imageContentFileItem];
        if(nil == imageFileItem)
        {
            imageFileItem = [[FTFileItemImage alloc] initWithFileName:[self imageContentFileName]];
            imageFileItem.securityDelegate = document;
            [[document resourceFolderItem] addChildItem:imageFileItem];
        }
        imageFileItem.image = inImage;
        self.forceRender = true;
    }
}

-(UIImage*)transformedImage
{
    if(nil == _transformedImage) {
        _transformedImage = [self trasnformedContentFileItem].image;
    }
    return _transformedImage;
}

-(void)setTransformedImage:(UIImage*)txImage
{
    if(txImage == nil && self.version >= [FTImageAnnotation v2ImageEditVersion]) {
        _transformedImage = txImage;
        FTFileItemImage *imageFileItem = [self trasnformedContentFileItem];
        [imageFileItem deleteContent];
        return;
    }
    
    _transformedImage = [UIImage imageWithCGImage:txImage.CGImage scale:1 orientation:txImage.imageOrientation];

    if(nil != self.associatedPage) {
        FTFileItemImage *imageFileItem = [self trasnformedContentFileItem];
        if(nil == imageFileItem)
        {
            FTNoteshelfDocument *document = (FTNoteshelfDocument *)[self.associatedPage parentDocument];
            imageFileItem = [[FTFileItemImage alloc] initWithFileName:[self trasnformedContentFileName]];
            imageFileItem.securityDelegate = document;
            [[document resourceFolderItem] addChildItem:imageFileItem];
        }
        imageFileItem.image = _transformedImage;
    }
    self.forceRender = true;
}

-(NSString*)description
{
    NSString *descriptionString=[NSString stringWithFormat:@"BoundingRect of image= %@",NSStringFromCGRect(self.boundingRect)];

    return descriptionString;
}


#pragma mark - OpenGL Rendering

-(void)renderInOpenGL2Context:(EAGLContext *)context
                        scale:(CGFloat)scale
                 clippingRect:(CGRect)clipRect
        imageRenderingProgram:(GLImageRenderingProgram*)imageRenderingProgram;
{
    if (self.hidden) {
        return;
    }

    if(self.version >= [FTImageAnnotation v2ImageEditVersion]) {
        [self renderInOpenGL2ContextV5:context
                                 scale:scale
                          clippingRect:clipRect
                 imageRenderingProgram:imageRenderingProgram];
        return;
    }

    @synchronized(self)
    {
        self.currentScale = scale;
        UIImage *localImage = self.transformedImage;
        CGAffineTransform transformToApply = CGAffineTransformIdentity;
        if(nil == localImage) {
            transformToApply = self.transformMatrix;
            localImage = self.image;
        }
        CGSize imageSize = localImage.size;

        if (!self.glTexture || self.forceRender) {
            self.forceRender = false;
            if(self.glTexture) {
                [[FTGLRenderer sharedGLRenderer] useGLRendererContext];
                glDeleteTextures(1, &glTexture);
                glTexture = 0;
            }

            self.glTexture = [[FTGLRenderer sharedGLRenderer] getOpenGLTextureForImage2:localImage.CGImage context:context];
        }
        
        if([EAGLContext currentContext] != context)
            [EAGLContext setCurrentContext:context];
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
        [imageRenderingProgram use];
        
        CGFloat imageScaleLocal = screenScale;
        
        CGRect layerBoundRect = CGRectScale(self.renderingRect, scale);
        CGFloat ratioX = (imageSize.width/layerBoundRect.size.width);
        CGFloat ratioY = (imageSize.height/layerBoundRect.size.height);
        
        CGAffineTransform effectiveTransform = CGAffineTransformMakeScale((scale*ratioX)/imageScaleLocal, (scale*ratioY)/imageScaleLocal);
        effectiveTransform = CGAffineTransformConcat(effectiveTransform, transformToApply);
        
        [imageRenderingProgram setMvpMatrixForSize:clipRect.size
                                         transform:effectiveTransform];
        
        CGRect layerBoundingRect = CGRectIntegral(CGRectScale(self.renderingRect, scale));
        
        CGFloat texPixelWidth   = 1.0 / layerBoundingRect.size.width;
        CGFloat texPixelHeight  = 1.0 / layerBoundingRect.size.height;
        
        //Bring to tile origin
        layerBoundingRect.origin = CGPointTranslate(layerBoundingRect.origin, -clipRect.origin.x, -clipRect.origin.y);
        layerBoundingRect.origin.y = clipRect.size.height - layerBoundingRect.origin.y - layerBoundingRect.size.height;
        
        CGRect clipRectGL = clipRect;
        clipRectGL.origin = CGPointZero;
        
        CGAffineTransform aTransform = CGAffineTransformMakeTranslation(-layerBoundingRect.origin.x, -layerBoundingRect.origin.y);
        aTransform = CGAffineTransformScale(aTransform, texPixelWidth, texPixelHeight);
        
        CGRect clipRectGLTransformed = CGRectApplyAffineTransform(clipRectGL, aTransform);
        
        clipRectGLTransformed.origin.x *= texPixelWidth;
        clipRectGLTransformed.origin.y *= texPixelHeight;
        
        const GLfloat textureCoordinates[] = {
            clipRectGLTransformed.origin.x,     //bottom-left x
            clipRectGLTransformed.origin.y,     //bottom-left y
            
            clipRectGLTransformed.origin.x + clipRectGLTransformed.size.width, //bottom-right x
            clipRectGLTransformed.origin.y,  //bottom-right y
            
            clipRectGLTransformed.origin.x,  //top-left x
            clipRectGLTransformed.origin.y + clipRectGLTransformed.size.height, //top-left y
            
            clipRectGLTransformed.origin.x + clipRectGLTransformed.size.width,  //top-right x
            clipRectGLTransformed.origin.y + clipRectGLTransformed.size.height, //top-right y
        };
        
        static const GLfloat squareVertices[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f,
        };
        
        __unused static const GLfloat flatTextureCoordinates[] = {
            0.0f, 0.0f,  //bottom-left x, y
            1.0f, 0.0f,  //bottom-right x, y
            0.0f,  1.0f, //top-left x, y
            1.0f,  1.0f, //top-right x, y
        };
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, glTexture);
        glUniform1i(imageRenderingProgram.imageTexture, 0);
        
        glVertexAttribPointer(imageRenderingProgram.imagePositionSlot, 2, GL_FLOAT, 0, 0, squareVertices);
        glVertexAttribPointer(imageRenderingProgram.imageTexureCoordinates, 2, GL_FLOAT, 0, 0, textureCoordinates);
        
        glEnable(GL_SCISSOR_TEST);
        glScissor(layerBoundingRect.origin.x, layerBoundingRect.origin.y, layerBoundingRect.size.width, layerBoundingRect.size.height);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glDisable(GL_SCISSOR_TEST);
        
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}


#pragma mark - Core Graphics Rendering -

-(void)renderInContext:(CGContextRef)context scale:(CGFloat)scale
{
    if(self.version >= [FTImageAnnotation v2ImageEditVersion]) {
        [self renderInContextV5:context scale:scale];
        return;
    }
    
    @synchronized(self)
    {
        if(!self.hidden)
        {
            CGContextSaveGState(context);
            CGRect scaledBounds = CGRectIntegral(CGRectScale(self.boundingRect,scale));
            
            CGContextTranslateCTM(context, scaledBounds.origin.x, scaledBounds.origin.y);
            scaledBounds.origin = CGPointZero;

            UIImage *localImage = self.transformedImage;
            CGAffineTransform transformToApply = CGAffineTransformIdentity;
            if(nil == localImage) {
                localImage = self.image;
                transformToApply = self.transformMatrix;
            }
            
            CGAffineTransform dummy=CGAffineTransformMake(0, 0, 0, 0, 0, 0);
            
            if((!CGAffineTransformEqualToTransform(transformToApply, CGAffineTransformIdentity) && !CGAffineTransformEqualToTransform(transformToApply, dummy)))
            {
                
                // Transform the image (as the image view has been transformed)
                
                CGContextTranslateCTM(context, CGRectGetMidX(scaledBounds), CGRectGetMidY(scaledBounds));

                CGContextScaleCTM(context, scale, scale);
                CGContextConcatCTM(context, transformToApply);
                
                CGSize imageSize = CGSizeScale(localImage.size,localImage.scale/screenScale);
                
                CGContextTranslateCTM(context, -imageSize.width*0.5, -imageSize.height*0.5);
                CGContextTranslateCTM(context, 0.0, imageSize.height);
                CGContextScaleCTM(context, 1.0, -1.0);
                
                // Draw view into context
                CGRect imageRect = CGRectMake(0,0,imageSize.width,imageSize.height);
                CGContextDrawImage(context,imageRect, localImage.CGImage);
            }
            else {
                CGContextTranslateCTM(context, CGRectGetMinX(scaledBounds), CGRectGetMaxY(scaledBounds));
                CGContextScaleCTM(context, 1.0, -1.0);
                // Draw view into context
                CGContextDrawImage(context, CGRectMake(0,0,scaledBounds.size.width, scaledBounds.size.height), localImage.CGImage);
            }
            
            CGContextRestoreGState(context);
        }
    }
}


- (BOOL)intersectsPath:(CGPathRef)inSelectionPath withScale:(CGFloat)scale withOffset:(CGPoint)selectionOffset
{
    @synchronized(self)
    {
        BOOL result=NO;
        
        CGRect selectionPathBounds=CGPathGetBoundingBox(inSelectionPath);
        selectionPathBounds.origin=CGPointMake(selectionPathBounds.origin.x+selectionOffset.x, selectionPathBounds.origin.y+selectionOffset.y);
        CGRect boundingRect1 = CGRectScale(self.renderingRect, scale);
        if(CGRectIntersectsRect(boundingRect1,selectionPathBounds))
        {
            CGRect intersectionRect=CGRectIntersection(boundingRect1, selectionPathBounds);
            CGRect rect = intersectionRect;
            size_t width = floorf(rect.size.width);
            size_t height = floorf(rect.size.height);
            uint8_t *bits = calloc(width * height, sizeof(*bits));
            CGContextRef bitmapContext =
            CGBitmapContextCreate(bits,
                                  width,
                                  height,
                                  sizeof(*bits) * 8,
                                  width,
                                  NULL,
                                  kCGImageAlphaOnly);
            
            
            CGContextTranslateCTM(bitmapContext, 0, height);
            CGContextScaleCTM(bitmapContext, 1, -1);
            
            CGContextSetShouldAntialias(bitmapContext, NO);
            
            //We want the portion of the image to be drawn in that intersection rect. So translate, such that portion gets drawn
            CGContextTranslateCTM(bitmapContext, -(rect.origin.x), -(rect.origin.y));
            CGContextSaveGState(bitmapContext);
            //Since our selection path is from lasso view which is in different coordinate system,this transaltion is necessary
            CGContextTranslateCTM(bitmapContext, (selectionOffset.x), (selectionOffset.y));
            CGContextAddPath(bitmapContext, inSelectionPath);
            CGContextRestoreGState(bitmapContext);
            CGContextClip(bitmapContext);
            [self renderInContext:bitmapContext scale:scale];
            
            NSUInteger x = 0;
            for (; x < width; ++x)
            {
                for (NSUInteger y = 0; y < height; ++y)
                {
                    if (bits[y * width + x] !=0)
                    {
                        result=YES;
                        break;
                    }
                }
                if (result) {
                    break;
                    
                }
            }
            
            free(bits);
            if(bitmapContext)
                CFRelease(bitmapContext);
            
        }
        return result;
    }
}

-(BOOL)allowsResize
{
    return YES;
}

-(NSString*)imageContentFileName
{
    return [self.uuid stringByAppendingString:@".png"];
}

-(NSString*)trasnformedContentFileName
{
    return [self.uuid stringByAppendingString:@"_tx.png"];
}

-(NSArray *)resourceFileNames
{
    if(self.version >= [FTImageAnnotation v2ImageEditVersion]) {
        return @[[self imageContentFileName]];
    }
    return @[[self imageContentFileName],[self trasnformedContentFileName]];
}

-(BOOL)allowsEditing
{
    return YES;
}
#pragma mark - V5 Rendering (private) -
-(void)renderInOpenGL2ContextV5:(EAGLContext *)context
                          scale:(CGFloat)scale
                   clippingRect:(CGRect)clipRect
          imageRenderingProgram:(GLImageRenderingProgram*)imageRenderingProgram;
{
    if (self.hidden) {
        return;
    }
    
    @synchronized(self) {
        self.currentScale = scale;
        UIImage *localImage = self.image;
        CGAffineTransform transformToApply = CGAffineTransformIdentity;
        
        CGRect annotationRenderRect = CGRectScale(self.renderingRect, self.screenScale);
        
        int maxTextureSize;
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
        CGSize textureSize = [self aspectFittedRect:annotationRenderRect.size max:CGSizeMake(maxTextureSize, maxTextureSize)];
        annotationRenderRect.size = textureSize;
        CGSize imageSize = annotationRenderRect.size;
        
        if (!self.glTexture || self.forceRender) {
            self.forceRender = false;
            if(self.glTexture) {
                [[FTGLRenderer sharedGLRenderer] useGLRendererContext];
                glDeleteTextures(1, &glTexture);
                glTexture = 0;
            }
            
            CGRect boundRect = CGRectScale(self.boundingRect, self.screenScale);
            annotationRenderRect.origin = CGPointZero;
            
            CGAffineTransform transform = CGAffineTransformMakeScale(boundRect.size.width/self.image.size.width, boundRect.size.height/self.image.size.height);
            
            transform = CGAffineTransformConcat(transform, self.imageTransformMatrix);
            
            localImage = [self.image resizedImage:annotationRenderRect.size
                                        transform:transform
                                     clippingRect:annotationRenderRect
                                      screenScale:1
                                    includeBorder:NO];
            
            self.glTexture = [[FTGLRenderer sharedGLRenderer] getOpenGLTextureForImage2:localImage.CGImage context:context];
        }
        
        if([EAGLContext currentContext] != context)
            [EAGLContext setCurrentContext:context];
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
        [imageRenderingProgram use];
        
        CGFloat imageScaleLocal = screenScale;
        
        CGRect layerBoundRect = CGRectScale(self.renderingRect, scale);
        CGFloat ratioX = (imageSize.width/layerBoundRect.size.width);
        CGFloat ratioY = (imageSize.height/layerBoundRect.size.height);
        
        CGAffineTransform effectiveTransform = CGAffineTransformMakeScale((scale*ratioX)/imageScaleLocal, (scale*ratioY)/imageScaleLocal);
        effectiveTransform = CGAffineTransformConcat(effectiveTransform, transformToApply);
        
        [imageRenderingProgram setMvpMatrixForSize:clipRect.size
                                         transform:effectiveTransform];
        
        CGRect layerBoundingRect = CGRectIntegral(CGRectScale(self.renderingRect, scale));
        
        CGFloat texPixelWidth   = 1.0 / layerBoundingRect.size.width;
        CGFloat texPixelHeight  = 1.0 / layerBoundingRect.size.height;
        
        //Bring to tile origin
        layerBoundingRect.origin = CGPointTranslate(layerBoundingRect.origin, -clipRect.origin.x, -clipRect.origin.y);
        layerBoundingRect.origin.y = clipRect.size.height - layerBoundingRect.origin.y - layerBoundingRect.size.height;
        
        CGRect clipRectGL = clipRect;
        clipRectGL.origin = CGPointZero;
        
        CGAffineTransform aTransform = CGAffineTransformMakeTranslation(-layerBoundingRect.origin.x, -layerBoundingRect.origin.y);
        aTransform = CGAffineTransformScale(aTransform, texPixelWidth, texPixelHeight);
        
        CGRect clipRectGLTransformed = CGRectApplyAffineTransform(clipRectGL, aTransform);
        
        clipRectGLTransformed.origin.x *= texPixelWidth;
        clipRectGLTransformed.origin.y *= texPixelHeight;
        
        const GLfloat textureCoordinates[] = {
            clipRectGLTransformed.origin.x,     //bottom-left x
            clipRectGLTransformed.origin.y,     //bottom-left y
            
            clipRectGLTransformed.origin.x + clipRectGLTransformed.size.width, //bottom-right x
            clipRectGLTransformed.origin.y,  //bottom-right y
            
            clipRectGLTransformed.origin.x,  //top-left x
            clipRectGLTransformed.origin.y + clipRectGLTransformed.size.height, //top-left y
            
            clipRectGLTransformed.origin.x + clipRectGLTransformed.size.width,  //top-right x
            clipRectGLTransformed.origin.y + clipRectGLTransformed.size.height, //top-right y
        };
        
        static const GLfloat squareVertices[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f,
        };
        
        __unused static const GLfloat flatTextureCoordinates[] = {
            0.0f, 0.0f,  //bottom-left x, y
            1.0f, 0.0f,  //bottom-right x, y
            0.0f,  1.0f, //top-left x, y
            1.0f,  1.0f, //top-right x, y
        };
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, glTexture);
        glUniform1i(imageRenderingProgram.imageTexture, 0);
        
        glVertexAttribPointer(imageRenderingProgram.imagePositionSlot, 2, GL_FLOAT, 0, 0, squareVertices);
        glVertexAttribPointer(imageRenderingProgram.imageTexureCoordinates, 2, GL_FLOAT, 0, 0, textureCoordinates);
        
        glEnable(GL_SCISSOR_TEST);
        glScissor(layerBoundingRect.origin.x, layerBoundingRect.origin.y, layerBoundingRect.size.width, layerBoundingRect.size.height);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glDisable(GL_SCISSOR_TEST);
        
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}

-(void)renderInContextV5:(CGContextRef)context scale:(CGFloat)scale
{
    @synchronized(self) {
        if(!self.hidden) {
            CGContextSaveGState(context);
            CGRect scaledBounds = CGRectIntegral(CGRectScale(self.boundingRect,scale));
            
            CGContextTranslateCTM(context, scaledBounds.origin.x, scaledBounds.origin.y);
            scaledBounds.origin = CGPointZero;
            
            CGContextTranslateCTM(context, CGRectGetMidX(scaledBounds), CGRectGetMidY(scaledBounds));
            CGContextConcatCTM(context, self.imageTransformMatrix);
            
            CGContextTranslateCTM(context, -CGRectGetMidX(scaledBounds), -CGRectGetMidY(scaledBounds));
            
            CGContextTranslateCTM(context, 0.0, scaledBounds.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            
            // Draw view into context
            CGContextDrawImage(context, CGRectMake(0,0,scaledBounds.size.width, scaledBounds.size.height), self.image.CGImage);
            
            CGContextRestoreGState(context);
        }
    }
}

#pragma mark - FTTransformScale -
-(void)applyTransformScale:(CGFloat)scale
{
    if(scale == 1) {
        return;
    }

    CGRect boundingRect = self.boundingRect;
    boundingRect.size = CGSizeScale(boundingRect.size, scale);
    self.boundingRect = boundingRect;
    
    if(self.version < 5) {
        //modify the transform change due to change in scale.
        CGAffineTransform currentScaleTransform = CGAffineTransformIdentity;
        CGAffineTransform scaleTransform = self.transformMatrix;
        if(self.version == 1) {
            CGSize imageSize = CGSizeScale(self.image.size,1/self.screenScale);
            currentScaleTransform = CGAffineTransformMakeScale(boundingRect.size.width/imageSize.width, boundingRect.size.height/imageSize.height);
            scaleTransform = currentScaleTransform;
        }
        else {
            currentScaleTransform = CGAffineTransformMakeScale(scale, scale);
            scaleTransform = CGAffineTransformConcat(currentScaleTransform, self.transformMatrix);
        }
        
        //modify the image transform change due to change in scale.
        CGAffineTransform tranform = self.imageTransformMatrix;
        CGFloat angle = CGAffineTransformGetRotation(tranform);
        tranform = CGAffineTransformRotate(tranform, -angle);
        
        CGFloat currentScaleX = CGAffineTransformGetScaleX(tranform);
        CGFloat currentScaleY = CGAffineTransformGetScaleY(tranform);
        
        tranform = CGAffineTransformScale(tranform, 1/currentScaleX, 1/currentScaleY);
        
        CGFloat transX = CGAffineTransformGetTranslateX(tranform);
        CGFloat transY = CGAffineTransformGetTranslateY(tranform);
        tranform = CGAffineTransformTranslate(tranform, (transX*scale)-transX, (transY*scale)-transY);
        
        tranform = CGAffineTransformScale(tranform, currentScaleX, currentScaleY);
        
        tranform = CGAffineTransformRotate(tranform, angle);
        
        self.imageTransformMatrix = tranform;
        CGAffineTransform transformToApply = CGAffineTransformConcat(scaleTransform, self.imageTransformMatrix);
        
        //get the thumb image.
        CGRect clipRect = CGRectIntegral(boundingRect);
        clipRect.origin = CGPointZero;
        
        UIImage *img = [self.image  resizedImage:clipRect.size
                                       transform:transformToApply
                                    clippingRect:clipRect
                                     screenScale:self.screenScale
                                   includeBorder:NO];
        self.transformedImage = img;
        self.transformMatrix = scaleTransform;
    }
}

+(NSInteger)defaultAnnotationVersion
{
    //version 1: images from NS1
    //version 2-4: 1st version of NS2
    //version 5: new edit feature
    return 5;
}

+(NSInteger)v2ImageEditVersion
{
    return 5;
}

-(CGRect)renderingRect
{
    if(self.version >= [FTImageAnnotation v2ImageEditVersion]) {
        CGAffineTransform tranform = self.imageTransformMatrix;
        CGRect boundingRect = CGRectApplyAffineTransform(self.boundingRect, tranform);
        boundingRect.origin.x = CGRectGetMidX(self.boundingRect) - CGRectGetWidth(boundingRect)*0.5;
        boundingRect.origin.y = CGRectGetMidY(self.boundingRect) - CGRectGetHeight(boundingRect)*0.5;
        return boundingRect;
    }
    else {
        return [super renderingRect];
    }
}

-(BOOL)isPointInside:(CGPoint)point
{
    CGRect frame = self.boundingRect;
    CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    
    CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(center.x, center.y);
    CGAffineTransform rotationTransform = self.imageTransformMatrix;
    CGAffineTransform customRotation = CGAffineTransformConcat(CGAffineTransformConcat( CGAffineTransformInvert(translateTransform), rotationTransform), translateTransform);
    
    CGPoint point1 = CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame));
    point1 = CGPointApplyAffineTransform(point1, customRotation);

    CGPoint point2 = CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame));
    point2 = CGPointApplyAffineTransform(point2, customRotation);

    CGPoint point3 = CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame));
    point3 = CGPointApplyAffineTransform(point3, customRotation);

    CGPoint point4 = CGPointMake(CGRectGetMaxX(frame), CGRectGetMinY(frame));
    point4 = CGPointApplyAffineTransform(point4, customRotation);

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:point1];
    [path addLineToPoint:point2];
    [path addLineToPoint:point3];
    [path addLineToPoint:point4];
    [path closePath];
    return [path containsPoint:point];
}

-(CGPoint)RotatePointAboutOrigin:(CGPoint)point angle:(float)angle
{
    float s = sinf(angle);
    float c = cosf(angle);
    return CGPointMake(c * point.x - s * point.y, s * point.x + c * point.y);
}

- (CGSize) aspectFittedRect:(CGSize)inSize max:(CGSize)maxSize
{
    if (inSize.width <= maxSize.width && inSize.height <= maxSize.height) {
        return inSize;
    }
    
    float originalAspectRatio = inSize.width / inSize.height;
    float maxAspectRatio = maxSize.width / maxSize.height;
    
    CGSize newSize = maxSize;
    if (originalAspectRatio > maxAspectRatio) { // scale by width
        newSize.height = (int) (maxSize.height * inSize.height / inSize.width);
    } else {
        newSize.width = (int) (maxSize.height  * inSize.width / inSize.height);
    }
    
    return newSize;
}

@end

