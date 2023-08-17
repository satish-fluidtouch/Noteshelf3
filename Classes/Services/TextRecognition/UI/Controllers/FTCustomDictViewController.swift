//
//  FTCustomDictViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 15/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTCustomDictViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var addTextField: UITextField!
    @IBOutlet private weak var addView: UIView!
    @IBOutlet private weak var headerInfo: UILabel!
    @IBOutlet private weak var addBtn: UIButton!

    private let reuseId = "Cell"
    private var customWords: [String] = []
    private let manager = FTSpellCheckManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
        self.customWords = manager.fetchSpellLearnWords().caseInsensitiveSorted()
    }

    private func configureUI() {
        self.navigationItem.title = "convertToText.customDictionary".localized
        let font = UIFont.clearFaceFont(for: .medium, with: 20)
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
        self.navigationController?.navigationBar.titleTextAttributes = attributes

        self.addView.layer.cornerRadius = 10.0
        self.addView.layer.masksToBounds = true
        self.addTextField.delegate = self
        let reqFont = UIFont.appFont(for: .regular, with: 17.0)
        let placeholderText = NSAttributedString(string: "convertToText.cutomDict.newWord".localized, attributes: [
            .foregroundColor: UIColor.label,
            .font: reqFont,
            .baselineOffset: 0
        ])
        self.addTextField.attributedPlaceholder = placeholderText
        self.addTextField.font = reqFont
        let config = UIImage.SymbolConfiguration(font: reqFont)
        self.addBtn.imageView?.tintColor = .appColor(.accent)
        self.addBtn.setImage(UIImage(systemName: FTIcon.plusCircle.name, withConfiguration: config), for: .normal)
        self.headerInfo.text = "convertToText.cutomDict.headerInfo".localized
        self.tableView.contentInset.top = -32.0
    }

    @IBAction private func addTapped(_ sender: Any) {
        self.addTextField.becomeFirstResponder()
    }

    private func handleNewCustomWord(_ word: String) {
        if !self.customWords.contains(word) {
            self.customWords.append(word)
            self.customWords = self.customWords.caseInsensitiveSorted()
            self.tableView.reloadData()
            UITextChecker.learnWord(word)
            FTSpellCheckManager.shared.save(spellWord: word)
            self.addTextField.text = ""
        } else {
            self.informDuplication()
        }
    }

    private func informDuplication() {
        let alertController = UIAlertController(title: "", message: "convertToText.cutomDict.duplicateWord".localized, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok".localized, style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension FTCustomDictViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, !text.isEmpty {
            self.handleNewCustomWord(text)
        }
        textField.resignFirstResponder()
        return true
    }
}

extension FTCustomDictViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.customWords.count
    }

    private func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: reuseId)
        cell.backgroundColor = UIColor.appColor(.white60)
        let word = self.customWords[indexPath.row]
        var config = cell.defaultContentConfiguration()
        let attributes = [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 17.0)]
        config.attributedText = NSAttributedString(string: word, attributes: attributes)
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let removeWord = self.customWords[indexPath.row]
            self.customWords.remove(at: indexPath.row)
            self.manager.remove(spellWord: removeWord)
            tableView.performBatchUpdates {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
}

private extension Array<String> {
    func caseInsensitiveSorted() -> [String] {
        return self.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
    }
}
