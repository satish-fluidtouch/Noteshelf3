//
//  FTCoversNavigationController.swift
//  FTNewNotebook
//
//  Created by Narayana on 10/03/23.
//

import UIKit
import FTStyles

class FTCoversHeaderController: UIViewController {
    func configureNavigationItems(with headerTitle: String) {
        let font = UIFont.appFont(for: .regular, with: 17)
        let config = UIImage.SymbolConfiguration(font: font)
        let backButtonImg = UIImage(systemName: "chevron.backward", withConfiguration: config)
        let backButtonTitle = "Back".localized
        let tintColor = UIColor.appColor(.accent)
        let backBtn: UIButton
        // TODO: To be fixed if we can get the same with single solution
#if !targetEnvironment(macCatalyst)
        var backBtnConfig = UIButton.Configuration.plain()
        backBtnConfig.title = backButtonTitle
        backBtnConfig.image = backButtonImg
        backBtnConfig.imagePadding = 0
        backBtnConfig.contentInsets = NSDirectionalEdgeInsets(top: 0.0, leading: 0.0, bottom: 0.0, trailing: 0.0)
        backBtn = UIButton(configuration: backBtnConfig)
        backBtn.tintColor = tintColor
#else
        backBtn = UIButton()
        backBtn.setTitle(backButtonTitle, for: .normal)
        backBtn.setTitleColor(tintColor, for: .normal)
        backBtn.titleLabel?.font = font
        backBtn.setImage(backButtonImg, for: .normal)
#endif
        backBtn.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)

        self.title = headerTitle
        let titleAttrs = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20.0), NSAttributedString.Key.foregroundColor: UIColor.label]
        self.navigationController?.navigationBar.titleTextAttributes = titleAttrs

        let rightButton = UIBarButtonItem(title: "Done".localized, style: .plain, target: self, action: #selector(doneTapped))
        rightButton.tintColor = FTNewNotebook.Constants.SelectedAccent.tint
        let attributes = [NSAttributedString.Key.font: font]
        rightButton.setTitleTextAttributes(attributes, for: .normal)
        self.navigationItem.rightBarButtonItem = rightButton
    }

    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc func doneTapped() {
        // It will be overridden in sub classes
    }
}
