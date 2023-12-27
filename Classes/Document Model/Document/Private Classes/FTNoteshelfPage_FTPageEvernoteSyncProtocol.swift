//
//  FTNoteshelfPage_FTPageEvernoteSyncProtocol.swift
//  Noteshelf
//
//  Created by Amar on 30/04/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private var evernoteRenderManager : FTOffScreenRenderer?;

extension FTNoteshelfPage : FTPageEvernoteSyncProtocol
{
    fileprivate func pageRectForEnSync() -> CGRect {
        var rect = CGRect.zero;
        rect.size = self.pageReferenceViewSize();
        rect.size = CGSize.aspectFittedSize(rect.size, min: CGSize.init(width: minImageExportSize,
                                                                        height: minImageExportSize));
        return rect.integral;
    }
    
    #if !targetEnvironment(macCatalyst)
    var edamResource: EDAMResource? {
        if(FTENPublishManager.shared.shouldCancelPublishing) {
            FTLogError("Evernote Publish Error", attributes: ["Reason": "Publish Cancelled"])
            return nil;
        }
        let pageRect = self.pageRectForEnSync();

        let scale = UIScreen.main.scale;
        let pageImage = FTPDFExportView.snapshot(forPage: self,
                                             size: pageRect.size,
                                             screenScale: scale,
                                             shouldRenderBackground: true,
                                             offscreenRenderer: self.getOffscreenRenderer(),
                                             with: FTSnapshotPurposeEvernoteSync)
        if let image = pageImage, let myFileData = image.jpegData(compressionQuality: 0.6) {
            let mime = "image/jpeg";
            let imageDataHash = (myFileData as NSData).enmd5;
            
            let edamData = EDAMData();
            edamData?.bodyHash = imageDataHash();
            edamData?.size = Int32(myFileData.count);
            edamData?.body = myFileData;
            
            let attributes = EDAMResourceAttributes();
            attributes?.fileName = (self.uuid as NSString).appendingPathExtension("jpg");
            
            let resource = EDAMResource();
            resource?.guid = self.uuid;
            resource?.noteGuid = nil;
            resource?.data = edamData;
            resource?.mime = mime;
            resource?.width = Int16(Float(image.size.width) as Float)
            resource?.height = Int16(Float(image.size.height) as Float)
            resource?.duration = Int16();
            resource?.active =  true;
            resource?.recognition = nil;
            resource?.attributes = attributes;
            resource?.updateSequenceNum = Int32();
            resource?.alternateData = nil;
            
            return resource;
        }
        FTLogError("Evernote Publish Error", attributes: ["Reason": "Did not find image"])
        return nil;
    }
    #endif

    private func getOffscreenRenderer() -> FTOffScreenRenderer?
    {
        if(nil == evernoteRenderManager) {
            evernoteRenderManager = FTRendererProvider.shared.dequeOffscreenRenderer();
        }
        return evernoteRenderManager;
    }
}
