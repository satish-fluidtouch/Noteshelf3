//
//  FTTagsView.swift
//  FTTagsView
//
//  Created by Siva on 15/11/22.
//

import UIKit
import FTStyles

enum TagViewAligment {
    case left, right
}

public class FTTagModel: NSObject {
    public var id: String = ""

    public var text: String = "" {
        didSet {
            if(text != oldValue) {
                NotificationCenter.default.post(name: Notification.Name("TagDidUpdate"), object: self);
            }
        }
    }
    
    public var image: UIImage?
    public var isSelected: Bool = false

    public init(id: String = UUID().uuidString, text: String, image: UIImage? = nil, isSelected: Bool = false) {
        self.text = text
        self.image = image
        self.isSelected = isSelected
        self.id = id
    }

    public func equals(_ other: FTTagModel) -> Bool {
        return self.text == other.text
    }
}

public class FTTagViewConfiguration {
    public var bgColor: UIColor = UIColor.appColor(.white40)
    public var textColor: UIColor = UIColor.appColor(.black70)
    public var selectedTextColor: UIColor = .white
    public var tagBgColor: UIColor = UIColor.appColor(.black5)
    public var tagSelectedBgColor: UIColor = UIColor.appColor(.accent)
    public var borderColor: UIColor = .clear
    public var textFont: UIFont = UIFont.appFont(for: .medium, with: 15.0)
    public init(tagBgColor: UIColor, borderColor: UIColor) {
        self.tagBgColor = tagBgColor
        self.borderColor = borderColor
    }
    public var showContextMenu: Bool = true

}

public protocol TagsViewDelegate: AnyObject {
    func didSelectIndexPath(indexPath: IndexPath)
    func didAddNewTag(tag: String)
    func didRenameTag(tag: FTTagModel)
    func didDeleteTag(tag: FTTagModel)

}

public class FTTagsView: UIView {
    public weak var delegate: TagsViewDelegate?

    var aligment: TagViewAligment = .left {
        didSet {
            switch self.aligment {
            case .left:
                self.layout.horizontalAlignment = .left
            case .right:
                self.layout.horizontalAlignment = .right
            }
        }
    }

    public var tagConfiguration: FTTagViewConfiguration = FTTagViewConfiguration(tagBgColor: UIColor.appColor(.black5), borderColor: .clear)

    private let layout: FTTagsAlignedCollectionViewFlowLayout = {
        let layout = FTTagsAlignedCollectionViewFlowLayout()
        layout.horizontalAlignment = .leading
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        return layout
    }()

    public lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        collection.backgroundColor = self.backgroundColor
        collection.layer.cornerRadius = 10
        return collection
    }()

    public var items: [FTTagModel] = []
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    init(tags: [FTTagModel]) {
        super.init(frame: CGRect.zero)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    func setup() {
        backgroundColor = .clear
        self.addCollectionView()
        let bundle = Bundle(for: type(of: self))
        collectionView.register(UINib(nibName: FTTagCollectionCell.id, bundle: bundle), forCellWithReuseIdentifier: FTTagCollectionCell.id)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.reloadData()
    }

    private func addCollectionView() {
        self.addSubview(self.collectionView)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: self.collectionView.topAnchor).isActive = true
        self.leadingAnchor.constraint(equalTo: self.collectionView.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: self.collectionView.trailingAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: self.collectionView.bottomAnchor).isActive = true
    }

    public func refresh() {
        let indexSet = IndexSet(integer: 0)
        UIView.performWithoutAnimation {
            collectionView.reloadSections(indexSet)
        }
    }
}

// MARK:- UICollectionViewDataSource
extension FTTagsView: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTTagCollectionCell.id, for: indexPath) as! FTTagCollectionCell
        cell.setCellModel(model: self.items[indexPath.row], configuration: tagConfiguration)
        return cell
    }

}

// MARK:- UICollectionViewDelegate
extension FTTagsView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? FTTagCollectionCell {
            cell.isSelected = true
        }
        collectionView.deselectItem(at: indexPath, animated: true)
        self.delegate?.didSelectIndexPath(indexPath: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
          if let cell = collectionView.cellForItem(at: indexPath) as? FTTagCollectionCell {
              cell.isSelected = false
          }
      }

}

// MARK:- UICollectionViewDelegateFlowLayout
extension FTTagsView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let label = UILabel(frame: CGRect.zero)
        label.font = tagConfiguration.textFont
        let item = self.items[indexPath.row]
        label.text = item.text
        let iconWidth = item.image == nil ? 8 : CGFloat(25)
        label.sizeToFit()
        let size = label.frame.size
        let padding = CGFloat(12)
        return CGSize(width: size.width + iconWidth + padding, height: 36)
    }

}
