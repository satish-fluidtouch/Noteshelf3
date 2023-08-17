//
//  FTDocumentProviderPrivate.h
//  FTDocumentSample
//
//  Created by Developer on 18/11/14.
//  Copyright (c) 2014 FluidTouch.biz. All rights reserved.
//

#ifndef FTDocumentSample_FTDocumentProviderPrivate_h
#define FTDocumentSample_FTDocumentProviderPrivate_h

@class FTDocumentGroup,FTDocument,FTDocumentProvider;

@interface FTDocumentProvider ()

@property (nonatomic,weak) Class ftDocumentClass;
@property (nonatomic,strong) NSString *documentExtension;
@property (nonatomic,weak) Class ftDocumentModelClass;

//Declerations FTDocument implements
- (NSString*)getUniqueDocumentName:(NSString *)prefix forDocument:(FTDocumentModel*)document inGroup:(FTDocumentGroup*)groupItem;
- (NSString*)getUniqueGroupNameWithName:(NSString*)prefix forGroupItem:(FTDocumentGroup*)group;
- (FTDocumentModel*)addDocumentToCache:(NSURL*)inFileURL;

- (void)removeDocumentFromCache:(NSURL*)fileURL;
- (void)removeGroupFromCache:(NSURL*)fileURL;
- (BOOL)docBelongsToGroup:(NSURL*)url;

- (NSDictionary*)moveDocument:(FTDocumentModel*)document toURL:(NSURL*)fileURL;
- (NSDictionary*)moveDocument:(FTDocumentModel*)document fromURL:(NSURL*)sourceURL toURL:(NSURL*)fileURL;

//Declerations sub-classes should implement
- (NSArray*)getRootDirectoryContents;

-(FTDocument*)newDocumentInstanceWithURL:(NSURL*)url;
@end

#endif
