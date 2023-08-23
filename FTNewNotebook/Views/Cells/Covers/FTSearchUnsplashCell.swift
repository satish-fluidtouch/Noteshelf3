//
//  FTSearchUnsplashCell.swift
//  FTNewNotebook
//
//  Created by Narayana on 14/03/23.
//

import UIKit
import FTStyles

typealias FTSearchUnsplashHandler = (_ searchText: String) -> Void

protocol FTSearchUnsplashCellDelegate: AnyObject {
    func getSearchKey() -> String
}

class FTSearchUnsplashCell: UICollectionViewCell {
    @IBOutlet private weak var imgView: UIImageView!
    private(set) var searchTextField: UITextField!
    private(set) var searchStarter: UITextField!

    var searchUnsplash: FTSearchUnsplashHandler?
    weak var delegate: FTSearchUnsplashCellDelegate?

    func configure() {
        self.imgView.image = UIImage(named: "search_unsplash", in: currentBundle, with: nil)
        self.searchStarter = UITextField()
        self.searchStarter.backgroundColor = .clear
        self.searchStarter.tintColor = .clear
        self.searchStarter.borderStyle = .none
        self.searchStarter.frame.size = self.imgView.frame.size
        self.searchStarter.center = self.imgView.center
        self.imgView.addSubview(self.searchStarter)
        self.searchStarter.delegate = self
#if !targetEnvironment(macCatalyst)
        self.configureSearchAccessory()
#endif
    }

    private func configureSearchAccessory() {
        self.searchTextField = UITextField(frame: CGRect(x: 0, y: 0, width: self.window?.frame.size.width ?? 1024, height: 50))
        self.searchTextField.borderStyle = .roundedRect

        // Left view
        let searchIcon = UIImageView(image: UIImage(named: "searchIcon"))
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.frame = CGRect(x: 8, y: 0, width: 20, height: 20)
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 28, height: 20))
        paddingView.addSubview(searchIcon)
        self.searchTextField.leftView = paddingView
        self.searchTextField.leftViewMode = .always
        self.searchTextField.clearButtonMode = .always
        self.searchTextField.placeholder = "Search Unsplash"
        self.searchTextField.delegate = self
        self.searchTextField.returnKeyType = .search
        self.searchStarter.inputAccessoryView = self.searchTextField
    }
}

extension FTSearchUnsplashCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
#if !targetEnvironment(macCatalyst)
        if textField == self.searchStarter {
            self.searchTextField.becomeFirstResponder()
            self.searchTextField.text = self.delegate?.getSearchKey()
        }
#else
        self.presentSearchAlert(with: self.delegate?.getSearchKey())
#endif
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.searchStarter {
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            self.searchUnsplash?(text)
        }
        textField.resignFirstResponder()
        return true
    }
}

#if targetEnvironment(macCatalyst)
extension FTSearchUnsplashCell {
    func presentSearchAlert(with text: String?) {
        let alertController = UIAlertController(title: "Search", message: "unsplash.search.alertMessage".localized, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Search".localized
            textField.text = text
        }

        let searchAction = UIAlertAction(title: "Search".localized, style: .default) { _ in
            if let searchText = alertController.textFields?.first?.text, !searchText.isEmpty {
                self.searchUnsplash?(searchText)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil)
        alertController.addAction(searchAction)
        alertController.addAction(cancelAction)
        if let del = self.delegate as? FTUnsplashViewController {
            del.present(alertController, animated: true, completion: nil)
        }
    }
}
#endif
