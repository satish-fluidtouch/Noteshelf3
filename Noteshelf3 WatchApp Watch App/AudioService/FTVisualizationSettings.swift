//
//  FTVisualizationSettings.swift
//  Noteshelf3
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

public let FTRecordingButtonDidClick  = "FTRecordingButtonDidClick"

@objc class FTVisualizationSettings: NSObject {
    @objc var maxFrequency: Float = 7000.0
    @objc var minFrequency: Float = 400.0
    @objc var numOfBins: Int = 40
    @objc var padding: CGFloat = 0.2
    @objc var gain: CGFloat = 10
    @objc var gravity: Float = 10
    @objc var maxBinHeight: CGFloat = 100.0
    var plotType: FTVisualizerPlotType!
    var equalizerType: FTVisualizerType!
    @objc var isFillGraph = false

    class func histogramVisualizerSettings() -> FTVisualizationSettings{
        let audioSettings = FTVisualizationSettings()

        audioSettings.equalizerType = FTVisualizerType.histogram;
        audioSettings.numOfBins = 50;
        audioSettings.gravity = 3;
        audioSettings.plotType = FTVisualizerPlotType.buffer;
        audioSettings.gain = 30;
        audioSettings.padding = 0.3;

        return audioSettings
    }
    class func circularVisualizerSettings() -> FTVisualizationSettings{
        let audioSettings = FTVisualizationSettings()

        audioSettings.equalizerType = FTVisualizerType.circularWave;
        audioSettings.numOfBins = 120;
        audioSettings.gravity = 1;
        audioSettings.maxBinHeight = 30
        audioSettings.plotType = FTVisualizerPlotType.buffer;
        audioSettings.gain = 30;
        audioSettings.padding = 0.3;

        return audioSettings
    }
}

@objc enum FTVisualizerType: Int {
    case histogram
    case circularWave
}
@objc enum FTVisualizerPlotType: Int {
    case buffer
    case rolling
}
