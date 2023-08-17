//
//  DAVResponseItem.h
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface DAVResponseItem : NSObject {
  @private
	NSString *href;
	NSDate *modificationDate;
	long long contentLength;
	NSString *contentType;
	NSDate *creationDate;
	NSDictionary *attributes;
    BOOL isCollection;
    NSString *displayName;
}

@property (copy) NSString *href;
@property (retain) NSDate *modificationDate;
@property (assign) long long contentLength;
@property (retain) NSString *contentType;
@property (retain) NSDate *creationDate;
@property (copy) NSDictionary *fileAttributes;  // like NSFileManager returns
@property (assign) BOOL isCollection;
@property (retain) NSString *displayName;

@end
