//
//  FTAnnotationGroup.swift
//  Noteshelf3
//
//  Created by Akshay on 19/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTAnnotationGroups<Key: Hashable, Value> {
    private var elements: [(Key, Value)] = []

    mutating func setValue(_ value: Value, forKey key: Key) {
        if let index = elements.firstIndex(where: { $0.0 == key }) {
            elements[index].1 = value // Update existing value
        } else {
            elements.append((key, value)) // Add new key-value pair
        }
    }

    func value(forKey key: Key) -> Value? {
        return elements.first(where: { $0.0 == key })?.1
    }

    mutating func removeValue(forKey key: Key) {
        if let index = elements.firstIndex(where: { $0.0 == key }) {
            elements.remove(at: index)
        }
    }

    func containsKey(_ key: Key) -> Bool {
        return elements.contains(where: { $0.0 == key })
    }

    var isEmpty: Bool {
        return elements.isEmpty
    }

    var count: Int {
        return elements.count
    }
}

extension FTAnnotationGroups where Value == Set<FTAnnotation> {
    func boundingRect(for key: Key) -> CGRect {
        let boundingRect = self.value(forKey: key)?.reduce(CGRect.null, { partialResult, annotation in
            return partialResult.union(annotation.boundingRect)
        })
        return boundingRect ?? CGRect.null
    }
}
