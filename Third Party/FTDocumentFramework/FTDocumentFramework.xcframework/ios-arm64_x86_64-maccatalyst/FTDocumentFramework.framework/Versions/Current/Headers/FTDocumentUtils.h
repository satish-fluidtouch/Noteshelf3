//
//  FTDocumentUtils.h
//  FTDocumentFramework
//
//  Created by Ashok Prabhu on 26/11/14.
//  Copyright (c) 2014 Fluid Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface  NSString (FTDocumentAdditions)

- (NSString *)stringByValidatingDocumentName;

@end

@interface NSURL (FTDocumentAdditions)

-(NSURL*)resolvedURL;

@end
    
@interface FTDocumentUtils : NSObject

+ (NSString*)UUIDString;
+ (NSURL*)resolvedURL:(NSURL*)fileURL;

@end


extern CGRect aspectFittedRect(CGRect inRect,CGRect maxRect);
CG_EXTERN CGAffineTransform PDFPageGetDrawingTransform(CGPDFPageRef pageRef,CGRect rect,CGPDFBox pdfBox);
