//
//  FTFileItemPDF.h
//  FTDocumentFramework
//
//  Created by Ashok Prabhu on 10/12/14.
//  Copyright (c) 2014 Fluid Touch. All rights reserved.
//

#import "FTFileItem.h"

@interface FTFileItemPDF : FTFileItem

@property (nonatomic,assign) NSUInteger pageCount;

@property (strong) NSString *documentPassword;

-(CGPDFDocumentRef)pdfDocumentRef;
-(CGPDFPageRef)pdfPageRefAtPageNumber:(NSUInteger)pageNumber;
-(CGRect)pageRectOfPageAtNumber:(NSUInteger)pageNumber;

@end
