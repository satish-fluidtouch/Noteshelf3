//
//  FTSpinnerView.h
//  FTWhink
//
//  Created by Chandan on 23/4/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FTSpinnerView : UIImageView

+(FTSpinnerView*)spinnerForImage:(NSString*)imageName;
-(void)startAnimation;
-(void)stopAnimation;

@end
