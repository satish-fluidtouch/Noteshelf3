//
//  NSStringAdditions.m
//  Noteshelf
//
//  Created by Rama Krishna on 10/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSStringAdditions.h"

@implementation NSString (NSStringAdditions)

- (NSString *)stringByTrimmingTrailingCharactersInSet:(NSCharacterSet *)characterSet {
    NSUInteger location = 0;
    NSUInteger length = [self length];
    unichar charBuffer[length];
    [self getCharacters:charBuffer];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    for (length; length > 0; length--) {
        if (![characterSet characterIsMember:charBuffer[length - 1]]) {
            break;
        }
    }
#pragma clang diagnostic pop
    
    return [self substringWithRange:NSMakeRange(location, length - location)];
}

@end
