//
//  FTRoundProgressLayer.h
//  FTCircularProgress
//
//  Created by Rama on 24/04/18.
//  Copyright © 2018 Fluid Touch. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface FTRoundProgressLayer : CALayer

@property (nonatomic) CGFloat progress;
@property (nonatomic) CGFloat radius;
@property (nonatomic) CGFloat borderThickness;

-(void)expandAndRemoveFromSuperLayer;

@end
