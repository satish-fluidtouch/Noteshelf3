//
//  FTShapeUtility.m
//  FTWhink
//
//  Created by Chandan on 20/1/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//

#import "FTShapeUtility.h"
#import <iostream>
#import <vector>
#import <opencv2/imgproc/imgproc.hpp>
#include <algorithm>

using namespace std;

@implementation FTShapeUtility

+(vector<cv::Point>)pointsToInputArray:(NSArray*)points
{
    __block vector<cv::Point> contours;
    contours.resize(points.count);
    
    [points enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGPoint point = [obj CGPointValue];
        cv::Point val;
        val.x = point.x;
        val.y = point.y;
        contours[idx] = val;
    }];
    return contours;
}

+(CGRect)boundingRect:(NSArray*)vertices
{
    vector<cv::Point> inputArray = [FTShapeUtility pointsToInputArray:vertices];
    cv::Rect rect = cv::boundingRect(inputArray);
    return CGRectMake(rect.x, rect.y, rect.width, rect.height);
}

@end
