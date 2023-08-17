//
//  FTFileItemReader.h
//  FTDocumentSample
//
//  Created by Ashok Prabhu on 30/10/14.
//  Copyright (c) 2014 FluidTouch.biz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FTFileItem;
@protocol FTFileItemSecurity;

@interface FTFileItemFactory : NSObject

@property(weak) id<FTFileItemSecurity> securityDelegate;
@property(assign,readonly) BOOL usePDFKitForPDFFileItems;

-(FTFileItem*)fileItemWithURL:(NSURL*)url canLoadSubdirectory:(BOOL)canLoadSubdirectory;

- (FTFileItem*)sqliteFileItemWithURL:(NSURL*)url;
- (FTFileItem*)imageFileItemWithURL:(NSURL*)url;
- (FTFileItem*)plistFileItemWithURL:(NSURL*)url;
- (FTFileItem*)pdfFileItemWithURL:(NSURL*)url;
- (FTFileItem*)textFileItemWithURL:(NSURL*)url;
- (FTFileItem*)audioFileItemWithURL:(NSURL*)url;

@end
