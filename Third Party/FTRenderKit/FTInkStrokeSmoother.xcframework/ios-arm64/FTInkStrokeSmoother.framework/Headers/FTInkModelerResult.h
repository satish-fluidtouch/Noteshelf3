//
//  FTInkModelerResult.h
//  FTInkStrokeSmoother
//
//  Created by Amar Udupa on 06/05/24.
//  Copyright © 2024 Fluid Touch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FTInkModelerResult : NSObject
{
    NSMutableArray<NSValue*> *_smoothenedPoints;
    NSMutableArray<NSValue*> *_predictedPoints;
}

@property(readonly) NSArray<NSValue*> *points;
@property(readonly) NSArray<NSValue*> *predictedPoints;

@end

NS_ASSUME_NONNULL_END
