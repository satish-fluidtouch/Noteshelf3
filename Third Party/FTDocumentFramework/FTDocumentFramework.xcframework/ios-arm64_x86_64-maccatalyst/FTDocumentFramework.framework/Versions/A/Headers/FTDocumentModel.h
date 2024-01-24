//
//  FTDocumentModel.h
//  FTDocumentFramework
//
//  Created by Chandan on 11/1/16.
//  Copyright © 2016 Fluid Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FTDocumentFramework/FTDocument.h>

@interface FTDocumentModel : NSObject

@property (nonatomic,strong) NSURL *fileURL;
@property (readonly) NSString *filePath;
@property (readonly) NSString *documentName;
@property (nonatomic,readonly,weak)FTDocument *document;

- (FTDocument*)createNewDocument:(Class)documentClass;
- (instancetype)initWithFileURL:(NSURL *)url;
- (NSDate*)urlModificationDate;
- (NSDate*)urlCreationDate;

/**
 A convenience method that will set the iCloud status flags of the `FTDocument` from an `NSMetadataItem` corresponding to that document package. Use this in  conjunction with a meta data query.
 
 @param metadataItem The `NSMetadataItem` corresponding to that document package.
 */
-(void)updateWithMetadataItem:(NSMetadataItem*)metadataItem;
-(void)getUniqueID:(void (^)(NSString *uniqueID))completion;
-(void)getKeys:(void (^)(NSArray* keys))completion;

///---------------------------------------
/// @name Document iCloud status flags
///---------------------------------------

/**
 Indicates that the document has finished downloading contents from the iCloud server and is up-to-date.
 */
@property (readonly) BOOL isDownloaded;

/**
 Indicates that the document content is being downloaded from the iCloud server.
 */
@property (readonly) BOOL isDownloading;

/**
 Indicates that the document has finished Uploading contents to the iCloud server.
 */
@property (readonly) BOOL isUploaded;

/**
 Indicates that the document content is being uploaded to the iCloud server.
 */
@property (readonly) BOOL isUploading;

/**
 Indicates that % downloaded when a document is being downloaded from the iCloud server.
 */
@property (readonly) CGFloat percentDownloaded;

/**
 Indicates that % uploaded when a document is being uploaded to the iCloud server.
 */
@property (readonly) CGFloat percentUploaded;

@end
