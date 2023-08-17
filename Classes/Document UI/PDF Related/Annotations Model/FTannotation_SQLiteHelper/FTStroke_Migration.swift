//
//  FTStroke_Migration.swift
//  Noteshelf
//
//  Created by Akshay on 11/02/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

///This was used until `v6.1.8`, later we removed the `boundingRect` property and optimized the storage.
/// Updated the Document version to `v5`
final class FTStrokeMigrationV1
{
    private struct FTSegmentStruct_v1 {
        var startPoint : FTPoint;
        var endPoint : FTPoint;
        var thickness : Float;
        var boundingRect: FTRect;
        var opacity : Float;

        init(startPoint: FTPoint, endPoint: FTPoint, thickness: Float,  boundingRect: FTRect, opacity: Float) {
            self.startPoint = startPoint;
            self.endPoint = endPoint;
            self.thickness = thickness;
            self.boundingRect = boundingRect;
            self.opacity = opacity;
        }

        func migrated() -> FTSegmentStruct {
            return FTSegmentStruct(startPoint: self.startPoint,
                                   endPoint: self.endPoint,
                                   thickness: self.thickness,
                                   opacity: self.opacity,
                                   isErased: false)

        }
    }

    static func migrated(_ data : Data,segmentCount inSegmentCount : Int) -> Data
    {
        var localSegmentArray = [FTSegmentStruct]();
        let segments_v1 = data.toArray(type: FTSegmentStruct_v1.self, count: inSegmentCount);
        localSegmentArray = segments_v1.map { $0.migrated() }
        let data = Data(from: localSegmentArray);
        return data;
    }

}

///This was used until `v6.1.13`, later we added the `isErased` property. To maintain the erased segments in the sqlite.
/// Updated the Document version to `v6`
final class FTStrokeMigrationV2
{
    private struct FTSegmentStruct_v2 {
        var startPoint : FTPoint;
        var endPoint : FTPoint;
        var thickness : Float;
        var opacity : Float;

        init(startPoint: FTPoint, endPoint: FTPoint, thickness: Float, opacity: Float) {
            self.startPoint = startPoint;
            self.endPoint = endPoint;
            self.thickness = thickness;
            self.opacity = opacity;
        }

        func migrated() -> FTSegmentStruct {
            return FTSegmentStruct(startPoint: self.startPoint,
                                   endPoint: self.endPoint,
                                   thickness: self.thickness,
                                   opacity: self.opacity,
                                   isErased: false)

        }
    }
    
    static func migrated(_ data : Data,segmentCount inSegmentCount : Int) -> Data
    {
        var localSegmentArray = [FTSegmentStruct]();
        let segments_v2 = data.toArray(type: FTSegmentStruct_v2.self, count: inSegmentCount);
        localSegmentArray = segments_v2.map { $0.migrated() }
        let data = Data(from: localSegmentArray);
        return data;
    }

}

extension Data {
    init<T>(from array: [T]) {
        self.init(bytes: array, count: MemoryLayout<T>.stride*array.count)
    }

    func toArray<T>(type: T.Type,count: Int) -> [T] {
        return self.withUnsafeBytes { pointer in
            [T](UnsafeBufferPointer(start: pointer, count: count))
        }
    }
}
