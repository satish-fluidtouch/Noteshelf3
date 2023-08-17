//
//  CADisplayLink_Extension.h
//  FTWhink
//
//  Created by Amar on 25/2/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

CG_INLINE CGPoint
CGPointAdd(CGPoint point1, CGPoint point2)
{
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}

@interface CADisplayLink (Extension)

@property (nonatomic, copy) NSDictionary *FT_userInfo;

@end