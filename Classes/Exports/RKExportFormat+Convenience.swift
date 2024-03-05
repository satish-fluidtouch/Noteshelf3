//
//  RKExportFormat.swift
//  Noteshelf
//
//  Created by Siva on 15/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

extension RKExportFormat {

    var displayTitle: String {
        let title: String
        switch self {
        case kExportFormatImage:
            title = "notebook.share.image"
        case kExportFormatPDF:
            title = "notebook.share.pdf"
        case kExportFormatNBK:
            title = "notebook.share.NoteshelfFile"
        case kExportFormatTemplate:
            title = "Template"
        default:
            title = ""
        }
        return title.localized
    }

    var image: UIImage {
        let exportimage:UIImage
        switch self {
        case kExportFormatImage:
            exportimage =  UIImage(named: "Export/png")!
        case kExportFormatPDF:
            exportimage = UIImage(named: "Export/pdf")!
        case kExportFormatNBK:
            exportimage = UIImage(named: "Export/nbk")!
        case kExportFormatTemplate:
            exportimage = UIImage(named: "Export/nbk")!
        default:
            exportimage = UIImage()
        }
        return exportimage
    }
    
    func filePathExtension() -> String {
        let pathExtention: String
        switch self {
        case kExportFormatImage:
            pathExtention = "png"
        case kExportFormatPDF:
            pathExtention =  "pdf"
        case kExportFormatNBK:
            pathExtention = nsBookExtension
        case kExportFormatTemplate:
            pathExtention = nsTemplateExtension
        default:
            pathExtention =  ""
        }
        return pathExtention
    }

    var iconName: FTIcon {
        let icon: FTIcon
        switch self {
        case kExportFormatImage:
            icon = .photoIcon
        case kExportFormatPDF:
            icon = .richtext
        case kExportFormatNBK:
            icon = .docText
        case kExportFormatTemplate:
            icon = .richTextfill
        default:
            icon = .photo
        }
        return icon
    }
    
    var param: String {
        let name: String
        switch self {
        case kExportFormatImage:
            name = "image"
        case kExportFormatPDF:
            name = "pdf"
        case kExportFormatNBK:
            name = "noteshelf"
        default:
            name = ""
        }
        return name
    }
}
