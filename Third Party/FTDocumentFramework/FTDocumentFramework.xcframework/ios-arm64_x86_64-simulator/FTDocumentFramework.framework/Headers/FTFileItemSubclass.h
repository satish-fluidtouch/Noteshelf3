//
//  FTFileItemSubclass.h
//  FTDocumentFramework
//
//  Created by Amar Udupa on 23/01/24.
//  Copyright © 2024 Fluid Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FTFileItem.h"

@interface FTFileItem (FTFileItemSubclassProtected)

-(id<NSObject>)loadContentsOfURL:(NSURL*)url;

-(id<NSObject>)performCoordinatedRead;

@end
