//
//  FTUnsplashCollectionCell.swift
//  Noteshelf
//
//  Created by srinivas on 14/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTNewNotebook

class FTUnsplashCollectionCell: UICollectionViewCell {
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .center
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return imageView
    }()
    
    private lazy var selectImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.image = UIImage(named: "select")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    
    var item: FTUnSplashItem? {
        didSet {
            guard let itemUrl = item?.urls?.thumb else { return }
            Task {
                do {
                    let uiImage = try await downloadImage(with: itemUrl)
                    await MainActor.run {
                        debugPrint("unsplash image")
                        self.imageView.image = uiImage
                    }
                } catch {
                    debugPrint("catch : \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func downloadImage(with url: String) async throws -> UIImage? {
        guard let url = URL(string: url) else { throw APIError.badURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
    }
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        layout()
    }
    
    required init?(coder: NSCoder) {
//        super.init(coder: coder)
        fatalError("")
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: 90.0, height: 90.0)
    }
    
    private func layout() {
        addSubview(imageView)
        addSubview(selectImageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            selectImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            selectImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            selectImageView.heightAnchor.constraint(equalToConstant: 16.0),
            selectImageView.widthAnchor.constraint(equalToConstant: 16.0)
        ])
    }
}
