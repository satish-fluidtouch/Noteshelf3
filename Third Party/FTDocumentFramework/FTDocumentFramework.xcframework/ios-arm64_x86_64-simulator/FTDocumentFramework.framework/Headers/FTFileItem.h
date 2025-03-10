//
//  FTFileItem.h
//  FTDocumentSample
//
//  Created by Ashok Prabhu on 30/10/14.
//  Copyright (c) 2014 FluidTouch.biz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@protocol FTFileItemSecurity <NSObject>
-(BOOL)shouldSecure;
-(BOOL)isSecured;
-(NSData *)encrypt:(NSData *)data;
-(NSData *)decrypt:(NSData *)data;
-(BOOL)shouldIgnoreFromEncryption:(NSURL*)fileItemURL;
@end

@interface FTFileItem : NSObject

@property (nonatomic,strong) NSURL *fileItemURL; //Full URL to the file
@property (nonatomic,strong) NSString *fileName;
@property (nonatomic,weak) FTFileItem *parent;
@property (strong) NSMutableSet *children;
@property (readonly, nonatomic) BOOL isDirectory;
@property (readonly, nonatomic) BOOL isModified;
@property (nonatomic,strong) id<NSObject> content;
@property (weak) id<FTFileItemSecurity> securityDelegate;
@property (assign) BOOL forceSave;

- (id<NSObject>)content;

- (instancetype)initWithURL:(NSURL*)url isDirectory:(BOOL)isDir;
- (instancetype)initWithFileName:(NSString*)fileName;
- (instancetype)initWithFileName:(NSString*)fileName isDirectory:(BOOL)isDir;

- (NSData *)data;
- (NSString *)string;
- (NSDictionary *)dictionary;
- (UIImage *)image;

- (void)updateContent:(id<NSObject>)content;
- (void)deleteContent;
- (BOOL)writeUpdatesToURL:(NSURL *)url error:(NSError *__autoreleasing *)outError;

- (void)addChildItem:(FTFileItem*)childItem;
- (FTFileItem*)childFileItemWithName:(NSString*)filename;

- (BOOL)saveContentsOfFileItem;
- (id)loadContentsOfFileItem;
- (void)documentDidMoveToURL:(NSURL*)url;

- (void)unloadContentsOfFileItem;

//Encrypt/decrypt
- (BOOL)shouldEncryptWhileSaving;
- (BOOL)shouldDecryptWhileLoading;
-(BOOL)shouldBeIgnored;

@end
