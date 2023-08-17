//
//  FTPDFView.m
//  Noteshelf
//
//  Created by Amar Udupa on 26/3/13.
//
//

#import "FTPDFExportView.h"

#import <QuartzCore/QuartzCore.h>
#import "Noteshelf-Swift.h"
#import <PDFKit/PDFKit.h>

extern CGRect aspectFittedRect(CGRect inRect,CGRect maxRect);

@interface FTPDFExportView()

@end

@implementation FTPDFExportView
@synthesize pdfScale = _pdfScale;
@synthesize pdfPage = _pdfPage;
@synthesize scale = _scale;
@synthesize bounds = _bounds;
- (id)initWithFrame:(CGRect)frame
           pdfScale:(CGFloat)pdfScale
            pdfPage:(id<FTPageProtocol>)inPage
              scale:(CGFloat)scale
{
    self = [super init];
    if (self) {
        // Initialization code
        _bounds = frame;
        _pdfScale = pdfScale;
        _pdfPage = inPage;
        _scale = scale;
    }
    return self;
}

-(void)drawInContext:(CGContextRef)inContext renderBackground:(BOOL)renderbackground
{
    PDFPage *pdfPage = self.pdfPage.pdfPageRef;
    CGContextRef context=inContext;
    
    // Fill the background with white.
    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
    CGContextFillRect(context, self.bounds);

    if(renderbackground) {
        int rotatedAngle = 360 - self.pdfPage.rotationAngle;
        if(rotatedAngle >= 360) {
            rotatedAngle = 360 - rotatedAngle;
        }

        CGContextSaveGState(context);
        // Flip the context so that the PDF page is rendered right side up.
        //CGContextTranslateCTM(context, 0.0, self.bounds.size.height);
        //CGContextScaleCTM(context, 1.0, -1.0);
        
        // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
        //    CGContextScaleCTM(context, self.pdfScale, self.pdfScale);
        
        NSString *version = self.pdfPage.templateInfo.version;
        CGFloat documentVersion = [version floatValue];

        CGFloat midx = self.bounds.size.width*0.5;
        CGFloat midy = self.bounds.size.height*0.5;

        CGAffineTransform translate = CGAffineTransformMakeTranslation(midx, midy);
        CGAffineTransform rotate = CGAffineTransformMakeRotation(rotatedAngle*M_PI/180);
        CGAffineTransform translateInvert;
        if(rotatedAngle == 0 || rotatedAngle == 180) {
            translateInvert = CGAffineTransformMakeTranslation(-midx, -midy);
        }
        else {
            translateInvert = CGAffineTransformMakeTranslation(-midy, -midx);
        }
        CGContextConcatCTM(context, translate);
        CGContextConcatCTM(context, rotate);
        CGContextConcatCTM(context, translateInvert);

        CGAffineTransform transform = drawingTransform(pdfPage,
                                                       self.bounds,
                                                       self.pdfScale,
                                                       kPDFDisplayBoxCropBox,
                                                       rotatedAngle,
                                                       version);
        CGContextConcatCTM(context, transform);
        
        if(documentVersion > 0) {
            NSMutableArray *annotations = [NSMutableArray array];
            pdfPage.displaysAnnotations = self.pdfPage.templateInfo.renderAnnotations;
            if (pdfPage.displaysAnnotations) {
                [pdfPage.annotations enumerateObjectsUsingBlock:^(PDFAnnotation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (
                        [obj.action isKindOfClass:[PDFActionURL class]]
                        || [obj.action isKindOfClass:[PDFActionGoTo class]]
                        ){
                        if(obj.shouldDisplay) {
                            obj.shouldDisplay = FALSE;
                            [annotations addObject:obj];
                        }
                    }
                }];
            }
            [pdfPage drawWithBox:kPDFDisplayBoxCropBox toContext:context];
            [annotations enumerateObjectsUsingBlock:^(PDFAnnotation *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.shouldDisplay = YES;
            }];
        }
        else {
            CGContextDrawPDFPage(context, pdfPage.pageRef);
        }

        CGContextRestoreGState(context);
    }
    
    NSArray *annotations = [self.pdfPage annotations];
    NSInteger totalAnnotationCount = annotations.count;

    id<FTPageProtocolPDFExport> page = (id<FTPageProtocolPDFExport>)self.pdfPage;
    NSDictionary *annotationsOrder = [page anntationsForPDFExport];
    NSArray *imageAnnotations = [annotationsOrder objectForKey:@"images"];
    NSArray *strokeAnnotations = [annotationsOrder objectForKey:@"strokes"];
    NSArray *textAnnotations = [annotationsOrder objectForKey:@"texts"];
    NSArray *shapeAnnotations = [annotationsOrder objectForKey:@"shapes"];

    CGContextSaveGState(context);

    if(totalAnnotationCount > 0) {
        //***************************
        //Image annotation rendering
        //***************************
        
        if(imageAnnotations.count) {
            UIImage *annotationsImage = [FTPDFExportView snapshotForPage:self.pdfPage
                                                  screenScale:UIScreen.mainScreen.scale
                                              withAnnotations:imageAnnotations
                                       shouldRenderBackground:false];
            CGContextDrawImage(inContext, self.bounds, annotationsImage.CGImage);
        }
        //***************************
        //End Image annotation rendering
        //***************************
        
        //Draw other strokes except text annotations
        [strokeAnnotations enumerateObjectsUsingBlock:^(FTAnnotation *obj, NSUInteger idx, BOOL *stop) {
            [(id<FTCGContextRendering>)obj renderInContext:inContext scale:self.scale];
        }];
        
        [shapeAnnotations enumerateObjectsUsingBlock:^(FTAnnotation *obj, NSUInteger idx, BOOL *stop) {
            [(id<FTCGContextRendering>)obj renderInContext:inContext scale:self.scale];
        }];
        
        
        if(textAnnotations.count)  {
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, 0.0, self.bounds.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            //Since we skipped all text annotations, its time to render them on top
            [textAnnotations enumerateObjectsUsingBlock:^(FTAnnotation *annotation, NSUInteger idx, BOOL *stop) {
                [(id<FTCGContextRendering>)annotation renderInContext:inContext scale:self.scale];
            }];
            CGContextRestoreGState(context);
        }
    }
    //Render Hidden text to enable the search on exported PDF
    [self renderRecognizedText:context];
    CGContextRestoreGState(context);
}

#pragma mark Image using StaticRenderView

+ (CGSize) aspectFittedRect:(CGSize)inSize max:(CGSize)maxSize
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
