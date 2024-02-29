//
//  FTNewSettingsHeaderView.swift
//  Noteshelf
//
//  Created by Matra on 10/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

extension UIViewController {
    
     func configureNavigationBar(hideBackButton: Bool = false, hideDoneButton: Bool = false, title: String, preferLargeTitle: Bool = true) {
         self.navigationItem.hidesBackButton = true
         self.navigationController?.navigationItem.hidesBackButton = true
         self.navigationItem.title = ""

        if !hideBackButton {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: "nav_blueBack"), for: .normal)
            button.imageEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 7.5, right: 0.0)
            button.setTitle(NSLocalizedString("Back", comment: "Back"), for: .normal)
            button.titleLabel?.font = UIFont.appFont(for: .regular, with: 17)
            button.setTitleColor(.appColor(.accent), for: .normal)
            button.tintColor = .appColor(.accent)
            button.titleLabel?.addCharacterSpacing(kernValue: -0.41)
            button.frame = CGRect(x: -20, y: 0, width: NSLocalizedString("Back", comment: "Back").size().width + 53.0, height: 40) // to fix localization issue
            view.addSubview(button)
            let leftBarBtnItem = UIBarButtonItem(customView: view)
            self.navigationItem.leftBarButtonItems = [leftBarBtnItem]
            button.addTarget(self, action: #selector(leftNavBtnTapped(_ :)), for: .touchUpInside)
        }
#if !targetEnvironment(macCatalyst)
        if !hideDoneButton {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
            let button = UIButton(type: .system)
            button.frame = CGRect(x: 20, y: 0, width: 80, height: 40)
            button.setTitle(NSLocalizedString("Done", comment: "Done"), for: .normal)
            button.titleLabel?.font = UIFont.appFont(for: .regular, with: 17)
            button.setTitleColor(.appColor(.accent), for: .normal)
            button.titleLabel?.addCharacterSpacing(kernValue: -0.41)
            view.addSubview(button)
            let rightBarBtnItem = UIBarButtonItem(customView: view)
            self.navigationItem.rightBarButtonItems = [rightBarBtnItem]
            button.addTarget(self, action: #selector(rightNavBtnTapped(_ :)), for: .touchUpInside)
        }
#endif
         self.navigationItem.title = title
//         self.navigationController?.navigationBar.prefersLargeTitles = preferLargeTitle
         self.navigationController?.navigationItem.largeTitleDisplayMode = .never
    }
    
    func configureCustomNavigation(hideBackButton: Bool = false, title: String) {
        self.navigationItem.hidesBackButton = true
        if !hideBackButton {
            let leftItem = UIBarButtonItem(image: UIImage.image(for: "chevron.backward", font: UIFont.appFont(for: .medium, with: 18)), style: .plain, target: self, action: #selector(leftNavBtnTapped(_ :)))
            self.navigationItem.leftBarButtonItems = [leftItem]
        }
        self.navigationItem.title = title
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20)]
    }

    @objc func leftNavBtnTapped(_ sender : UIButton) {
        if self == self.navigationController?.viewControllers[0] {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc func rightNavBtnTapped(_ sender : UIButton) {
        self.dismiss(animated: true)
    }

    func configureNewNavigationBar(hideDoneButton: Bool = false, title: String){
#if !targetEnvironment(macCatalyst)
        if !hideDoneButton {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
            let button = UIButton(type: .system)
            button.frame = CGRect(x: 20, y: 0, width: 80, height: 40)
            button.setTitle(NSLocalizedString("Done", comment: "Done"), for: .normal)
            button.titleLabel?.font = UIFont.appFont(for: .regular, with: 17)
            button.setTitleColor(.appColor(.accent), for: .normal)
            button.titleLabel?.addCharacterSpacing(kernValue: -0.41)
            view.addSubview(button)
            let rightBarBtnItem = UIBarButtonItem(customView: view)
            self.navigationItem.rightBarButtonItems = [rightBarBtnItem]
            button.addTarget(self, action: #selector(rightNavBtnTapped(_ :)), for: .touchUpInside)
        }
#endif
        self.navigationItem.title = title
        self.navigationController?.navigationItem.largeTitleDisplayMode = .never
    }
}

extension UILabel {
  func addCharacterSpacing(kernValue: Double = 1.0) {
    guard let text = text, !text.isEmpty else { return }
    let string = NSMutableAttributedString(string: text)
    string.addAttribute(NSAttributedString.Key.kern, value: kernValue, range: NSRange(location: 0, length: string.length - 1))
    attributedText = string
  }
}

extension UITextField {
    func addCharacterSpacing(kernValue: Double = 1.0) {
      guard let text = text, !text.isEmpty else { return }
      let string = NSMutableAttributedString(string: text)
      string.addAttribute(NSAttributedString.Key.kern, value: kernValue, range: NSRange(location: 0, length: string.length - 1))
      attributedText = string
    }
}
