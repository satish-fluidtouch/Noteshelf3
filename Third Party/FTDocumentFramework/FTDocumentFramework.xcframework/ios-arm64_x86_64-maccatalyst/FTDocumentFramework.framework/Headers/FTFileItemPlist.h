//
//  FTFileItemPlist.h
//  FTDocumentFramework
//
//  Created by Ashok Prabhu on 26/11/14.
//  Copyright (c) 2014 Fluid Touch. All rights reserved.
//

#import <FTDocumentFramework/FTFileItem.h>

@interface FTFileItemPlist : FTFileItem

@property (nonatomic, readonly) NSDictionary* contentDictionary;

- (void)setObject:(id)obj forKey:(NSString*)aKey;
- (id)objectForKey:(NSString*)aKey;

@end
