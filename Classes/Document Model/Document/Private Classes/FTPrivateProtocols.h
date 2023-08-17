//
//  FTPrivateProtocols.h
//  Noteshelf
//
//  Created by Siva on 16/08/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

#ifndef FTPrivateProtocols_h
#define FTPrivateProtocols_h

@import UIKit;

@protocol FTDeleting <NSObject>

-(void)willDelete;

@end


@protocol FTTransformScale <NSObject>

-(void)applyTransformScale:(CGFloat)scale;

@end

@protocol FTCGContextRendering <NSObject>

-(void)renderInContext:(CGContextRef)context scale:(CGFloat)scale;

@end

#endif /* FTPrivateProtocols_h */
