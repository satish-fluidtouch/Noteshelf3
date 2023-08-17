//
//  FTExportItem.h
//  Noteshelf
//
//  Created by Amar Udupa on 2/4/13.
//
//

#import <Foundation/Foundation.h>

@interface FTExportItem : NSObject

@property (strong) NSString *exportFileName;
@property (strong) id representedObject;
@property (strong) NSString *fileName;
@property (strong) NSMutableSet *tags;
@property (nonatomic) BOOL isGroupItem;
@property (strong) NSArray <FTExportItem*> *childItems;
@end
