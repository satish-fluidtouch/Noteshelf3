//
//  FTPDFView.h
//  Noteshelf
//
//  Created by Amar Udupa on 26/3/13.
//
//

#import <UIKit/UIKit.h>
@import FTRenderKit;

@protocol FTPageProtocol;

@interface FTPDFExportView : NSObject

@property (weak) id<FTPageProtocol> pdfPage;
@property (assign) CGFloat pdfScale;
@property (assign) CGFloat scale;
@property (assign) CGRect bounds;

- (id)initWithFrame:(CGRect)frame
           pdfScale:(CGFloat)pdfScale
            pdfPage:(id<FTPageProtocol>)inPage
              scale:(CGFloat)scale;

-(void)drawInContext:(CGContextRef)inContext renderBackground:(BOOL)renderbackground;

@end
