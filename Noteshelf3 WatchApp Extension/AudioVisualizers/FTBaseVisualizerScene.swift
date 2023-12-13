//
//  FTVisualizerProtocol.swift
//  NS2Watch Extension
//
//  Created by Simhachalam on 09/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SpriteKit

@objc class FTBaseVisualizerScene: SKScene, FTVisualizationTarget {
    
    var visualizerType:FTVisualizerType!
    internal var visualizerSettings: FTVisualizationSettings!
    
    func currentVizualizerSettings() -> FTVisualizationSettings {
        //override in subclass
        return FTVisualizationSettings.histogramVisualizerSettings()
    }
    func didStartProcessingData() {
        
    }
    func didPauseProcessingData() {
        
    }
    func didStopProcessingData() {
        
    }
    
    func updateVisualizerWithData(_ visualizationData: FTVisualizationDataProtocol) {
        
    }
}

//Related Protocols
@objc protocol FTVisualizationDataProtocol: NSObjectProtocol{
    var numberOfBins:Int{get set}
    var currentFrequencyHeights: UnsafeMutablePointer<UnsafeMutablePointer<Float>>{get set}
    var currentTimeHeights:UnsafeMutablePointer<UnsafeMutablePointer<Float>>{get set}
}

@objc protocol FTVisualizationTarget: NSObjectProtocol{
    func currentVizualizerSettings() -> FTVisualizationSettings
    func didStartProcessingData()
    func didStopProcessingData()
    func updateVisualizerWithData(_ visualizationData:FTVisualizationDataProtocol)
}

