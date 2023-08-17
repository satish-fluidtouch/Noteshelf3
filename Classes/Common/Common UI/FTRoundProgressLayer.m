//
//  FTRoundProgressLayer.m
//  FTCircularProgress
//
//  Created by Rama on 24/04/18.
//  Copyright © 2018 Fluid Touch. All rights reserved.
//

#import "FTRoundProgressLayer.h"
#import <UIKit/UIKit.h>

@implementation FTRoundProgressLayer

@dynamic progress;
@dynamic radius;
@dynamic borderThickness;

+ (BOOL)needsDisplayForKey:(NSString *)key {
    return [key isEqualToString:@"progress"]
    || [key isEqualToString:@"radius"]
    || [key isEqualToString:@"borderThickness"]
    || [super needsDisplayForKey:key];
}

- (id)actionForKey:(NSString *) aKey {
    if (
        [aKey isEqualToString:@"progress"]
        || [aKey isEqualToString:@"radius"]
        || [aKey isEqualToString:@"borderThickness"]
        ) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:aKey];
        animation.fromValue = [self.presentationLayer valueForKey:aKey];
        return animation;
    }
    return [super actionForKey:aKey];
}

- (void)drawInContext:(CGContextRef)context {
    
    CGColorRef borderColor = [[UIColor whiteColor] CGColor];
    CGColorRef backgroundColor = [[[UIColor blackColor] colorWithAlphaComponent:0.4] CGColor];
    CGContextSetFillColorWithColor(context, backgroundColor);
    CGContextFillRect(context, self.bounds);
    
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat startAngle = -M_PI / 2;
    CGFloat endAngle = self.progress * 2 * M_PI + startAngle;
    CGContextSetFillColorWithColor(context, borderColor);
    
    CGContextSaveGState(context);
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, self.radius, startAngle, endAngle, 0);
    CGContextClosePath(context);
    CGContextClip(context);
    CGContextClearRect(context, self.bounds);
    CGContextRestoreGState(context);
    
    CGContextAddEllipseInRect(context,  CGRectInset(self.bounds, self.bounds.size.width/2 - self.radius, self.bounds.size.height/2 - self.radius));
    CGContextAddEllipseInRect(context,  CGRectInset(self.bounds, self.bounds.size.width/2 - self.radius + self.borderThickness, self.bounds.size.height/2 - self.radius + self.borderThickness));
    CGContextClosePath(context);
    CGContextEOClip(context);
    CGContextClearRect(context, self.bounds);
    
    [super drawInContext:context];
}

#pragma mark -
#pragma mark Public Interface

-(void)expandAndRemoveFromSuperLayer
{
    CGFloat diagonal = sqrt( self.bounds.size.width*self.bounds.size.width + self.bounds.size.height*self.bounds.size.height);
    
    if (self.progress != 1){
        self.progress = 1;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.radius = diagonal;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeFromSuperlayer];
            });
        });
        return;
    }
    
    self.radius = diagonal;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeFromSuperlayer];
    });
}

@end
