//
//  FTTagsViewController.swift
//  FTAddOperations
//
//  Created by Siva on 15/06/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import UIKit
import FTCommon

protocol FTTagsViewControllerDelegate: NSObjectProtocol {
    func addTagsViewController(didTapOnBack controller: FTTagsViewController);
    func didAddTag(tag: FTTagModel) async throws
    func didRenameTag(tag: FTTagModel, renamedTag: FTTagModel) async throws
    func didDeleteTag(tag: FTTagModel) async throws
    func didUnSelectTag(tag: FTTagModel) async throws
    func tagsViewControllerFor(items: [FTShelfItemProtocol],onCompletion:@escaping((Bool) -> Void))
}

class FTTagsViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()
    weak var delegate: FTTagsViewControllerDelegate?
    weak var contextMenuTagDelegate: FTFinderContextMenuTagDelegate?

    @IBOutlet weak var tagsView: FTTagsView?
    @IBOutlet weak var textField: UITextField?
    @IBOutlet private weak var cancelButton: FTCustomButton?

    var tagsList: [FTTagModel] = []

    var isPresenting = false
    var showCloseIcon = false
    var showBackButton = false
    var sourceViewController: UIViewController?
    var tagsType: FTTagsType = .page
    var lastUsedTag = ""
    deinit {
           #if DEBUG
               debugPrint("deinit \(self.classForCoder)");
           #endif
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshShelfTags"), object: nil, userInfo: ["tag": lastUsedTag])
       }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        if showCloseIcon {
#if targetEnvironment(macCatalyst)
            self.cancelButton?.isHidden = false
#endif
        }
        self.textField?.delegate = self
        self.textField?.layer.cornerRadius = 10.0
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 34))
        textField?.leftView = paddingView
        textField?.leftViewMode = .always

        let shadowColor = UIColor(hexString: "#000000")
        view.layer.applySketchShadow(color: shadowColor, alpha: 0.2, x: 0.0, y: 10.0, blur: 30.0, spread: 0)
        configureTagsView()
        updatePreferredContentSize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        updatePreferredContentSize()
        self.navigationController?.navigationBar.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        self.delegate?.addTagsViewController(didTapOnBack: self)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    //MARK:- Custom Functions
    func configureTagsView() {
        tagsView?.backgroundColor = UIColor.appColor(.cellBackgroundColor)
        tagsView?.layer.cornerRadius = 10
        tagsView?.delegate = self
        tagsView?.items = self.tagsList
        self.tagsView?.refresh()
        if self.tagsList.isEmpty {
            tagsView?.isHidden = true
        }
    }

    func updatePreferredContentSize() {
//        if sourceViewController?.isRegularClass() ?? false {
        var height: CGFloat = 364
            if let contentSize = self.tagsView?.collectionView.contentSize {
                self.navigationController?.preferredContentSize = CGSize(width: defaultPopoverWidth, height: max(height, contentSize.height))
            }
    }
    
    static func showTagsController(fromSourceView sourceView:Any, onController controller:UIViewController, tags: [FTTagModel]){
        let storyBoard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        if let tagsController: FTTagsViewController = storyBoard.instantiateViewController(withIdentifier: "FTTagsViewController") as? FTTagsViewController {
            tagsController.tagsList = tags
            tagsController.isPresenting = true
            tagsController.sourceViewController = controller
            tagsController.delegate = controller as? FTTagsViewControllerDelegate
            tagsController.contextMenuTagDelegate = controller as? FTFinderContextMenuTagDelegate
            tagsController.ftPresentationDelegate.source = sourceView as AnyObject
            controller.ftPresentPopover(vcToPresent: tagsController, contentSize: CGSize(width: 320, height:360))
        }
    }

    static func presentTagsController(onController controller:UIViewController, tags: [FTTagModel]){
        let storyBoard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        if let tagsController: FTTagsViewController = storyBoard.instantiateViewController(withIdentifier: "FTTagsViewController") as? FTTagsViewController {
            tagsController.tagsList = tags
            tagsController.isPresenting = true
            tagsController.showCloseIcon = true
            tagsController.sourceViewController = controller
            tagsController.delegate = controller as? FTTagsViewControllerDelegate
            tagsController.contextMenuTagDelegate = controller as? FTFinderContextMenuTagDelegate
            tagsController.modalPresentationStyle = .formSheet
            controller.ftPresentFormsheet(vcToPresent: tagsController, contentSize: CGSize(width: 320, height:360))
        }
    }
    
    func searchResultsFor(searchText: String) -> [FTTagModel]? {
        if !searchText.isEmpty {
            let filteredTags = self.tagsList.filter({ (tag) -> Bool in
                return tag.text.lowercased().contains(searchText.lowercased())
            })
            return filteredTags
        }
        return self.tagsList
    }

    //MARK:- IBActions
    @IBAction func cancelButtonTapped(_ sender: UIButton?) {
        self.dismiss(animated: true)
        UserDefaults.standard.setValue("", forKey: TAG_MENU_TYPE_SELECTED_NAME_KEY)
    }
    
    //MARK:- Notifications Handling
    @objc func keyboardWillShow(_ notification:Notification) {
        if !self.traitCollection.isRegular {
            if let newFrame = (notification.userInfo?[ UIResponder.keyboardFrameEndUserInfoKey ] as? NSValue)?.cgRectValue {
                let insets = UIEdgeInsets( top: 0, left: 0, bottom: newFrame.height, right: 0 )
            }
        }
    }
    //MARK:- Gesture Handling
    @objc func keyboardWillHide(_ notification:Notification) {

    }

    func didAddNewTag(tag: String) {
        if tag.count > 0 {
            tagsView?.isHidden = false
            let filtered =  self.tagsList.filter {$0.text == tag }
            if filtered.count == 0 {
                let item = FTTagModel(text: tag, isSelected: true)
                self.tagsList.append(item)
                // Add new unique page tag
                let sortedArray = self.tagsList.sorted(by: { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending })
                self.tagsList = sortedArray
                tagsView?.items = self.tagsList
                self.tagsView?.refresh()
                track("tag_action", params: ["isAdded" : true])
                Task {
                    do {
                        try await self.delegate?.didAddTag(tag: item)
                        self.performDidAddTag(tag: item.text)
                    } catch {

                    }
                }
            }
        }
    }
}

// MARK: TagsViewDelegate
extension FTTagsViewController: TagsViewDelegate {
    func didSelectIndexPath(indexPath: IndexPath) {
        let item = self.tagsList[indexPath.row]
        // Update page tags based on Select and Unselect
        if item.isSelected {
            item.isSelected = false
            Task {
                do {
                    try await self.delegate?.didUnSelectTag(tag: item)
                    let docIds = FTCacheTagsProcessor.shared.documentIdsForTag(tag: item)
                    if docIds.isEmpty {
                        self.performDidDeleteTag(tag: item.text)
                    }
                } catch {

                }
            }
            track("tag_action", params: ["isAdded" : false])
        } else {
            item.isSelected = true
            Task {
                do {
                    try await self.delegate?.didAddTag(tag: item)
                } catch {

                }
            }
            track("tag_action", params: ["isAdded" : true])
        }
        self.tagsList[indexPath.row] = item
        let sortedArray = self.tagsList.sorted(by: { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending })
        self.tagsList = sortedArray
        tagsView?.items = self.tagsList
        self.tagsView?.refresh()

    }

    func didRenameTag(tag: FTTagModel) {
        UIAlertController.showRenameDialog(with: "Rename".localized, message: "", renameText: tag.text, from: self) { [weak self] renamedTag in
            guard let self = self else { return }
            let oldTag = FTTagModel(id: tag.id, text: tag.text, isSelected: tag.isSelected)

            //Rename tag from All Pages from All Books
            tag.text = renamedTag;
            let sortedArray = self.tagsList.sorted(by: { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending })
            self.tagsList = sortedArray
            self.tagsView?.items = self.tagsList
            self.tagsView?.refresh()
            self.performDidRenameTag(tag: oldTag.text, renamedTag: renamedTag)

            Task {
                do {
                    try await self.delegate?.didRenameTag(tag: oldTag, renamedTag: FTTagModel(id: tag.id, text: renamedTag, isSelected: tag.isSelected))
                }
                catch {
                    print(error)
                }
            }
        }
    }

    func didDeleteTag(tag: FTTagModel) {
        UIAlertController.showDeleteDialog(with: String(format: "tags.delete.alert.title".localized, "\"\(tag.text)\""), message: "tags.delete.alert.message".localized, from: self) {
            self.tagsList.removeAll { tagModel in
                tagModel.text == tag.text
            }

            let sortedArray = self.tagsList.sorted(by: { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending })
            self.tagsList = sortedArray
            self.tagsView?.items = self.tagsList
            self.tagsView?.refresh()
            if self.tagsList.isEmpty {
                self.tagsView?.isHidden = true
            } else {
                self.tagsView?.isHidden = false
            }
            //Remove tag from All Pages from All books
            Task {
                do {
                    try await self.delegate?.didDeleteTag(tag: tag)
                    self.performDidDeleteTag(tag: tag.text)
                } catch {

                }
            }
            track("Tag_Delete")
        }
    }

    @MainActor
    func performDidAddTag(tag: String) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil, userInfo: ["tag": tag, "type": "add", "renamedTag": ""])
    }

    @MainActor
    func performDidDeleteTag(tag: String) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil, userInfo: ["tag": tag, "type": "delete", "renamedTag": ""])
    }

    @MainActor
    func performDidRenameTag(tag: String, renamedTag: String) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil, userInfo: ["tag": tag, "type": "rename", "renamedTag": renamedTag])
        self.lastUsedTag = renamedTag
        track("Tag_Rename")
    }

}

// MARK:- UITextFieldDelegate
extension FTTagsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let cleanedString = (textField.text?.trimmingCharacters(in: .whitespaces)) ?? ""
        self.didAddNewTag(tag: cleanedString)
        textField.text = ""
        return true
    }

}
