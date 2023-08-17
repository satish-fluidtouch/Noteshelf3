//
//  FTBackUpAccountInfo.m
//  Noteshelf
//
//  Created by Amar on 30/3/16.
//
//

#import "FTBackUpAccountInfo.h"

@implementation FTBackUpAccountInfo

-(CGFloat)percentageUsed
{
    CGFloat percentage = 0.0f;
    CGFloat totalValue = self.totalBytes;
    CGFloat consumerValue = self.consumedBytes;
    
    if (totalValue > 0)
    {
        percentage = (consumerValue/totalValue)*100;
    }
    return percentage;
}

@end
