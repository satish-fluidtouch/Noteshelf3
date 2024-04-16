//
//  FTAudioServiceProtocols.swift
//  Noteshelf3
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTAudioServiceDelegate: NSObjectProtocol {
    func audioServiceDidFinishRecording(withURL audioURL:URL)
    func audioServiceDidFinishPlaying(withError error: Error?)
}

@objc protocol FTVisualizationDataProtocol: NSObjectProtocol {
    var numberOfBins: Int {get set}
    var currentFrequencyHeights: UnsafeMutablePointer<UnsafeMutablePointer<Float>> {get set}
    var currentTimeHeights: UnsafeMutablePointer<UnsafeMutablePointer<Float>> {get set}
}

@objc protocol FTVisualizationTarget: NSObjectProtocol{
    func currentVizualizerSettings() -> FTVisualizationSettings
    func didStartProcessingData()
    func didStopProcessingData()
    func updateVisualizerWithData(_ visualizationData:FTVisualizationDataProtocol)
}
