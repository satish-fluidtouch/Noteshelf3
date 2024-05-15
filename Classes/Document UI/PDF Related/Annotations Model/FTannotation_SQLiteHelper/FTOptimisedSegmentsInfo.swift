//
//  FTOptimisedSegmentsInfo.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 14/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

struct FTPointOffset {
    var x,y : Int16;
}

private extension Float {
    static let precisionVal: Float = 1000;
    static let onebyPrecisionVal: Float = 1/Float.precisionVal;

    var toInt16: Int16 {
        if fabsf(self*Float.precisionVal) > Float(Int16.max) {
            FTLogError("Stroke Float to int failed", attributes: ["value": self])
        }
        return Int16(max(min(self*Float.precisionVal,Float(Int16.max)), Float(Int16.min)))
    }
}
struct FTSegmentStructOptimized {
    var startPoint: FTPointOffset;
    var thickness: Int16;
    var opacity: Int16;
    var isErased: Bool;
        
    init(segment: FTSegmentStruct,referencePoint: FTPoint,isLastSeg: Bool = false) {
        let xOffset =  isLastSeg ? (segment.endPoint.x - referencePoint.x) : (segment.startPoint.x - referencePoint.x);
        let yOffset =  isLastSeg ? (segment.endPoint.y - referencePoint.y) : (segment.startPoint.y - referencePoint.y);

//        self.startPoint = isLastSeg ? segment.startPoint : segment.endPoint
        self.startPoint = FTPointOffset(x: xOffset.toInt16, y: yOffset.toInt16);
        self.thickness = segment.thickness.toInt16
        self.opacity = segment.opacity.toInt16
        self.isErased = segment.isErased;
    }
}

extension FTSegmentStruct {
    init(segment: FTSegmentStructOptimized,nextSegment: FTSegmentStructOptimized, referencePoint: FTPoint) {
        let presValue = Float.onebyPrecisionVal;
        let pointX = referencePoint.x + (Float(segment.startPoint.x) * presValue);
        let pointy = referencePoint.y + (Float(segment.startPoint.y) * presValue);
        self.startPoint = FTPoint(x: pointX, y: pointy);
//        self.startPoint = segment.startPoint;

        self.thickness = Float(segment.thickness) * presValue
        self.opacity = Float(segment.opacity)  * presValue
        self.isErased = segment.isErased;

        let endpointX = referencePoint.x + (Float(nextSegment.startPoint.x) * presValue);
        let endpointy = referencePoint.y + (Float(nextSegment.startPoint.y) * presValue);
        self.endPoint = FTPoint(x: endpointX, y: endpointy);
//        self.endPoint = nextSegment.startPoint
    }
}

extension FTStroke {
    func setOptimizedSegmentsData(_ data: Data,inSegmentCount: Int) {
        let segments = data.toArray(type: FTSegmentStructOptimized.self, count: inSegmentCount);
        self.optimizedSegmentArray = segments;
        segmentCount = inSegmentCount - 1;
        self.segmentsTransientArray = Array(repeating: FTSegmentTransient(), count: inSegmentCount);
    }
    
    func optimizedSegmentsData() -> Data {
        guard let _refPoint = self.referencePoint else {
            return self.segmentData();
        }
        
        var segments = [FTSegmentStructOptimized]();
        self.segmentArray.enumerated().forEach { eachItem in
            if eachItem.offset == 0 {
                let segment = FTSegmentStructOptimized(segment: eachItem.element, referencePoint: _refPoint);
                segments.append(segment);
            }
            else {
                let prevSegment = self.segmentArray[eachItem.offset - 1];
                let segment = FTSegmentStructOptimized(segment: eachItem.element, referencePoint: prevSegment.startPoint);
                segments.append(segment);
                if eachItem.offset == self.segmentArray.count {
                    let segment = FTSegmentStructOptimized(segment: eachItem.element, referencePoint: eachItem.element.startPoint,isLastSeg: true);
                    segments.append(segment);
                }
            }
        }
        let data = Data(from: segments);
        return data;
    }
}
