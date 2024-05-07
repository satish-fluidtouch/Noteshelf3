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
    func tagsViewControllerFor(items: [FTShelfItemProtocol], onCompletion: @escaping ((Bool) -> Void));
    func tagsViewController(_ contorller: FTTagsViewController, addedTags: [FTTagModel], removedTags: [FTTagModel]);
}

extension FTTagsViewControllerDelegate {
    func tagsViewController(_ contorller: FTTagsViewController, addedTags: [FTTagModel], removedTags: [FTTagModel]) {
        
    }
    
    func tagsViewControllerFor(items: [FTShelfItemProtocol], onCompletion: @escaping ((Bool) -> Void)) {
    }
}


class FTTagsViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()
    weak var delegate: FTTagsViewControllerDelegate?

    @IBOutlet private weak var tagsView: FTTagsView?
    @IBOutlet private weak var textField: UITextField?
    @IBOutlet private weak var cancelButton: FTCustomButton?

    func setTagsList(_ tags: [FTTagModel]) {
        self.tagItemsList = tags;
        self.commonTagModels = tags.filter{$0.isSelected};
    }
    private var commonTagModels = [FTTagModel]();
    private var tagItemsList: [FTTagModel] = [] {
        didSet {
            tagItemsList.sortTags();
        }
    }

    private var isPresenting = false
#if targetEnvironment(macCatalyst)
    var showCloseIcon = false
#endif
    
    deinit {
        debugLog("deinit \(self.classForCoder)");
        let newlySelectedTags = Set(self.tagItemsList.filter{$0.isSelected});
        let newlyAdded = newlySelectedTags.subtracting(Set(commonTagModels));
        let removed = Set(commonTagModels).subtracting(newlySelectedTags);
        self.delegate?.tagsViewController(self, addedTags: Array(newlyAdded), removedTags: Array(removed));
    }

    override func viewDidLoad() {
        super.viewDidLoad()
#if targetEnvironment(macCatalyst)
        if showCloseIcon {
            self.cancelButton?.isHidden = false
        }
#endif
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

    static func showTagsController(fromSourceView sourceView:Any? = nil
                                   , onController controller:UIViewController
                                   , tags: [FTTagModel]){
        let storyBoard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        if let tagsController: FTTagsViewController = storyBoard.instantiateViewController(withIdentifier: "FTTagsViewController") as? FTTagsViewController {
            tagsController.setTagsList(tags)
            tagsController.isPresenting = true
            tagsController.delegate = controller as? FTTagsViewControllerDelegate
            if let _sourceVuew = sourceView {
                tagsController.ftPresentationDelegate.source = _sourceVuew as AnyObject
                controller.ftPresentPopover(vcToPresent: tagsController, contentSize: CGSize(width: 320, height:360))
            }
            else {
#if targetEnvironment(macCatalyst)
               tagsController.showCloseIcon = true
#endif
                controller.ftPresentFormsheet(vcToPresent: tagsController, contentSize: CGSize(width: 320, height:360))
            }
        }
    }

    //MARK:- IBActions
    @IBAction func cancelButtonTapped(_ sender: UIButton?) {
        self.dismiss(animated: true)
        UserDefaults.standard.setValue("", forKey: TAG_MENU_TYPE_SELECTED_NAME_KEY)
    }

    //MARK:- Notifications Handling
    func didAddNewTag(tag: String) {
        if !tag.isEmpty {
            tagsView?.isHidden = false
            let curTag = self.tagItemsList.first(where: {$0.text.localizedCaseInsensitiveCompare(tag) == .orderedSame});
            if nil == curTag {
                let tagModel = FTTagModel(id: UUID().uuidString, text: tag, image: nil, isSelected: true);
                self.tagItemsList.append(tagModel);
                self.tagsView?.items = self.tagItemsList;
                self.tagsView?.refresh()
                track("tag_action", params: ["isAdded" : true])
            }
            else if let _tag = curTag, !_tag.isSelected {
                _tag.isSelected = true
                self.tagsView?.refresh()
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
