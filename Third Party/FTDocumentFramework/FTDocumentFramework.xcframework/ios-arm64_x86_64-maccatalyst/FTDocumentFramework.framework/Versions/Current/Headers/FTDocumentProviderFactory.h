//
//  FTDocumentProviderFactory.h
//  FTDocumentFramework
//
//  Created by Ashok Prabhu on 26/11/14.
//  Copyright (c) 2014 Fluid Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTDocumentProvider.h"

@interface FTDocumentProviderFactory : NSObject

+ (void)documentProviderWithCompletionHandler:(void (^)(FTDocumentProvider* provider))completionBlock;
+ (FTDocumentProvider*)iCloudDocumentProvider;
+ (FTDocumentProvider*)fileSystemDocumentProvider;

+ (Class)fileSystemDocumentProviderClass;
+ (Class)iCloudDocumentProviderClass;

+ (Class)documentClass;
+ (NSString*)rootDocumentDirectoryName;
+ (NSString*)documentExtension;

@end
