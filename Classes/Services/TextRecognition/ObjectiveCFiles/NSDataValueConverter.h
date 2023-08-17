//
//  NSData+CGRectValueArray.h
//  CGRectArrayPersistance
//
//  Created by Rama Krishna on 12/06/18.
//  Copyright © 2018 Rama Krishna. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDataValueConverter: NSObject

+ (NSData *) dataWithRectValuesArray:(NSArray *)valuesArray;
+ (NSArray <NSValue *>*)rectValuesArrayFromData:(NSData *)data;

@property (readonly) NSArray *rectValuesArray;

@end
