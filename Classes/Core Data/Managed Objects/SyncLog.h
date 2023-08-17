//
//  SyncLog.h
//  Noteshelf
//
//  Created by Ashok Prabhu on 22/4/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SyncLog;

@interface SyncLog : NSManagedObject

@property (nonatomic, strong) NSNumber * date;
@property (nonatomic, strong) NSString * log;

@end
