//
//  FTMigrationViewController.swift
//  Noteshelf3
//
//  Created by Akshay on 11/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTMigrationViewController: UIViewController {
    static func showMigration(on controller: UIViewController) {
        guard let migrationController = UIStoryboard(name: "Migration", bundle: nil).instantiateInitialViewController() as? FTMigrationViewController else {
            fatalError("Storyboard error for migration controller")
        }
        migrationController.modalPresentationStyle = .fullScreen
        controller.present(migrationController, animated: true)
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var migrationTitle: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var migratedSuccessTextLabel: UILabel!
    @IBOutlet weak var warningTitle: UILabel?

    @IBOutlet weak var cancelButton: UIButton?
    @IBOutlet weak var doneButton: UIButton?
    @IBOutlet weak var progressView: UIProgressView?

    @IBOutlet weak var successIndicator: BEMCheckBox!
    @IBOutlet weak var inProgressView: UIView?
    @IBOutlet weak var successView: UIView?
    private var messageObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.inProgressView?.isHidden = false
        self.successView?.isHidden = true
        self.successIndicator?.onCheckColor = UIColor.white
        self.successIndicator?.onFillColor = UIColor.init(hexString: "F97641")
        self.successIndicator?.onTintColor = UIColor.init(hexString: "F97641")
        self.successIndicator?.lineWidth = 6.0
        self.successIndicator?.onAnimationType = BEMAnimationType.bounce
        migrationTitle?.text = "migration.progress.text".localized
        warningTitle?.text = "⚠︎ " + "migration.exitScreen".localized
        migratedSuccessTextLabel.text = "migration.succes".localized
        cancelButton?.titleLabel?.text = "migration.cancel".localized
        doneButton?.setTitle(NSLocalizedString("Done", comment: "Done"), for: .normal)
        doneButton?.layer.shadowColor = UIColor.init(hexString: "186F81").cgColor
        doneButton?.layer.shadowOffset = CGSize(width: 0.0, height: 12.0)
        doneButton?.layer.shadowOpacity = 0.24
        doneButton?.layer.shadowRadius = 8.0

        self.view.backgroundColor = UIColor.init(hexString: "F0EEEB")
        self.overrideUserInterfaceStyle = .light

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runInMainThread(0.5) {
            self.processMigration()
        }
    }

    func processMigration() {
        FTNoteshelfDocumentProvider.shared.disableCloudUpdates()
        UIApplication.shared.isIdleTimerDisabled = true

        FTCLSLog("---Migration Started---")
        let progress = FTDocumentMigration.intiateNS2ToNS3MassMigration(on: self) { [weak self] success, error in
            runInMainThread {
                let status = success ? "Migration Completed" : "Migration Failed"
                FTCLSLog("---\(status)---")

                // TODO: (AK) Move to a proper location
                FTTextStyleManager.shared.migrateNS2TextStyles()
                FTFavoritePensetDataManager.shared.migrateNS2Favorites()
                FTDocumentMigration().migrateNS2CustomTemplates()

                FTNoteshelfDocumentProvider.shared.enableCloudUpdates()
                self?.updateSuccessUI()
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }

        progressView?.observedProgress = progress
        messageObserver = self.progressView?.observedProgress?.observe(\.localizedDescription, changeHandler: { [weak self] progress, message in
            runInMainThread {
                self?.descriptionLabel?.text = progress.localizedDescription
            }
        })
    }

    deinit {
        self.messageObserver?.invalidate()
        self.messageObserver = nil
        UIApplication.shared.isIdleTimerDisabled = false
        #if targetEnvironment(macCatalyst)
        self.nsToolbar?.isVisible = true
        #endif
    }
    
    private func updateSuccessUI() {
        self.inProgressView?.isHidden = true
        self.successView?.isHidden = false
        self.cancelButton?.isHidden = true
        imageView.isHidden = true
        showSuccessIndicator()
    }
    
    private func showSuccessIndicator() {
        self.successIndicator?.isHidden = false;
        UIView.animate(withDuration: 1.5, animations: {
            self.successIndicator?.setOn(true, animated: true)
        })
    }

    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.progressView?.observedProgress?.pause()
        let alertController = UIAlertController(title: "migration.cancel.alert".localized, message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: { _ in
            self.progressView?.observedProgress?.resume()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("dontMigrate", comment: ""), style: .destructive, handler: { [weak self] _ in
            self?.progressView?.observedProgress?.cancel()
            self?.dismiss()
        }))
        self.present(alertController, animated: true, completion: nil)
    }

    @IBAction func doneTapped(_ sender: UIButton){
        self.dismiss()
    }
    
    func dismiss() {
        #if targetEnvironment(macCatalyst)
        self.nsToolbar?.isVisible = true
        #endif
        self.dismiss(animated: true)
    }
}
