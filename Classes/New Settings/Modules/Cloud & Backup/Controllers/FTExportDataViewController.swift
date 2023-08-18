//
//  FTExportDataViewController.swift
//  Noteshelf
//
//  Created by Akshay on 03/11/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTExportDataViewController: UIViewController,  FTViewControllerSupportsScene {
    var addedObserverOnScene: Bool = false

    @IBOutlet weak var backupNowButton: UIButton?
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var errorLabel: UILabel?

    private var exportManager : FTDBBackupManager?
    private var activityController : UIActivityViewController?

    private var failedItems: [String]? {
        didSet {
            self.tableView?.reloadData()
        }
    }

    private var backupError: String? {
        didSet {
            errorLabel?.text = backupError
            if backupError == nil {
                errorLabel?.isHidden = true
            } else {
                errorLabel?.isHidden = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        failedItems = nil
        backupError = nil
        backupNowButton?.setTitle("export_data".localized, for: .normal)
        backupNowButton?.layer.cornerRadius = 10.0
        backupNowButton?.addShadow(color: UIColor.appColor(.accent), offset: CGSize(width: 0, height: 4), opacity: 0.24, shadowRadius: 8.0)
        self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)

        self.tableView?.rowHeight = UITableView.automaticDimension
        self.tableView?.register(UINib(nibName: "FTExportDataInfoCell", bundle: nil), forCellReuseIdentifier: "FTExportDataInfoCell")
        self.tableView?.register(UINib(nibName: "FTExportDataFailedItemCell", bundle: nil), forCellReuseIdentifier: "FTExportDataFailedItemCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNewNavigationBar(hideDoneButton: false,title: "export_data".localized)
        self.tableView?.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureSceneNotifications()
    }

    @IBAction func exportDataTapped(_ sender: UIButton) {
        exportManager = nil
        failedItems = nil
        backupError = nil

        exportManager = FTDBBackupManager()
        exportManager?.startBackup(from: self, completion: { [weak self] exportResult in
            self?.handleExportDataResult(exportResult)
        })
        track("Backup_ExportData_BackupNow", screenName: FTScreenNames.shelfSettings)
    }
}

private extension FTExportDataViewController {

    func handleExportDataResult(_ exportResult: FTBackupResult) {
        switch exportResult {
        case .success(let result):
            self.failedItems = result.failedItems
            if self.failedItems != nil {
                self.backupError = "failed_following".localized
            } else {
                self.backupError = nil
            }
            self.showExportactivityController(url: result.url)
            FTCLSLog("✅ Export Data Backup Completed")
        case .failure(let error):
            self.exportManager?.cleanUpData()
            switch error {
            case .error(let failedItems):
                self.failedItems = failedItems
                if failedItems != nil {
                    self.backupError = "failed_following".localized
                } else {
                    self.backupError = "backup_unknown_error".localized
                }
            case .zippingFailed:
                self.backupError = "backup_file_create_failed".localized
            case .cancelled, .paused:
                self.backupError = nil
            }
            if self.backupError != nil {
                FTCLSLog("⚠️ Export Data Backup Failed")
            }
        }
    }

    func showExportactivityController(url: URL) {
        #if targetEnvironment(macCatalyst)
        let exportItem = FTExportItem();
        exportItem.exportFileName = url.deletingPathExtension().lastPathComponent;
        exportItem.representedObject = url.path;
        exportItem.fileName = exportItem.exportFileName;
        let finderActivity = FTCustomActivity.activity(type: kExportModeFilesDrive, format: kExportFormatNBK, items: [exportItem], baseViewController: self);
        activityController = UIActivityViewController(activityItems: [url], applicationActivities: [finderActivity])
        #else
        activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        #endif
        activityController?.popoverPresentationController?.sourceView = backupNowButton ?? self.view // so that iPads won't crash
        activityController?.popoverPresentationController?.sourceRect = self.backupNowButton?.bounds ?? CGRect.zero

        activityController?.completionWithItemsHandler = { [weak self] (_, _, _, _) in
            #if !targetEnvironment(macCatalyst)
            self?.exportManager?.cleanUpData()
            #endif
        }

        if let activityVC = activityController {
            self.present(activityVC, animated: true, completion: nil)
        }
    }
}

extension FTExportDataViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + (failedItems?.count ?? 0) // 2 -> message, format
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 27.0 : .leastNonzeroMagnitude
   }
   
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return UITableView.automaticDimension
        }
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
#if targetEnvironment(macCatalyst)
             return  FTGlobalSettingsController.macCatalystTopInset;
#else
        return .leastNonzeroMagnitude
#endif
   }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "FTExportDataInfoCell", for: indexPath) as? FTExportDataInfoCell else {
                fatalError("Programmer error - Could not find FTExportDataMessageCell")
            }

            let description1 = NSAttributedString(string: "export_description1".localized)
            let description2 = NSAttributedString(string: "export_description2".localized)

            let attributedText = NSMutableAttributedString()
            attributedText.append(description1)
            attributedText.append(NSAttributedString(string: "\n\n"))
            attributedText.append(description2)

            let range = (description2.string as NSString).range(of: ".noteshelf")
            let boldItalicAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.appFont(for: .bold, with: 17).boldItalic()
            ]
            attributedText.addAttributes(boldItalicAttributes, range: NSRange(location: description1.length + 2 + range.location, length: range.length))

            cell.messageLabel.addCharacterSpacing(kernValue: -0.41)
            cell.messageLabel.attributedText = attributedText

            return cell
        }  else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "FTExportDataFailedItemCell", for: indexPath) as? FTExportDataFailedItemCell else {
                fatalError("Programmer error - Couldnot find FTExportDataFailedItemCell")
            }
            cell.failedItemLabel.text = failedItems?[indexPath.row - 1]
            return cell
        }
    }
}

extension FTExportDataViewController: FTSceneBackgroundHandling {
    func configureSceneNotifications() {
        let object = self.sceneToObserve;
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidEnterBackground(_:)),
                                               name: UIApplication.sceneDidEnterBackground,
                                               object: object)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneWillEnterForeground(_:)),
                                               name: UIApplication.sceneWillEnterForeground,
                                               object: object)
    }

    func sceneDidEnterBackground(_ notification: Notification) {
        if(!self.canProceedSceneNotification(notification)) {
            return;
        }
        exportManager?.pause()
    }

    func sceneWillEnterForeground(_ notification: Notification) {
        if(!self.canProceedSceneNotification(notification)) {
            return;
        }
        exportManager?.resume()
    }
}
