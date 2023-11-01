//
//  FTDetailDiagnosisHandler.swift
//  Noteshelf
//
//  Created by Amar on 29/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import MessageUI

extension MFMailComposeViewController {
    func addSupportMailID() {
        #if DEBUG
            self.setToRecipients(["amar@fluidtouch.biz"]);
        #else
            self.setToRecipients(["noteshelf@fluidtouch.biz"]);
        #endif
    }
}

private var sharedInstance : FTDetailDiagnosisHandler?;

class FTDetailDiagnosisHandler: NSObject,MFMailComposeViewControllerDelegate {
    func sendDetailSystemLog(_ viewController : UIViewController) {
        UIAlertController.showConfirmationDialog(with: NSLocalizedString("Warning", comment: "Warning"),
                                                 message: NSLocalizedString("ExtendedLogsMessage", comment: "ExtendedLogsMessage"),
                                                 from: viewController) {
            UIApplication.shared.isIdleTimerDisabled = true;
            let indicator = FTLoadingIndicatorViewController.show(onMode: .activityIndicator,
                                                                  from: viewController,
                                                                  withText: NSLocalizedString("Generating", comment: "Generating..."))
            sharedInstance = self;
            
            DispatchQueue.main.async {
                FTNoteshelfDocumentProvider.shared.shelfs({ (shelfCollections) in
                        var items = [FTShelfItemCollection]();
                        for eachCategory in shelfCollections {
                            items.append(contentsOf: eachCategory.categories);
                        }
                        let itemInfo = [[String:AnyObject]]();
                        self.getDetailsOfShelfCollections(shelfCollection: items,
                                                          info: itemInfo,
                                                          onCompletion:
                            { (details) in
                                UIApplication.shared.isIdleTimerDisabled = false;
                                indicator.hide();
                                var info = [String:AnyObject]();
                                info["collections"] = details as AnyObject;
                                info["userInfo"] = FTZenDeskManager.customFields() as AnyObject;
                                do {
                                    let data = try PropertyListSerialization.data(fromPropertyList: info, format: PropertyListSerialization.PropertyListFormat.xml, options: 0);
                                    self.showMail(attachmentPath: data,
                                                  viewController:viewController);
                                }
                                catch {
                                    
                                }
                        });
                    });
                };
        };
    }
        
    private func showMail(attachmentPath : Data,viewController : UIViewController)
    {
        //Attach to mail and send
        if(MFMailComposeViewController.canSendMail()) {
            let mailComposerViewController = MFMailComposeViewController.init();
            mailComposerViewController.mailComposeDelegate = self;
            mailComposerViewController.modalPresentationStyle = UIModalPresentationStyle.formSheet;
            mailComposerViewController.setSubject("Noteshelf3 Log");
            mailComposerViewController.addSupportMailID();
            
            mailComposerViewController.addAttachmentData(attachmentPath, mimeType: "application/com.ramki.logs", fileName: "detailInfo.dat")
            
            viewController.present(mailComposerViewController, animated: true, completion: nil);
        }
    }
    
    private func getDetailsOfShelfCollections(shelfCollection : [FTShelfItemCollection],
                                              info : [[String:AnyObject]],
                                              onCompletion : @escaping ([[String:AnyObject]])->Void)
    {
        var collectionItems = shelfCollection;
        let collection = collectionItems.first;
        var collectionDetails = info;
        
        if(nil == collection) {
            onCompletion(info);
        }
        else {
            collection?.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil, onCompletion: { (items) in
                let collectionItemsInfo = self.getDetailsOfShelfItems(shelfItems: items);
                
                var collectionInfo = [String:AnyObject]();
                collectionInfo["collectionTitle"] = collection!.title as AnyObject;
                collectionInfo["items"] = collectionItemsInfo as AnyObject;
                collectionDetails.append(collectionInfo);
                
                collectionItems.removeFirst();

                self.getDetailsOfShelfCollections(shelfCollection: collectionItems, info: collectionDetails, onCompletion: onCompletion);
            });
        }
    }
    
    private func getDetailsOfShelfItems(shelfItems : [FTShelfItemProtocol]) -> [[String:AnyObject]]
    {
        var detailInfo = [[String:AnyObject]]();
        for item in shelfItems
        {
            if(item is FTGroupItemProtocol) {
                let group = item as! FTGroupItemProtocol;
                var groupInfo = [[String:AnyObject]]();
                for eachItem in group.childrens {
                    let info = self.getDetailsOfShelfItem(item: eachItem);
                    groupInfo.append(info as [String : AnyObject]);
                }
                var info = [String:AnyObject]();
                info["groupTitle"] = group.URL.lastPathComponent as AnyObject;
                info["childrens"] = groupInfo as AnyObject;
                detailInfo.append(info);
            }
            else {
                let info = self.getDetailsOfShelfItem(item: item);
                detailInfo.append(info as [String : AnyObject]);
            }
        }
        return detailInfo;
    }
    
    private func getDetailsOfShelfItem(item : FTShelfItemProtocol) -> [String:String]
    {
        var info = [String:String]();
        info["bookTitle"] = item.URL.lastPathComponent;
        
        if let docItem = item as? FTDocumentItemProtocol {
            if(docItem.isDownloaded) {
                let size = FTFileSizeGenerator.getDirectoryFileSize(item.URL);
                info["file size"] = fileSize(size)
            }
            else {
                info["download state"] = "Not downloaded";
            }
        }
        return info;
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        sharedInstance = nil;
        controller.dismiss(animated: true, completion: nil)
    }

}
