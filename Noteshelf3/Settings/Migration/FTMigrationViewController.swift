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
    
    @IBOutlet weak var migrationTitle: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var migratedSuccessTextLabel: UILabel!
    @IBOutlet weak var warningTitle: UILabel?

    @IBOutlet weak var cancelButton: UIButton?
    @IBOutlet weak var doneButton: UIButton?
    @IBOutlet weak var progressView: UIProgressView?

    @IBOutlet weak var inProgressView: UIView?
    @IBOutlet weak var successView: UIView?
    private var messageObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.inProgressView?.isHidden = false
        self.successView?.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runInMainThread(2) {
            self.processMigration()
        }
    }

    func processMigration() {
        FTNoteshelfDocumentProvider.shared.disableCloudUpdates()
        UIApplication.shared.isIdleTimerDisabled = true

        FTCLSLog("---Migration Started---")
        let progress = FTDocumentMigration.intiateNS2ToNS3MassMigration(on: self) { [weak self] success, error in
            let status = success ? "Migration Completed" : "Migration Failed"
            FTCLSLog("---\(status)---")
            FTNoteshelfDocumentProvider.shared.enableCloudUpdates()
            self?.updateSuccessUI()
            UIApplication.shared.isIdleTimerDisabled = false
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
    }
    
    private func updateSuccessUI() {
        // TODO: To be updated with new UI, this is just temporary
        self.inProgressView?.isHidden = true
        self.successView?.isHidden = false
        self.cancelButton?.isHidden = true
    }

    @IBAction func cancelButtonTapped(_ sender: UIButton){
        //TODO: Update localization
        let alertController = UIAlertController(title: NSLocalizedString("Would you like to Cancel the Migration?", comment: ""), message: "", preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: { _ in
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Stop Migration", comment: ""), style: .destructive, handler: { [weak self] _ in
            self?.progressView?.observedProgress?.cancel()
            self?.dismiss(animated: true)
        }))
        self.present(alertController, animated: true, completion: nil)
    }

    @IBAction func doneTapped(_ sender: UIButton){
        self.dismiss(animated: false)
    }
}
