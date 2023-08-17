//
//  NSData+CGRectValueArray.m
//  CGRectArrayPersistance
//
//  Created by Rama Krishna on 12/06/18.
//  Copyright © 2018 Rama Krishna. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSDataValueConverter.h"

@implementation NSDataValueConverter

+(NSData*) dataWithValue:(NSValue*)value
{
    NSUInteger size;
    const char* encoding = [value objCType];
    NSGetSizeAndAlignment(encoding, &size, NULL);
    
    void* ptr = malloc(size);
    [value getValue:ptr];
    NSData* data = [NSData dataWithBytes:ptr length:size];
    free(ptr);
    
    return data;
}

+ (NSData *) dataWithRectValuesArray:(NSArray *)valuesArray{
    
    NSMutableData *data = [[NSMutableData alloc] init];
    for (NSValue * rectValue in valuesArray) {
        [data appendData:[NSDataValueConverter dataWithValue:rectValue]];
    }
    return data;
}

+ (NSArray <NSValue *>*)rectValuesArrayFromData:(NSData *)data {
    
    NSMutableArray *array = [NSMutableArray array];
    unsigned long numberOfRects = data.length / sizeof(CGRect);
    
    for (int i = 0; i < numberOfRects; i++) {
        NSRange range = NSMakeRange(i * sizeof(CGRect), sizeof(CGRect));
        NSData *rectData = [data subdataWithRange:range];
        NSValue *rectValue = [NSValue value:rectData.bytes withObjCType:@encode(CGRect)];
        [array addObject:rectValue];
    }
    return array;
}

@end
