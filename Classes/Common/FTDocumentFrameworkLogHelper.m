//
//  FTDocumentFrameworkLogHelper.m
//  Noteshelf3
//
//  Created by Amar Udupa on 26/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTDocumentFrameworkLogHelper.h"

@implementation FTDocumentFrameworkLogHelper

+ (void)config {
    clsLoggerClass = FTDocumentFrameworkLogHelper.class;
}

+ (void)logEvent:(NSString *)event {
    FTCLSLog(event);
}

+ (void)logEroor:(NSString *)error attributes:(NSDictionary *)attributes { 
    FTLogError(error, attributes);
}

@end
