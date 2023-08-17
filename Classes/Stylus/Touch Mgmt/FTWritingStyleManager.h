//
//  FTWritingStyleManager.h
//  Noteshelf
//
//  Created by Amar Udupa on 9/5/14.
//
//

#import <Foundation/Foundation.h>

@interface FTWritingStyleManager : NSObject

//returns the new reference point which needs to be considered for making decision to find whether the new point is above the line or below the line.
+(CGPoint)newReferencePoint:(CGPoint)currentRefPoint
                   newPoint:(CGPoint)newPoint
               forLandscape:(BOOL)isLandscape
                 isInverted:(BOOL)isInverted;

//returns a bool varibale to decide whether the current stroke needs to be cancelled or not.
//This method makes use of currently selected writing style while making the decision.
+(BOOL)isPointAboveLineForRefPoint:(CGPoint)refPoint
                      currentPoint:(CGPoint)curPoint
                      forLandscape:(BOOL)isLandscape
                        isInverted:(BOOL)isInverted;


/*
 Never used
+(CGFloat)parallelDistanceFromPoint:(CGPoint)point1
                            toPoint:(CGPoint)point2
                       forLandscape:(BOOL)isLandscape;
*/
@end
