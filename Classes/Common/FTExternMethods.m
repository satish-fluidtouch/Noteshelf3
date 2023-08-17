//
//  FTExternMethods.m
//  Noteshelf
//
//  Created by Simhachalam Naidu on 12/03/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTExternMethods.h"

CGRect pdfAspectFittedRect(CGRect inRect,CGRect maxRect)
{
    float originalAspectRatio = inRect.size.width / inRect.size.height;
    float maxAspectRatio = maxRect.size.width / maxRect.size.height;
    
    CGRect newRect = maxRect;
    if (originalAspectRatio > maxAspectRatio) { // scale by width
        newRect.size.height = maxRect.size.width * inRect.size.height / inRect.size.width;
        newRect.origin.y += (maxRect.size.height - newRect.size.height)/2.0;
    } else {
        newRect.size.width = maxRect.size.height  * inRect.size.width / inRect.size.height;
        newRect.origin.x += (maxRect.size.width - newRect.size.width)/2.0;
    }
//    return CGRectIntegral(newRect);
    return newRect;
}
