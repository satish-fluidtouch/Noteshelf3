//
//  ShareViewController.swift
//  Noteshelf Action
//
//  Created by Matra on 09/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class ShareViewController: UIViewController {

    @IBOutlet weak var sContentView: UIView?
    @IBOutlet weak var lblMessage: UILabel?

    @IBOutlet weak var progressContainerView: UIView?
    @IBOutlet weak var lblProgress: UILabel?
    @IBOutlet weak var lblProgressMessage: UILabel?
    @IBOutlet weak var progressView: UIProgressView?
    
    @IBOutlet weak var successCheckBox:BEMCheckBox?

    private var loadingFirstTime = true;
    private var progressObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOSApplicationExtension 13.0, *) {
            self.isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        };
        self.successCheckBox?.onCheckColor = UIColor.white
        let blueDogerColor = UIColor.init(red: 74/255.0, green: 161/255.0, blue: 255/255, alpha: 1.0);
        self.successCheckBox?.onFillColor = blueDogerColor;
        self.successCheckBox?.onTintColor = blueDogerColor;
        self.successCheckBox?.lineWidth = 3.0
        self.successCheckBox?.onAnimationType = BEMAnimationType.bounce
        
        self.sContentView?.layer.cornerRadius = 12.0
        self.sContentView?.layer.shadowColor = UIColor.black.cgColor
        self.sContentView?.layer.shadowRadius = 12
        self.sContentView?.layer.masksToBounds = true
        self.sContentView?.isHidden = true


        self.progressContainerView?.layer.cornerRadius = 12.0
        self.progressContainerView?.layer.shadowColor = UIColor.black.cgColor
        self.progressContainerView?.layer.shadowRadius = 12
        self.progressContainerView?.layer.masksToBounds = true

        self.progressView?.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
        self.lblProgressMessage?.text = NSLocalizedString("Generating", comment: "Generating")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        if(loadingFirstTime) {
            loadingFirstTime = false;
            guard let extContext = self.extensionContext else {
                self.showUnSupportedIndicator()
                return
            }
            
            let helper = FTExtensionAtttachmentsHelper()
            helper.loadInputAttachments(extContext) {[weak self] (attachmentsInfo) in
                if attachmentsInfo.hasOnlyUnSupportedFiles() {
                    self?.showUnSupportedIndicator()
                }
                else if attachmentsInfo.hasOnlyImageFiles() {
                    self?.handleImageItems(attachmentsInfo.imageItems)
                }
                else if attachmentsInfo.hasOnlyWebsiteLinks() {
                    if let window = self?.view.window {
                        DispatchQueue.main.async {
                            self?.progressContainerView?.isHidden = false
                        }
                        FTPDFConverter.shared.convertToPDF(url: attachmentsInfo.websiteURLs[0], view: window, onSuccess: { filePath in
                            FTImportStorageManager.addNewImportAction(URL(fileURLWithPath: filePath));
                            self?.showSuccessIndicator()
                        }, onFailure: { [weak self] _ in
                            self?.showUnSupportedIndicator()
                        }, progress: { [weak self] progress in
                            self?.lblProgress?.text = "\(Int(progress*100)) %"
                            self?.progressView?.progress = progress
                        })
                    }
                }
                else if attachmentsInfo.hasOnlyPublicImageURLs() {
                    DispatchQueue.main.async {
                        self?.progressContainerView?.isHidden = false
                        self?.lblProgress?.text = "\(Int(0.5*100)) %"
                        self?.progressView?.progress = 0.5
                    }
                    let imageURL = attachmentsInfo.publicImageURLs[0]
                    
                    let task = URLSession.shared.dataTask(with: imageURL) {[weak self] (data, _, error) in
                        guard let imageData = data, error == nil else {
                            self?.showUnSupportedIndicator()
                            return
                        }
                        DispatchQueue.main.async() {
                            if let image = UIImage(data: imageData) {
                                let filePath = FTPDFFileGenerator().generatePDFFile(withImage: image)
                                FTImportStorageManager.addNewImportAction(URL(fileURLWithPath: filePath))
                                self?.lblProgress?.text = "\(Int(1.0*100)) %"
                                self?.progressView?.progress = 1.0
                                self?.showSuccessIndicator()
                            }
                            else {
                                self?.showUnSupportedIndicator()
                            }
                        }
                    }
                    task.resume()
                }
                else if attachmentsInfo.hasPublicFiles() {
                    attachmentsInfo.publicURLs.forEach { (importedURL) in
                        FTImportStorageManager.addNewImportAction(importedURL)
                    }
                    if !attachmentsInfo.imageItems.isEmpty {
                        self?.handleImageItems(attachmentsInfo.imageItems)
                    }
                    else {
                        self?.showSuccessIndicator()
                    }
                }
                else {
                    self?.showUnSupportedIndicator()
                }
            }
        }
    }
    private func handleImageItems(_ imageItems: [UIImage]) {
        self.progressContainerView?.isHidden = false
        self.lblProgress?.text = "\(Int(0.0*100)) %"
        self.progressView?.progress = 0.0
        //*******************
        let conversionProgress: Progress = FTPDFFileGenerator().generatePDFFile(withImages: imageItems, onCompletion: {[weak self] (filePath) in
            FTImportStorageManager.addNewImportAction(URL(fileURLWithPath: filePath));
            self?.progressView?.progress = 1.0
            self?.showSuccessIndicator()
        })
        
        self.progressObserver = conversionProgress.observe(\.fractionCompleted,
                                   options: [.new, .old]) { [weak self] (progress, _) in
            DispatchQueue.main.async() { [weak self] in
                let fraction = Float(progress.fractionCompleted);
                self?.progressView?.progress = fraction
                self?.lblProgress?.text = "\(Int(fraction*100)) %"
            }
        }
        //*******************
    }
    @IBAction func done() {
        self.extensionContext?.completeRequest(returningItems: self.extensionContext?.inputItems, completionHandler: nil)
    }
    
    func didCancelChoosingTemplate(){
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private var supportedMimeTypes : [String] {
        var supportedMimeTypes = supportedMimeTypesForDownload();
        supportedMimeTypes.append(contentsOf: [UTI_TYPE_NOTESHELF_BOOK,UTI_TYPE_NOTESHELF_NOTES]);
        return supportedMimeTypes;
    }
    
    private func showSuccessIndicator()
    {
        DispatchQueue.main.async() { [weak self] in
            self?.successCheckBox?.isHidden = false;
            self?.progressContainerView?.isHidden = true
            self?.showContentWithAnimation(text: NSLocalizedString("ShareToNoteshelf", comment: "Sent to Noteshelf"));
            UIView.animate(withDuration: 1.5, animations: {
                self?.successCheckBox?.setOn(true, animated: true)
            })
            FTUserDefaults.defaults().userImportCount += 1;
            self?.progressObserver?.invalidate()
        }
    }
    
    private func showUnSupportedIndicator()
    {
        DispatchQueue.main.async() { [weak self] in
            self?.progressContainerView?.isHidden = true
            self?.successCheckBox?.isHidden = true;
            self?.showContentWithAnimation(text: NSLocalizedString("NotSupportedFormat", comment: "This format is not supported by Noteshelf"));
            self?.progressObserver?.invalidate()
        }
    }
    
    private func showContentWithAnimation(text:String)
    {
        self.sContentView?.isHidden = false
        self.sContentView?.alpha = 0.0
        UIView.animate(withDuration: 0.1, animations: {
            self.sContentView?.alpha = 1.0
        });
        self.lblMessage?.text = text;
    }
}
