//
//  FTFileItemSqlite.h
//  FTDocumentFramework
//
//  Created by Ashok Prabhu on 24/11/14.
//  Copyright (c) 2014 Fluid Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTFileItem.h"
#import "FMDB.h"

@interface FTFileItemSqlite : FTFileItem
@property (nonatomic, strong,readonly) FMDatabaseQueue *databaseQueue;


#pragma mark Subclasses should override
- (BOOL)createSchema;
- (BOOL)saveDatabaseChanges;

- (void)resetDatabase;

@end
