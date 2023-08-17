//
//  UIBarButtonItem+Extension.swift
//  FTCommon
//
//  Created by Narayana on 15/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

public enum FTBarButtonItemType {
    case left
    case right
}

public protocol FTBarButtonItemDelegate: AnyObject {
    func didTapBarButtonItem(_ type: FTBarButtonItemType)
}

public class FTNavBarButtonItem: UIBarButtonItem {
    private weak var delegate: FTBarButtonItemDelegate?
    private let type: FTBarButtonItemType!

    public init(type: FTBarButtonItemType, title: String, delegate: FTBarButtonItemDelegate?) {
        self.type = type
        self.delegate = delegate
        super.init()
        self.title = title
        self.style = .plain
        self.target = self
        self.action = #selector(barButtonTapped)
        let attrs = [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 17),
                         NSAttributedString.Key.foregroundColor: UIColor.appColor(.accent)]
        self.setTitleTextAttributes(attrs, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func barButtonTapped(_ sender: Any) {
        self.delegate?.didTapBarButtonItem(self.type)
    }
}
