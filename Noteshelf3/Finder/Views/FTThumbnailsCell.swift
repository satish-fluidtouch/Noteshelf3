//
//  FTThumbnailsCell.swift
//  Noteshelf3
//
//  Created by Sameer on 07/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTThumbnailsCell: UITableViewCell, UICollectionViewDelegate {
    @IBOutlet var collectionView: UICollectionView?
    
    override func awakeFromNib() {
       collectionView?.delegate = self
    }
    
//    func configureCell(with document: FTThumNco) {
//        
//    }
}
