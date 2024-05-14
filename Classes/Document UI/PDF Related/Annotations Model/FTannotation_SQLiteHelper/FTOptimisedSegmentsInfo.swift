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

struct FTSegmentStructOptimized {
    var startPoint: FTPointOffset;
    var thickness: Int16;
    var opacity: Int16;
    var isErased: Bool;
        
    init(segment: FTSegmentStruct,referencePoint: FTPoint,isLastSeg: Bool = false) {
        let xOffset =  isLastSeg ? (segment.endPoint.x - referencePoint.x) : (segment.startPoint.x - referencePoint.x);
        let yOffset =  isLastSeg ? (segment.endPoint.y - referencePoint.y) : (segment.startPoint.y - referencePoint.y);

        self.startPoint = FTPointOffset(x: Int16(xOffset*1000), y: Int16(yOffset*1000));
        self.thickness = Int16(segment.thickness * 100)
        self.opacity = Int16(segment.opacity * 100)
        self.isErased = segment.isErased;
    }
}

extension FTSegmentStruct {
    init(segment: FTSegmentStructOptimized,nextSegment: FTSegmentStructOptimized, referencePoint: FTPoint) {
        let pointX = referencePoint.x + (Float(segment.startPoint.x) * 0.001);
        let pointy = referencePoint.y + (Float(segment.startPoint.y) * 0.001);
        self.startPoint = FTPoint(x: pointX, y: pointy);
        
        self.thickness = Float(segment.thickness) * 0.01
        self.opacity = Float(segment.opacity)  * 0.01
        self.isErased = segment.isErased;

        let endpointX = referencePoint.x + (Float(nextSegment.startPoint.x) * 0.001);
        let endpointy = referencePoint.y + (Float(nextSegment.startPoint.y) * 0.001);
        self.endPoint = FTPoint(x: endpointX, y: endpointy);
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
