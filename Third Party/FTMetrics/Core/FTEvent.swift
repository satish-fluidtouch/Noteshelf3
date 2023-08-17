//
//  FTEvent.swift
//  Metrics
//
//  Created by Akshay on 02/04/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTEvent: Codable {

    let id: String
    let title: String
    let type: String
    let trackers: FTEventTracker

}

struct FTEventTracker: Codable {
    let firebase: Bool
}

