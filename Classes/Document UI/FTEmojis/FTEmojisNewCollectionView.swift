////
////  FTEmojisNewCollectionView.swift
////  Noteshelf
////
////  Created by srinivas on 10/09/22.
////  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
////
//
//import Foundation
//import Combine
//
//class FTEmojisNewCollectionView: UICollectionView {
//
//    private static let cellIdentifier = "emojicell"
//    let viewModel: FTEmojisViewModel
//    var subscriptions = Set<AnyCancellable>()
//
//    override init(viewModel: FTEmojisViewModel) {
//        //frame: CGRect, collectionViewLayout layout: UICollectionViewLayout
//        self.viewModel = viewModel
//       commonInit()
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        commonInit()
//    }
//
//    private func commonInit() {
//        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
////        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
////        layout.sectionInset = .zero
//        layout.minimumInteritemSpacing = 16
//        layout.minimumLineSpacing = 16
//        layout.itemSize = CGSize(width: 32, height: 32)
//        layout.scrollDirection = .vertical
//        super.init(frame: .zero, collectionViewLayout: layout)
//        dataSource = self
//        register(FTEmojiCollectionViewCell1.self, forCellWithReuseIdentifier: cellId)
//
//        viewModel.emojis.sink { [weak self] emojis in
//            self?.reloadData()
//        }.store(in: &subscriptions)
//    }
//
//
//}
//
//extension FTEmojisNewCollectionView: UICollectionViewDataSource {
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        viewModel.emojis.value.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! FTEmojiCollectionViewCell1
//        cell.emojisItem = viewModel.emojis.value[indexPath.row]
//        return cell
//    }
//}
