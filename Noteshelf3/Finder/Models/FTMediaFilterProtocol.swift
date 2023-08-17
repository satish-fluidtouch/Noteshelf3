//
//  FTMediaFilterProtocol.swift
//  Noteshelf3
//
//  Created by Sameer on 02/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTMediaProtocol {
    var name: String { get }
    var imageName: String { get }
    var type: FTMediaType { get }
}

class FTAllMedia: FTMediaProtocol {
    var name: String {
        return "All Content"
    }
    var imageName: String {
        return "square.grid.2x2"
    }
    var type: FTMediaType {
        return .allMedia
    }
}

class FTImageMedia: FTMediaProtocol {
    var name: String {
        return "Photos"
    }
    var imageName: String {
        return "photo"
    }
    var type: FTMediaType {
        return .photo
    }
}


class FTAudioMedia: FTMediaProtocol {
    var name: String {
        return "Audio"
    }
    var imageName: String {
        return "mic"
    }
    var type: FTMediaType {
        return .audio
    }
}
