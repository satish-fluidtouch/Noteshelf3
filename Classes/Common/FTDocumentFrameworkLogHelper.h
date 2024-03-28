//
//  FTDocumentFrameworkLogHelper.h
//  Noteshelf3
//
//  Created by Amar Udupa on 26/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
@import FTDocumentFramework;

NS_ASSUME_NONNULL_BEGIN

@interface FTDocumentFrameworkLogHelper : NSObject<FTCLSLogger>

+(void)config;

@end

NS_ASSUME_NONNULL_END
