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
    func didAddTag(tag: FTTagModel)
    func didUnSelectTag(tag: FTTagModel)
    func didDismissTags()
    func tagsViewControllerFor(items: [FTShelfItemProtocol],onCompletion:@escaping((Bool) -> Void))
    
    func tagsViewController(_ contorller: FTTagsViewController, addedTags: [FTTagModel], removedTags: [FTTagModel]);
}

extension FTTagsViewControllerDelegate {
    func tagsViewController(_ contorller: FTTagsViewController, addedTags: [FTTagModel], removedTags: [FTTagModel]) {
        
    }
    
    func tagsViewControllerFor(items: [FTShelfItemProtocol],onCompletion:@escaping((Bool) -> Void)) {
        
    }
}


class FTTagsViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()
    weak var delegate: FTTagsViewControllerDelegate?
    weak var contextMenuTagDelegate: FTFinderContextMenuTagDelegate?

    @IBOutlet weak var tagsView: FTTagsView?
    @IBOutlet weak var textField: UITextField?
    @IBOutlet private weak var cancelButton: FTCustomButton?

    var tagsList: [FTTagItemModel] = [] {
        didSet {
            self.tagsList = self.tagsList.sorted(by: { $0.tag.text.localizedCaseInsensitiveCompare($1.tag.text) == .orderedAscending })
        }
    }

    private var commonTagModels = [FTTagModel]();
    var tagItemsList: [FTTagModel] = [] {
        didSet {
            self.tagItemsList = self.tagItemsList.sorted(by: { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending })
        }
    }

    var isPresenting = false
    var showCloseIcon = false
    var showBackButton = false
    var tagsType: FTTagsType = .page
    var lastUsedTag = ""
    
    deinit {
        debugLog("deinit \(self.classForCoder)");
        let newlySelectedTags = Set(self.tagItemsList.filter{$0.isSelected});
        let newlyAdded = newlySelectedTags.subtracting(Set(commonTagModels));
        let removed = Set(commonTagModels).subtracting(newlySelectedTags);
        self.delegate?.tagsViewController(self, addedTags: Array(newlyAdded), removedTags: Array(removed));
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
        self.textField?.placeholder = "AddTag".localized
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 34))
        textField?.leftView = paddingView
        textField?.leftViewMode = .always
        textField?.returnKeyType = .done
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
//        self.delegate?.addTagsViewController(didTapOnBack: self)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    //MARK:- Custom Functions
    func configureTagsView() {
        tagsView?.backgroundColor = UIColor.appColor(.cellBackgroundColor)
        tagsView?.layer.cornerRadius = 10
        tagsView?.delegate = self
        tagsView?.items = self.tagItemsList;
        self.tagsView?.refresh()
        if self.tagItemsList.isEmpty {
            tagsView?.isHidden = true
        }
    }

    func updatePreferredContentSize() {
        let height: CGFloat = 364
        if let contentSize = self.tagsView?.collectionView.contentSize {
            self.navigationController?.preferredContentSize = CGSize(width: defaultPopoverWidth, height: max(height, contentSize.height))
        }
    }

    static func showTagsController(fromSourceView sourceView:Any, onController controller:UIViewController, tags: [FTTagModel]){
        let storyBoard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        if let tagsController: FTTagsViewController = storyBoard.instantiateViewController(withIdentifier: "FTTagsViewController") as? FTTagsViewController {
            tagsController.tagItemsList = tags
            tagsController.commonTagModels = tags.filter{$0.isSelected};
            tagsController.isPresenting = true
            tagsController.delegate = controller as? FTTagsViewControllerDelegate
            tagsController.contextMenuTagDelegate = controller as? FTFinderContextMenuTagDelegate
            tagsController.ftPresentationDelegate.source = sourceView as AnyObject
            controller.ftPresentPopover(vcToPresent: tagsController, contentSize: CGSize(width: 320, height:360))
        }
    }

    static func presentTagsController(onController controller:UIViewController, tags: [FTTagItemModel]){
        let storyBoard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        if let tagsController: FTTagsViewController = storyBoard.instantiateViewController(withIdentifier: "FTTagsViewController") as? FTTagsViewController {
            tagsController.tagsList = tags
            tagsController.isPresenting = true
            tagsController.showCloseIcon = true
            tagsController.delegate = controller as? FTTagsViewControllerDelegate
            tagsController.contextMenuTagDelegate = controller as? FTFinderContextMenuTagDelegate
            tagsController.modalPresentationStyle = .formSheet
            controller.ftPresentFormsheet(vcToPresent: tagsController, contentSize: CGSize(width: 320, height:360))
        }
    }

    static func presentTagsController(onController controller:UIViewController, tags: [FTTagModel]){
        let storyBoard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        if let tagsController: FTTagsViewController = storyBoard.instantiateViewController(withIdentifier: "FTTagsViewController") as? FTTagsViewController {
            tagsController.tagItemsList = tags
            tagsController.commonTagModels = tags.filter{$0.isSelected};
            tagsController.isPresenting = true
            tagsController.showCloseIcon = true
            tagsController.delegate = controller as? FTTagsViewControllerDelegate
            tagsController.contextMenuTagDelegate = controller as? FTFinderContextMenuTagDelegate
            tagsController.modalPresentationStyle = .formSheet
            controller.ftPresentFormsheet(vcToPresent: tagsController, contentSize: CGSize(width: 320, height:360))
        }
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
            if nil == self.tagItemsList.firstIndex(where: {$0.text.localizedCaseInsensitiveCompare(tag) == .orderedSame}) {
                let tagModel = FTTagModel(id: UUID().uuidString, text: tag, image: nil, isSelected: true);
                self.tagItemsList.append(tagModel);
                self.tagsView?.items = self.tagItemsList;
                self.tagsView?.refresh()
                track("tag_action", params: ["isAdded" : true])
            }
        }
    }
}

// MARK: TagsViewDelegate
extension FTTagsViewController: TagsViewDelegate {
    func didSelectIndexPath(indexPath: IndexPath) {
        let tagItem = self.tagItemsList[indexPath.row]
        // Update page tags based on Select and Unselect
        if tagItem.isSelected {
            tagItem.isSelected = false
            track("tag_action", params: ["isAdded" : false])
        } else {
            tagItem.isSelected = true
            track("tag_action", params: ["isAdded" : true])
        }
        self.tagsView?.refresh()
    }

    func performDidAddTag(tag: String) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil, userInfo: ["tag": tag, "type": "add", "renamedTag": ""])
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
