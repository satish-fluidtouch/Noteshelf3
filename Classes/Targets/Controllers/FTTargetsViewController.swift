//
//  FTTargetsViewController.swift
//  Noteshelf
//
//  Created by Siva on 03/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc protocol FTTargetsViewControllerDelegate : NSObjectProtocol {
    @objc optional func shouldShowScanDocumentsInTargetsViewController(_ targetsViewController: FTTargetsViewController) -> Bool;
    func targetsViewController(_ targetsViewController: FTTargetsViewController, shouldShowExportTarget targetMode : RKExportMode) -> Bool;

    func targetsViewController(_ targetsViewController: FTTargetsViewController, didSelectTarget target: FTExportImportTargetProtocol);
}

enum TargetTag: Int {
    case selectedTargets
    case specialTargets
}

class FTTargetsViewController: UIViewController, FTCustomPresentable {
    var customTransitioningDelegate: FTCustomTransitionDelegate = FTCustomTransitionDelegate.init(with: .interaction)
    
    weak var delegate: FTTargetsViewControllerDelegate!;
    var mode: FTTargetMetaDataPurpose!;
    var targetShareButton:UIButton?
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var collectionView: UICollectionView?
    
    private var targetMetaData: FTTargetMetaData!;
    
    override func viewDidLoad() {
        super.viewDidLoad();

//        self.tableView?.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .light));
        
        var canShowScanDocuments = false;
        if self.mode == FTTargetMetaDataPurpose.import {
            if self.delegate.responds(to: #selector(self.delegate.shouldShowScanDocumentsInTargetsViewController(_:))) {
                canShowScanDocuments = self.delegate.shouldShowScanDocumentsInTargetsViewController!(self);
            }
            else {
                canShowScanDocuments = true;
            }
        }
        self.targetMetaData = FTTargetMetaData(purpose: self.mode, canShowScanDocuments: canShowScanDocuments);
        self.targetMetaData.showFacebook = self.delegate.targetsViewController(self, shouldShowExportTarget: kExportModeFacebook);
        self.targetMetaData.showTwitter = self.delegate.targetsViewController(self, shouldShowExportTarget: kExportModeTwitter);
        if(self.mode == FTTargetMetaDataPurpose.export) {
            self.targetMetaData.showSaveAsTemplate = self.delegate.targetsViewController(self, shouldShowExportTarget: kExportModeSaveAsTemplate);
            self.targetMetaData.showSchoolwork = self.delegate.targetsViewController(self, shouldShowExportTarget: kExportModeSchoolwork)
        }        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        if let navigationController = self.navigationController {
            navigationController.preferredContentSize = CGSize.init(width: 0, height: 507);
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();        
        if(canbePopped()){
            self.backButton?.isHidden = false
            self.backButton?.setImage(UIImage.init(named: "backDark"), for: UIControl.State.normal)
        }
        else {
            self.backButton?.isHidden = true
        }
    }
    
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    
    //MARK:- Presentation
    class func showTargetPopover(forMode mode: FTTargetMetaDataPurpose, withDelegate delegate: FTTargetsViewControllerDelegate, fromSourceView sourceView: UIView, onViewController viewController: UIViewController) -> FTTargetsViewController {
        let targetsViewController: FTTargetsViewController!;
        if self == FTImportDocumentTargetsViewController.self {
            targetsViewController = UIStoryboard(name: "FTDocumentEntity", bundle: nil).instantiateViewController(withIdentifier: FTImportDocumentTargetsViewController.className) as! FTImportDocumentTargetsViewController;
        }
        else {
            targetsViewController = UIStoryboard(name: "FTTargets", bundle: nil).instantiateInitialViewController() as? FTTargetsViewController;
        }
        targetsViewController.delegate = delegate;
        targetsViewController.setPurpose(mode);
        targetsViewController.targetShareButton = sourceView as? UIButton
        targetsViewController.customTransitioningDelegate.sourceView = sourceView
        viewController.ftPresentModally(targetsViewController, animated: true, completion: nil)

        return targetsViewController;
    }
    
    //MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let targetsMoreViewController = segue.destination as? FTTargetsMoreViewController {
            //, let targetsMoreViewController = navigationController.viewControllers.first as? FTTargetsMoreViewController {
            targetsMoreViewController.delegate = self;
            targetsMoreViewController.targetMetaData = self.targetMetaData;
        }
    }
    
    //MARK:- Custom
    func setPurpose(_ mode: FTTargetMetaDataPurpose) {
        self.mode = mode;
    }
}

extension FTTargetsViewController: FTTargetsMoreViewControllerDelegate {
    func didFinishTargetsMoreViewController(_ targetsMoreViewController: FTTargetsMoreViewController) {
        self.targetMetaData.reloadSelectedTargets();
        self.collectionView?.reloadData();
        //self.presentedViewController?.dismiss(animated: true, completion: nil);
    }
}

extension FTTargetsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    //UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let tag = TargetTag(rawValue: section)
        switch tag! {
            case .selectedTargets:
                return self.targetMetaData.selectedTargets.count + 1;//added 1 for more button
            case .specialTargets:
                return self.targetMetaData.specialTargets.count;
        }
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "TargetsCollectionReusableView", for: indexPath)
        headerView.isHidden = (indexPath.section == 0)
        return headerView
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let targets: [FTExportImportTargetProtocol];
        let tag = TargetTag(rawValue: indexPath.section)!;
        switch tag {
        case .selectedTargets:
            targets = self.targetMetaData.selectedTargets;
        case .specialTargets:
            targets = self.targetMetaData.specialTargets;
        }

        
        if tag == .selectedTargets
            && indexPath.item >= targets.count {
            let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCellMore", for: indexPath) as! FTTargetCollectionViewCell;
            collectionViewCell.isAccessibilityElement = true;
            collectionViewCell.accessibilityIdentifier = "MoreTarget"

            collectionViewCell.labelTitle?.text = NSLocalizedString("More", comment: "More...");
            collectionViewCell.accessibilityLabel = collectionViewCell.labelTitle?.text;
            return collectionViewCell;
        }
        else {
            let target = targets[indexPath.item]

            let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCellTarget", for: indexPath) as! FTTargetCollectionViewCell;
            collectionViewCell.isAccessibilityElement = true;
            collectionViewCell.accessibilityIdentifier = "Target_\(target.name)"

            collectionViewCell.imageViewIcon?.image = target.image;
            collectionViewCell.labelTitle?.text = target.name;
            
            collectionViewCell.accessibilityLabel = collectionViewCell.labelTitle?.text;

            return collectionViewCell;
        }
        
    }
    //UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let targets: [FTExportImportTargetProtocol];
        let tag = TargetTag(rawValue: indexPath.section)!;
        switch tag {
        case .selectedTargets:
            targets = self.targetMetaData.selectedTargets;
        case .specialTargets:
            targets = self.targetMetaData.specialTargets;
        }
        
        if tag == .selectedTargets
            && indexPath.item >= targets.count {
            self.performSegue(withIdentifier: "showMoreTargets", sender: nil)
        }
        else {
            let target = targets[indexPath.item]
            #if NOTESHELF_RETAIL_DEMO
            if (target is FTDropboxExportTarget ||
                target is FTGoogleDriveExportTarget ||
                target is FTEvernoteExportTarget ||
                target is FTBoxExportTarget ||
                target is FTOneDriveExportTarget ||
                target is FTFacebookExportTarget ||
                target is FTTwitterExportTarget ||
                target is FTiTunesExportTarget ||
                
                target is FTImportActionDropbox ||
                target is FTImportActionGDrive ||
                target is FTImportActionBox ||
                target is FTImportActionOneDrive ||
                target is FTImportActionItunes
                )
            {
                UIAlertController.showDemoLimitationAlert(withMessageID: (target is FTImportAction) ? "ImportFromOthersLimitation" : "ExportToOthersLimitation", onController: self)
                return
            }
            #endif

            self.delegate.targetsViewController(self, didSelectTarget: target);
            
            if(self.mode == FTTargetMetaDataPurpose.export) {
                track("export_action", params: ["destination" : target.name]);
            } else {
                track("import_action", params: ["source" : target.name]);
            }
        }
    }
}
