//
//  FTSpinnerView.m
//  FTWhink
//
//  Created by Chandan on 23/4/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTSpinnerView.h"

@implementation FTSpinnerView

+(FTSpinnerView*)spinnerForImage:(NSString*)imageName
{
    UIImage *image = [UIImage imageNamed:imageName];
    FTSpinnerView *spinner = [[FTSpinnerView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    spinner.image = image;
    return spinner;
}

-(void)startAnimation
{
    // Configure animation
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    drawAnimation.duration            = 2.0;
    drawAnimation.repeatCount         = HUGE_VAL;
    drawAnimation.toValue   = [NSNumber numberWithFloat: M_PI * 2.0];
    
    // Add the animation to the circle
    [self.layer addAnimation:drawAnimation forKey:@"FTSpinnerAnimation"];
}

-(void)stopAnimation
{
    [self.layer removeAllAnimations];
}

@end
