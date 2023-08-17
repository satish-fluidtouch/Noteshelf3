//
//  FTRecognitionProcessor.h
//  Noteshelf
//
//  Created by Naidu on 24/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <iink/IINK.h>

@interface FTObjCMethods : NSObject
+(void)finishBulkEvents:(NSInteger)totalCount events:(NSArray*)events andEditor:(IINKEditor *)editor;
@end
