//
//  FTVisualizerConstants.swift
//  NS2Watch Extension
//
//  Created by Simhachalam on 09/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//
import Foundation
import WatchKit

public let screenWidth:CGFloat = WKInterfaceDevice.current().screenBounds.size.width
public let FTRecordingButtonDidClick  = "FTRecordingButtonDidClick"
public let DID_CHANGE_WATCH_STATE  = "FTDidChangeWatchState"
public let DID_WATCH_COMPLICATION_RECEIVED  = "FTDidWatchComplicationReceived"

@objc enum FTVisualizerType: Int {
    case histogram
    case circularWave
}
@objc enum FTVisualizerPlotType: Int {
    case buffer
    case rolling
}

