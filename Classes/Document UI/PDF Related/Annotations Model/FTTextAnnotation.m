//
//  TextArea.m
//  PDFAnnotation
//
//  Created by Ashok Prabhu on 14/3/13.
//  Copyright (c) 2013 FluidTouch.biz. All rights reserved.
//

#import "FTTextAnnotation.h"
#import "UIColorAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "UIImageAdditions.h"
#import "GLImageRenderingProgram.h"
#import "FTTextLayouter.h"
#import "Noteshelf-Swift.h"
#import "FTTextView.h"
#import "NSAttributedString_Extended.h"

@interface FTTextAnnotation() <FTCopying>

@end

@implementation FTTextAnnotation

@synthesize attributedString = _attributedString;
@synthesize dataValue;

@synthesize glTexture;

- (id)init
{
    self = [super init];
    if (self) {
        self.transformScale = 1;
        self.currentScale = 1.0f;
        self.uuid = [FTUtils GetUUID];
        self.forceRender = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
    }
    return self;
}


-(void)deepCopyAnnotation:(id<FTPageProtocol>)toPage onCompletion:(void (^)(FTAnnotation * _Nonnull))onCompletion
{
    FTTextAnnotation *annotation = [[FTTextAnnotation alloc] initWithPage:toPage];
    annotation.boundingRect = self.boundingRect;
    annotation.attributedString = [[NSAttributedString alloc] initWithAttributedString:self.attributedString];
    annotation.isReadonly = self.isReadonly;
    annotation.version = self.version;
    annotation.transformScale = self.transformScale;
    onCompletion(annotation);
}

-(void)didReceiveMemoryWarning:(NSNotification *)notice{
    @synchronized(self)
    {
        if (self.glTexture && !applicationDidResignActive) {
            [[FTGLRenderer sharedGLRenderer] useGLRendererContext];
            glDeleteTextures(1, &glTexture);
            glTexture = 0;
        }        
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.glTexture) {
        [[FTGLRenderer sharedGLRenderer] useGLRendererContext];
        glDeleteTextures(1, &glTexture);
        glTexture = 0;
    }
}

-(void)unloadContents
{
    @synchronized(self) {
        if (self.glTexture) {
            [[FTGLRenderer sharedGLRenderer] deleteOpenGLTexture:self.glTexture];
            glTexture = 0;
        }
    }
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_uuid forKey:@"uuid"];
    [aCoder encodeBool:self.isReadonly forKey:@"isReadonly"];
    [aCoder encodeInteger:self.version forKey:@"version"];
    [aCoder encodeCGRect:_boundingRect forKey:@"boundingRect"];
    [aCoder encodeDouble:self.transformScale forKey:@"transformScale"];
    
    NSData *data = [_attributedString dataFromRange:NSMakeRange(0, _attributedString.length) documentAttributes:@{NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType} error:nil];
   
    [aCoder encodeObject:data forKey:@"text"];
}

-(id)initWithCoder:(NSCoder*)aDecoder
{
    self=[super init];
    if(self)
    {
        _uuid = [aDecoder decodeObjectForKey:@"uuid"];
        self.isReadonly = [aDecoder decodeBoolForKey:@"isReadonly"];
        self.version = [aDecoder decodeIntegerForKey:@"version"];
        _boundingRect=[aDecoder decodeCGRectForKey:@"boundingRect"];
        
        self.transformScale = [aDecoder decodeDoubleForKey:@"transformScale"];

        NSData *data = [aDecoder decodeObjectForKey:@"text"];
        if(data)
        {
            NSAttributedString *str = [[NSAttributedString alloc] initWithData:data options:@{NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType} documentAttributes:nil error:nil];
            _attributedString = [str mapAttributesToMatchWithLineHeight:-1];
        }
    }
    return self;
}

#pragma mark Data I/O

-(void)setDataValue:(NSData *)inDataValue{
    
    if(inDataValue)
    {
        NSAttributedString *str = [[NSAttributedString alloc] initWithData:inDataValue options:@{NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType} documentAttributes:nil error:nil];
        str = [str mapAttributesToMatchWithLineHeight:-1];
        NSMutableAttributedString *atrStr = [[NSMutableAttributedString alloc] initWithAttributedString:str];
        [atrStr applyScale:1 originalScaleToApply:self.transformScale];
        _attributedString = atrStr;
    }
}

-(NSData *)dataValue{
    NSMutableAttributedString *attributedString = [_attributedString mutableCopy];
    
    [attributedString enumerateAttribute:@"NSOriginalFont" inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(UIFont *originalFont, NSRange range, BOOL *stop) {
        if (originalFont) {
            [attributedString addAttribute:NSFontAttributeName value:originalFont range:range];
        }
    }];

    return [attributedString dataFromRange:NSMakeRange(0, _attributedString.length) documentAttributes:@{NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType} error:nil];
}

#pragma mark Core Graphics rendering

-(void)renderInContext:(CGContextRef)context scale:(CGFloat)scale
{
    @synchronized(self)
    {
        if(self.hidden)
            return;
        
        UIEdgeInsets inset = [FTTextView textContainerInset:self.version];
        inset = UIEdgeInsetsScale(inset, self.transformScale);
        
        FTTextLayouter *textLayouter = [[FTTextLayouter alloc] initWithAttributedString:self.attributedString constraints:(CGSize){self.boundingRect.size.width-(inset.left+inset.right), FLT_MAX}];
        
        CGContextSaveGState(context);
        CGContextScaleCTM(context, scale, scale);
        UIColor *backgroundColor = [self backgroundColor];
        if(backgroundColor) {
            CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
            CGContextFillRect(context,self.boundingRect);
        }
        
        CGContextTranslateCTM(context, inset.left, inset.top);
        
        [textLayouter drawFlippedInContext:context bounds:(CGRect){self.boundingRect.origin,textLayouter.usedSize}];
        CGContextRestoreGState(context);
    }
}

#pragma mark OpenGL rendering

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

-(void)renderInOpenGL2Context:(EAGLContext *)context
                        scale:(CGFloat)scale
                 clippingRect:(CGRect)clipRect
        imageRenderingProgram:(GLImageRenderingProgram*)imageRenderingProgram
{

    if (self.hidden) {
        return;
    }
    @synchronized(self)
    {
        if([EAGLContext currentContext] != context)
            [EAGLContext setCurrentContext:context];
        
        if (self.currentScale != scale || self.glTexture == 0 || self.forceRender) {
            
            self.forceRender = NO;
            
            self.currentScale = scale;
            
            if (self.glTexture) {
                glDeleteTextures(1, &glTexture);
                glTexture = 0;
            }
            
            ////////////////////////////////////////////
            //Create an OpenGL Texture of the text
            
            CGRect scaledBoundingRect = CGRectScale(self.renderingRect, scale);
            scaledBoundingRect.origin = CGPointZero;
            
            int maxTextureSize;
            glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
            CGSize textureSize = [self aspectFittedRect:scaledBoundingRect.size max:CGSizeMake(maxTextureSize, maxTextureSize)];
            
            CGFloat textureScale =  textureSize.width/scaledBoundingRect.size.width;
            
            //The size of the context should be that of the cliprect
            size_t imageWidth = textureSize.width;
            size_t imageHeight = textureSize.height;
            
            // Allocate  memory needed for the bitmap context
            GLubyte *imageData = (GLubyte *) calloc(textureSize.width * textureSize.height * 4, sizeof(GLubyte));
            
            //Create the bitmap context
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef	imageContext = CGBitmapContextCreate(imageData, imageWidth, imageHeight, 8, imageWidth * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
            
            //Draw the image
            UIEdgeInsets inset = [FTTextView textContainerInset:self.version];
            inset = UIEdgeInsetsScale(inset, self.transformScale);

            FTTextLayouter *textLayouter = [[FTTextLayouter alloc] initWithAttributedString:self.attributedString constraints:(CGSize){self.renderingRect.size.width-(inset.left+inset.right), FLT_MAX}];
            
            CGContextScaleCTM(imageContext, textureScale*scale, textureScale*scale);
            
            UIColor *backgroundColor = [self backgroundColor];
            if(backgroundColor) {
                CGContextSetFillColorWithColor(imageContext, backgroundColor.CGColor);
                CGContextFillRect(imageContext, (CGRect){CGPointZero,self.renderingRect.size});
            }

            CGContextTranslateCTM(imageContext, inset.left, inset.top);
            
            [textLayouter drawFlippedInContext:imageContext bounds:(CGRect){CGPointZero,textLayouter.usedSize}];
            
            /*
             CGImageRef imageRef = CGBitmapContextCreateImage(imageContext);
             [[UIImage imageWithCGImage:imageRef] saveImageToDocumentsFolder:@"test_text.png"];
             CGImageRelease(imageRef);
             */
             //Release core graphics items
            CGContextRelease(imageContext);
            CGColorSpaceRelease(colorSpace);
            
            //Create OpenGL texture
            
            //glActiveTexture(GL_TEXTURE1);
            
            GLuint textureToReturn = 0;
            glGenTextures(1,&textureToReturn);
            glBindTexture(GL_TEXTURE_2D,textureToReturn);
            
            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); //needed for NON-POT textures
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); //needed for NON-POT textures
            
            glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,textureSize.width,textureSize.height,0,GL_RGBA,GL_UNSIGNED_BYTE,imageData);
            
            free(imageData);
            
            self.glTexture = textureToReturn;
            
            //NSLog(@"FTTextAnnotation created texture of size: %f, %f", textureSize.width, textureSize.height);
            
        }
        
        ////////////////////////////////////////////
        //Draw the texture
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
        [imageRenderingProgram use];
        
        [imageRenderingProgram setMvpMatrixForSize:clipRect.size
                                         transform:CGAffineTransformIdentity];
        
        CGRect layerBoundingRect = CGRectScale(self.renderingRect, scale);
        
        CGFloat texPixelWidth   = (1.0 / layerBoundingRect.size.width);
        CGFloat texPixelHeight  = (1.0 / layerBoundingRect.size.height);
        
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
        glBindTexture(GL_TEXTURE_2D, self.glTexture);
        glUniform1i(imageRenderingProgram.imageTexture, 0);
        
        glVertexAttribPointer(imageRenderingProgram.imagePositionSlot, 2, GL_FLOAT, 0, 0, squareVertices);
        glVertexAttribPointer(imageRenderingProgram.imageTexureCoordinates, 2, GL_FLOAT, 0, 0, textureCoordinates);
        
        glEnable(GL_SCISSOR_TEST);
        glScissor(layerBoundingRect.origin.x, layerBoundingRect.origin.y, layerBoundingRect.size.width, layerBoundingRect.size.height);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glDisable(GL_SCISSOR_TEST);
    }
}

#pragma mark Hit Test

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
            CGRect rect=intersectionRect;
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
            
            
            if(bitmapContext)
                CFRelease(bitmapContext);
            
        }
        
        return result;        
    }
}

#pragma mark Public Method

-(FTAnnotationType)annotationType
{
    return FTAnnotationTypeText;
}

-(UIColor*)backgroundColor
{
    NSRange range;
    UIColor *colorToReturn = nil;
    if(self.attributedString.length)
    {
        NSDictionary *attributes = [self.attributedString attributesAtIndex:0 effectiveRange:&range];
        if([attributes.allKeys containsObject:NSBackgroundColorAttributeName])
        {
            colorToReturn = [attributes valueForKey:NSBackgroundColorAttributeName];
        }
    }
    return colorToReturn;
}

-(void)setOffset:(CGPoint)offset
{
    if(!CGPointEqualToPoint(offset, CGPointZero))
    {
        CGRect strokeBoundingRect=self.boundingRect;
        strokeBoundingRect.origin=CGPointTranslate(strokeBoundingRect.origin, offset.x, offset.y);
        self.boundingRect=strokeBoundingRect;
        
    }
}

#pragma mark - FTTransformScale -
-(void)applyTransformScale:(CGFloat)scale
{
    if(scale == 1) {
        return;
    }
    self.transformScale = scale*self.transformScale;
    
    CGRect boundingRect = self.boundingRect;
    boundingRect.size = CGSizeScale(boundingRect.size, scale);
    self.boundingRect = boundingRect;
    
    NSMutableAttributedString *atrStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedString];
    [atrStr applyScale:scale originalScaleToApply:self.transformScale];
    self.attributedString = atrStr;
}

#pragma mark - FTTransformColorUpdate -
-(void)upodateColor:(UIColor*)color
{
    self.forceRender = true;
    NSMutableAttributedString *atrStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedString];
    [atrStr addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, atrStr.length)];
    self.attributedString = atrStr;
}

-(UIColor*)currentColor
{
    return [self.attributedString attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
}

+(NSInteger)defaultAnnotationVersion
{
    //the text container inset
    //from version 0 - 4 :: left = 20, right = 20, top = 20, bottom = 44;
    //from 5 to now :: left = 10, right = 10, top = 10, bottom = 10;
    return 5;
}

@end
