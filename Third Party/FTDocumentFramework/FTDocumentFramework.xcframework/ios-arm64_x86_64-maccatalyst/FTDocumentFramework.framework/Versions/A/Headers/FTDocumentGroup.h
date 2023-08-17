//
//  FTDocumentGroup.h
//  FTDocumentSample
//
//  Created by Ashok Prabhu on 14/11/14.
//  Copyright (c) 2014 FluidTouch.biz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTDocumentModel.h"

@interface FTDocumentGroup : NSObject

@property (nonatomic,strong) NSURL *fileURL;

@property (nonatomic,strong) NSMutableArray *children;

- (NSString*)filePath;

- (instancetype)initWithFileURL:(NSURL*)url;
- (void)removeDocumentWithURL:(NSURL*)url;
- (void)addDocument:(FTDocumentModel*)document;
- (void)removeDocument:(FTDocumentModel*)document;

- (void)validateChildren;
- (FTDocumentModel*)childDocumentWithURL:(NSURL*)fileURL;
- (NSString*)groupName;
- (NSArray*)allDocuments;
- (NSDate*)urlModificationDate;
- (NSDate*)urlCreationDate;
- (NSString *)documentUrlHash;

-(void)getKeys:(void (^)(NSArray* keys))completion;

@end
