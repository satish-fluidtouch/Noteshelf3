//
//  FTPDFKitFileItemPDF.h
//  FTDocumentFramework
//
//  Created by Amar on 08/01/18.
//  Copyright © 2018 Fluid Touch. All rights reserved.
//

#import "FTFileItem.h"
#import <PDFKit/PDFKit.h>

@interface FTPDFKitFileItemPDF : FTFileItem

@property (nonatomic,assign) NSUInteger pageCount;

@property (strong) NSString *documentPassword;

-(PDFDocument*)pdfDocumentRef;
-(PDFPage*)pdfPageRefAtPageNumber:(NSUInteger)pageNumber;
-(CGRect)pageRectOfPageAtNumber:(NSUInteger)pageNumber;

@end
