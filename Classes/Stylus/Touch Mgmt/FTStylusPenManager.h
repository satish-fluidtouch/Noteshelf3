//
//  FTStylusPenManager.h
//  Noteshelf
//
//  Created by Amar Udupa on 13/5/14.
//
//

#import <Foundation/Foundation.h>
#import "FTStylusPenProtocol.h"

@interface FTStylusPenManager : NSObject

+(instancetype)sharedInstance;

-(void)registerView:(UIView*)view delegate:(id<FTStylusPenDelegate>)delegate;

-(void)unregisterView:(UIView*)view setToDefault:(BOOL)setToDefault;

#pragma mark Point Process

- (void)processTouchesBegan:(NSSet *)touches event:(UIEvent*)event view:(UIView*)view;
- (void)processTouchesMoved:(NSSet *)touches event:(UIEvent*)event view:(UIView*)view;
- (void)processTouchesEnded:(NSSet *)touches event:(UIEvent*)event view:(UIView*)view;
- (void)processTouchesCancelled:(NSSet *)touches event:(UIEvent*)event view:(UIView*)view;

@end
