//
//  CADisplayLink_Extension.m
//  FTWhink
//
//  Created by Amar on 25/2/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "CADisplayLink_Extension.h"
#import <objc/runtime.h>

@implementation CADisplayLink (Extension)

- (void) setFT_userInfo:(NSDictionary *) FT_userInfo
{
    objc_setAssociatedObject(self, "FT_userInfo", FT_userInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *) FT_userInfo {
    return objc_getAssociatedObject(self, "FT_userInfo");
}

@end
