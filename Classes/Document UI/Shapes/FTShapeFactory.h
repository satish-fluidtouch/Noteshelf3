//
//  ShapeDetection.h
//  FTWhink
//
//  Created by Chandan on 16/1/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol FTShape;
@interface FTShapeFactory : NSObject
{
    
}

-(nullable id<FTShape>)getShapeForPoints:(nonnull NSArray*)inPoints;
-(double)getArcLength:(nonnull NSArray*)inPoints;

@end
