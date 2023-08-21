//
//  FTRecentSectionHeader.swift
//  Noteshelf3
//
//  Created by Sameer on 06/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public protocol FTRecentSectionDelegate: AnyObject {
    func didTapClearAllButton()
}

public class FTRecentSectionHeader: UIView {
    @IBOutlet private var titleLabel: FTCustomLabel?
    @IBOutlet private var clearAllButton: FTCustomButton?

    private weak var del: FTRecentSectionDelegate?

   public static func recentSectionHeader(with del: FTRecentSectionDelegate?) -> FTRecentSectionHeader {
        let bundle = Bundle(for: FTRecentSectionHeader.self)
       guard let view = bundle.loadNibNamed(String(describing: FTRecentSectionHeader.self), owner:nil , options: nil)?.first as? FTRecentSectionHeader else {
           fatalError("Progarammer error, unable to find FTRecentSectionHeader")
       }
       view.del = del
       return view
    }

    public func updateSectionTitle(_ title: String) {
        self.titleLabel?.text  = title
    }

    @IBAction func didTapClearButton(_ sender: Any) {
        self.del?.didTapClearAllButton()
    }
}
