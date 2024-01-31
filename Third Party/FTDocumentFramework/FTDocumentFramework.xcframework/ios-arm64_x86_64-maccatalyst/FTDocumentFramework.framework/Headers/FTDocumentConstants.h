//
//  FTDocumentConstants.h
//  FTDocumentSample
//
//  Created by Ashok Prabhu on 6/11/14.
//  Copyright (c) 2014 FluidTouch.biz. All rights reserved.
//

#ifndef FTDocumentSample_FTDocumentConstants_h
#import <Foundation/Foundation.h>

#define FTDocumentSample_FTDocumentConstants_h
#define FTICLOUD_MANAGER [FTiCloudManager sharedManager]
#define METADATA_FOLDER_NAME @"Metadata"
#define DOCUMENT_INDETIFIER_FILE_NAME @"DocumentIdentifier"
#define PROPERTIES_PLIST @"Properties.plist"
#define SECURITY_PLIST @"secure.plist"
#define ANNOTATIONS_FOLDER_NAME @"Annotations"

#define APPLICATION_VIEW_FRAME [[UIScreen mainScreen] bounds]

typedef void (^GenericSuccessBlock)(BOOL success);
extern NSString * const kFTDocumentKey;
extern NSString * const kFTDocumentURLKey;
extern NSString * const kFTDocumentNameKey;
extern NSString * const FTDocumentRenameNotification;
extern NSString * const FTPresentedDocumentDidChangeURLNotification;
extern NSString * const kFTDocumentOldURLKey;
extern NSString * const kFTDocumentNewURLKey;
extern NSString * const FTPresentedDocumentDeletedNotification;
#endif
