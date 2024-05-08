//
//  FTInkModelerHelper.h
//  FTInkStrokeSmoother
//
//  Created by Amar Udupa on 06/05/24.
//  Copyright © 2024 Fluid Touch. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FTInkModelerResult,FTTouchEvent;

NS_ASSUME_NONNULL_BEGIN

@interface FTInkModelerHelper : NSObject

-(FTInkModelerResult *)processTouchBegan:(FTTouchEvent *)touch;
-(FTInkModelerResult *)processTouchMoved:(FTTouchEvent *)touch;
-(FTInkModelerResult *)processTouchEnded:(FTTouchEvent *)touch;

@end

NS_ASSUME_NONNULL_END
