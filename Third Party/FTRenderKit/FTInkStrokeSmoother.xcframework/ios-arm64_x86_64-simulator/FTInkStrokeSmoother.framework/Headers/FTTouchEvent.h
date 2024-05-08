//
//  FTTouchEvent.h
//  FTInkStrokeSmoother
//
//  Created by Amar Udupa on 06/05/24.
//  Copyright © 2024 Fluid Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FTTouchEvent : NSObject

@property CGPoint location;
@property NSTimeInterval timestamp;
@property CGFloat pressure;

@end

NS_ASSUME_NONNULL_END
