/*
 * NSData+EvernoteSDK.m
 * evernote-sdk-ios
 *
 * Copyright 2012 Evernote Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSData+EvernoteSDK_iOS.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (EvernoteSDK)

- (NSData *) enmd5
{
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, md5Buffer);
    NSMutableData * md5Data = [NSMutableData dataWithBytes:md5Buffer length: CC_MD5_DIGEST_LENGTH];
    return md5Data;
}

- (NSString *) enlowercaseHexDigits
{
    unsigned const char * bytes = [self bytes];
    
    NSMutableString * hex = [NSMutableString stringWithCapacity: [self length] * 2];
    
    NSUInteger i;
    for (i = 0; i < [self length]; i++) {
        [hex appendFormat: @"%.2x", bytes[i]];
    }
    
    return hex;
}

+ (NSData *) endataWithHexDigits: (NSString *) hexDigits
{
    if (!hexDigits) {
        return nil;
    }
    if ([hexDigits length] % 2 != 0) {
        return nil;
    }
    
    NSMutableData * data = [NSMutableData dataWithLength: [hexDigits length] / 2];
    
    const char * sourceBytes = [hexDigits cStringUsingEncoding: NSASCIIStringEncoding];
    unsigned char * bytes = [data mutableBytes];
    
    const char * pos = sourceBytes;
    for (NSUInteger count = 0; count < [hexDigits length] / 2; count++) {
        sscanf(pos, "%2hhx", &bytes[count]);
        pos += 2;
    }
    
	return [NSData dataWithData:data];
}

@end
