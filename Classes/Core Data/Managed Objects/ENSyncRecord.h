//
//  ENSyncRecord.h
//  Noteshelf
//
//  Created by Ashok Prabhu on 11/4/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#if !TARGET_OS_MACCATALYST
#endif
#pragma GCC diagnostic ignored "-Wproperty-attribute-mismatch"

@class ENSyncRecord;

@interface ENSyncRecord : NSManagedObject

@property (nonatomic, strong) NSString * nsGUID;
@property (nonatomic, strong) NSString * enGUID;
@property (nonatomic) BOOL isDirty;
@property (nonatomic) BOOL isContentDirty;
@property (nonatomic) BOOL deleted;
@property (nonatomic) int16_t type;
@property (nonatomic, strong) NSNumber *lastUpdated;
@property (nonatomic, strong) NSNumber *index;


@property (nonatomic) BOOL syncEnabled;
@property (nonatomic, strong) ENSyncRecord *parentRecord;
@property (nonatomic, strong) NSSet *childRecords;


@property (nonatomic) BOOL isBusinessNote;
@property (nonatomic, strong) NSString *url;
- (BOOL)isDeleted;

@end

@interface ENSyncRecord (CoreDataGeneratedAccessors)

- (void)addChildRecordsObject:(ENSyncRecord *)value;
- (void)removeChildRecordsObject:(ENSyncRecord *)value;
- (void)addChildRecords:(NSSet *)values;
- (void)removeChildRecords:(NSSet *)values;

@end
