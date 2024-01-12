//
//  ShapeDetection.m
//  FTWhink
//
//  Created by Chandan on 16/1/15.
//  Copyright (c) 2015 Fluid Touch Pte Ltd. All rights reserved.
//
#import <iostream>
#import "FTShapeFactory.h"
#import <vector>
#import <opencv2/imgproc/imgproc.hpp>
#include <algorithm>
#include "FTShapeUtility.h"
#import "Noteshelf-Swift.h"

using namespace std;
using namespace cv;

@implementation FTShapeFactory
-(std::vector<cv::Point>)getCircleAproximation:(vector<cv::Point>)contours
{
    std::vector<cv::Point> approx;
    CGFloat epsilon = cv::arcLength(cv::Mat(contours),true) * (2.0f/100.0f);
    approxPolyDP(contours,approx,epsilon,false);
    return approx;
}

-(vector<cv::Point>)pointsToInputArray:(NSArray*)points
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

-(FTShapeEllipse*)isCircle:(vector<cv::Point>)contours
{
    FTShapeEllipse *outEllipse= nil;
    
    FTShapeEllipse *tEllipse = [self getEllipseForPoints:contours];
    NSArray *points = [tEllipse drawingPointsWithScale: 1.0];
    vector<cv::Point> ellipseContour = [self pointsToInputArray:points];
    if(ellipseContour.size() > 0 && contours.size() > 0){
        double match = matchShapes(ellipseContour,contours,CHAIN_APPROX_NONE, 0);
        if(match >= 0 && match < 0.2){
            //Perfect match if match is closer to 0
            outEllipse = tEllipse;
        }
    }
    
    return outEllipse;
}

-(FTShapeEllipse*)getEllipseForPoints:(vector<cv::Point>)contours
{
    cv::Point2f inCenter;
    std::vector<float>radius(contours.size() );
    cv::RotatedRect rect = cv::minAreaRect(contours);
    
    FTShapeEllipse *ellipse = [[FTShapeEllipse alloc] init];
    ellipse.center = CGPointMake(rect.center.x,rect.center.y);
    ellipse.boundingRectSize = CGSizeMake(rect.size.width, rect.size.height);
    ellipse.rotatedAngle = rect.angle;
    return ellipse;
}

-(nullable id<FTShape>)getShapeForPoints:(nonnull NSArray*)inPoints
{
    id<FTShape> shape = nil;
    if (inPoints.count > 0) {
        vector<cv::Point> contours = [self pointsToInputArray:inPoints];
        std::vector<std::vector<cv::Point> > newContours;
        vector<cv::Vec4i> hierarchy;
        std::vector<cv::Point> approx;
        
        FTShapeEllipse *ellipse = [self isCircle:contours];
        approx = [self getCircleAproximation:contours];
        if(approx.size() > 7 && ellipse){
            shape = ellipse;
        }
        else
        {
            approxPolyDP(contours,approx,cv::arcLength(cv::Mat(contours),true) * (2.0f/100.0f),false);
            if(approx.size() <= 8){
                //Filter again - it will remove unneccessary points
                approxPolyDP(contours,approx,cv::arcLength(cv::Mat(contours),true) * (4.0f/100.0f),false);
            }
            else{
                approxPolyDP(contours,approx,cv::arcLength(cv::Mat(contours),true) * (1.0f/100.0f),false);
            }
            
            if(approx.size() == 2){
                CGPoint startPoint = CGPointMake(approx[0].x, approx[0].y);
                CGPoint endPoint = CGPointMake(approx[1].x, approx[1].y);
                FTShapeLine *line = [[FTShapeLine alloc] initWithPoint:startPoint end:endPoint];
                shape = line;
            }
            else{
                FTShapeCurve *curve = [[FTShapeCurve alloc] initWithPoints:inPoints];
                NSValue *first = [NSValue valueWithCGPoint:CGPointMake(approx[0].x, approx[0].y)];
                NSValue *last = [NSValue valueWithCGPoint:CGPointMake(approx[approx.size()-1].x, approx[approx.size()-1].y)];
                vector<cv::Point> contours = [self pointsToInputArray:@[first, last]];
                double distance = cv::arcLength(cv::Mat(contours),false);
                if (curve != nil) {
                    shape = curve;
                } else if(distance > 5) {
                    FTShapeLineStrip *lineStrip = [[FTShapeLineStrip alloc] init];
                    NSMutableArray *vertices = [NSMutableArray array];
                    for (int i = 0 ; i < approx.size() ; i++) {
                        [vertices addObject:[NSValue valueWithCGPoint:CGPointMake(approx[i].x, approx[i].y)]];
                    }
                    objc_sync_enter(lineStrip);
                    lineStrip.vertices = vertices;
                    lineStrip.isClosedShape = NO;
                    shape = lineStrip;
                    objc_sync_exit(lineStrip);
                } else {
                    FTShapePolygon *polygonShape = nil;
                    NSMutableArray *vertices = [NSMutableArray array];
                    for (int i = 0 ; i < approx.size() ; i++) {
                        [vertices addObject:[NSValue valueWithCGPoint:CGPointMake(approx[i].x, approx[i].y)]];
                    }
                    if(approx.size() == 4){ //One 3+1 last point is user lift the finger up
                        polygonShape = [[FTShapePolygon alloc] init];
                    }
                    else if(approx.size() == 5){
                        polygonShape = [[FTShapeRectangle alloc] initWithPoints:vertices];
                        if (polygonShape == nil) {
                            polygonShape = [[FTShapePolygon alloc] init];
                        }
                    }
                    else{
                        shape = [[FTShapeCurve alloc] initWithPoints:inPoints];
                        if (shape != nil) {
                            return shape;
                        }
                        polygonShape = [[FTShapePolygon alloc] init];
                    }
                    objc_sync_enter(polygonShape);
                    polygonShape.vertices = vertices;
                    objc_sync_exit(polygonShape);
                    shape = polygonShape;
                }
            }
        }
    }
    return shape;
}

-(double)getArcLength:(nonnull NSArray*)inPoints
{
    vector<cv::Point> contours = [self pointsToInputArray:inPoints];
    return cv::arcLength(cv::Mat(contours),false);
}

/*
-(BOOL)isCurve:(NSArray*)inPoints
{
    BOOL isCurve = NO;
    if (inPoints.count > 0) {
        vector<cv::Point> contours = [self pointsToInputArray:inPoints];
        std::vector<cv::Point> approx;
        CGFloat epsilon = cv::arcLength(cv::Mat(contours),true) * (4.0f/100.0f);
        approxPolyDP(contours,approx,epsilon,false);
        if(approx.size() > 3){
            isCurve = YES;
        }
    }
    return isCurve;
}
*/
@end
