//
//  FTFavoritebarViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 26/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFavoritebarViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var sizeIndicator: UIButton!

    private var favorites: [FTPenSetProtocol] = []
    private let manager = FTFavoritePensetManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.favorites = manager.fetchFavorites()
    }

    @IBAction func sizeIndicatorTapped(_ sender: Any) {
    }
}
