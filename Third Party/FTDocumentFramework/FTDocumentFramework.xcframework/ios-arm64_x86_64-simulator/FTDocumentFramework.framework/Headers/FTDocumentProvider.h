//
//  FTDocumentProvider.h
//  FTDocumentSample
//
//  Created by Ashok Prabhu on 5/11/14.
//  Copyright (c) 2014 FluidTouch.biz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTDocumentGroup.h"

@class FTDocument;
typedef void(^documentWithErrorBlock)(FTDocumentModel *document,NSError*error) ;
@protocol FTDocumentProviderDelegate

- (void)documentsDidGetAdded:(NSArray*)filePaths;
- (void)documentsDidGetDeleted:(NSArray*)filePaths;
- (void)documentsDidGetUpdated:(NSArray*)filePaths;

@end

@interface FTDocumentProvider : NSObject

@property (nonatomic,weak) id<FTDocumentProviderDelegate>delegate;
@property (nonatomic,readonly) NSURL *rootDocumentsDirectoryURL;
@property (atomic,strong) NSMutableArray *documentItems;
@property (nonatomic,strong) NSString *rootDocumentDirectoryName;

- (void)createDocumentWithName:(NSString*)name inGroup:(FTDocumentGroup*)group
             completionHandler:(documentWithErrorBlock) completionBlock;

- (void)createDocumentWithName:(NSString*)name
                       inGroup:(FTDocumentGroup*)group
                 withSourceURL:(NSURL*)sourceURL
             completionHandler:(documentWithErrorBlock)completionBlock;

- (void)createDocumentWithName:(NSString*)name
                       inGroup:(FTDocumentGroup*)group
               withTemplateURL:(NSURL*)templateURL
             completionHandler:(documentWithErrorBlock)completionBlock;


- (void)renameDocument:(FTDocumentModel*)document
                toName:(NSString*)newName
     completionHandler:(documentWithErrorBlock)completionBlock;
- (void)deleteDocument:(NSURL*)fileURL completionHandler:(void(^)(NSError*error))completionBlock;
;

- (FTDocumentGroup*)groupItemForDocument:(NSURL*)fileURL;
- (FTDocumentGroup*)groupItemForURL:(NSURL*)fileURL;
- (FTDocumentGroup*)groupItemWithName:(NSString*)groupName;

- (FTDocumentModel*)documentWithFileURL:(NSURL*)fileURL;
- (FTDocumentModel*)documentWithName:(NSString*)docName;

- (BOOL)docWithNameExists:(NSString *)docName inGroupItem:(FTDocumentGroup*)groupItem;

//Declerations sub-classes should implement
- (void)fetchDocuments:(void(^)(BOOL success))completionBlock;
- (void)clearDocuments;
- (NSURL *)getUniqueURLWithName:(NSString *)filename forDocument:(FTDocumentModel*)document inGroup:(FTDocumentGroup*)groupItem;
- (void)removeDocumentAtURL:(NSURL*)docURL completionHandler:(void(^)(NSError*error))completionBlock;

- (void)groupDocuments:(NSArray*)documents
              withName:(NSString*)groupName
     completionHandler:(void(^)(FTDocumentGroup *group,NSError*error))completionBlock;

- (void)renameGroupItem:(FTDocumentGroup*)groupItem
                 toName:(NSString*)name
      completionHandler:(void(^)(FTDocumentGroup *group,NSError*error))completionBlock;

- (void)moveDocument:(FTDocumentModel*)docItem
             toGroup:(FTDocumentGroup*)groupItem
   completionHandler:(documentWithErrorBlock)completionBlock;

- (void)createCopyOfDocument:(FTDocumentModel*)docItem withCompletionHandler:(void(^)(FTDocumentModel *document))completionBlock;;

- (BOOL)isDocumentDownloaded:(NSURL*)fileURL;

-(void)enableUpdates;
-(void)disableUpdates;
@end