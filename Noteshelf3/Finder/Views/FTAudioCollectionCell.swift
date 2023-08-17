//
//  FTAudioCollectionCell.swift
//  Noteshelf3
//
//  Created by Sameer on 25/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon


class FTAudioCollectionCell: UICollectionViewCell {
    @IBOutlet var indexLabel: FTCustomLabel?
    @IBOutlet weak var volumeImage: UIImageView!
    @IBOutlet var audioDuration: FTCustomLabel?
    weak var delegate: FTMediaDelegate?
    var item: FTMediaItem?
    
    @IBAction func didTapMoreOption(_ sender: Any) {
        self.delegate?.didTapMoreOption(cell: self, item: self.item)
    }
    
    override var canBecomeFocused: Bool {
        return false
    }
    
    func configureCell(_ object: FTMediaItem, index: Int, delegate: FTMediaViewController) {
        self.delegate = delegate
        self.item = object
        self.indexLabel?.text = "\(index)"
        if let annotation = object.annotation as? FTAudioAnnotation {
            audioDuration?.text = FTUtils.timeFormatted(UInt(annotation.recordingModel.audioDuration()))
        }
    }
}
