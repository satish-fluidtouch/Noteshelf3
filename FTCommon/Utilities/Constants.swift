//
//  Constants.swift
//  FTCommon
//
//  Created by Siva on 27/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import AVFoundation

public let UTI_TYPE_NOTESHELF_NOTES = "com.ramki.noteshelfbook"
public let UTI_TYPE_NOTESHELF_BOOK = "com.fluidtouch.noteshelfbook"
public let nsBookExtension = "noteshelf"
public let noteshelfDocumentsExt = "nsdata"
public let nsTemplateExtension = "nstemplate"

public func supportedUTITypesForDownload() -> [String] {
    var supportedUTITypes = [String]()
#if targetEnvironment(macCatalyst)
    supportedUTITypes = ["com.adobe.pdf"]
#else
    supportedUTITypes = ["com.microsoft.excel.xls", "com.microsoft.excel.xls", "org.openxmlformats.spreadsheetml.sheet","com.microsoft.word.doc", "org.openxmlformats.wordprocessingml.document","com.microsoft.powerpoint.ppt", "org.openxmlformats.presentationml.presentation","com.adobe.pdf"]
#endif
    return supportedUTITypes

}

public func supportedAudioUTITypes() -> [String]
{
    var supportedUTITypes = [String]()
        supportedUTITypes = [
            "public.aac-audio",
            "org.xiph.flac",
            AVFileType.wav.rawValue,
            AVFileType.mp3.rawValue,
            AVFileType.aiff.rawValue,
            AVFileType.caf.rawValue,
            AVFileType.m4a.rawValue,
            AVFileType.aifc.rawValue
        ]
    return supportedUTITypes;
}

//public func supportedMimeTypesForDownload() -> [String] {
//    var supportedMineTypes = [String]()
//            #if TARGET_OS_MACCATALYST
//        supportedMineTypes = ["application/pdf"];
//        #else
//        supportedMineTypes = ["application/pdf",
//                              "application/vnd.ms-excel",
//                              "application/vnd.ms-excel.12",
//                              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
//                              "application/vnd.ms-powerpoint",
//                              "application/vnd.ms-powerpoint.12",
//                              "application/vnd.openxmlformats-officedocument.presentationml.presentation",
//                              "application/msword",
//                              "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
//                              "application/vnd.ms-word.document.12",
//                              "text/html"
//                              ];
//        #endif
//    return supportedMineTypes;
//}
//
//public func MIMETypeFileAtPath(path: String) -> String?
//{
//    var result: String? = nil
//    var extractedMimeType: String? = nil
//    var pathExtension = path.pathExtension
//    if pathExtension.lowercased() == "pdf"
//    {
//        return "application/pdf"
//    }
//    if pathExtension.lowercased() == noteshelfDocumentsExt {
//        return "com.ramki.noteshelfData";
//    }
//    if pathExtension.lowercased() == nsBookExtension {
//        return "com.fluidtouch.noteshelfbook"
//    }
//
//    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
//                                                            (__bridge CFStringRef)extension, NULL);
//    if (uti) {
//        extractedMimeType = (__bridge NSString *)(uti);
//        CFStringRef cfMIMEType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
//        if (cfMIMEType) {
//            result = CFBridgingRelease(cfMIMEType);
//        }
//        CFRelease(uti);
//    }
//    if(nil == result)
//    {
//        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
//        BOOL isFolder = [[attributes fileType] isEqualToString:NSFileTypeDirectory];
//
//        BOOL isPDFPackge = ([extractedMimeType caseInsensitiveCompare:@"com.ramki.noteshelfpdf"] == NSOrderedSame)?YES:NO;
//        BOOL isNoteshelfData = ([extractedMimeType caseInsensitiveCompare:@"com.ramki.noteshelfData"] == NSOrderedSame)?YES:NO;
//
//        if(isFolder && !isPDFPackge && !isNoteshelfData)
//            result = @"";
//        else
//            result = extractedMimeType;
//    }
//    return result;
//}
//public func shouldConvertToPDF(path: String, mimeType: String) -> Bool {
//    let shouldConvert = true
//     mimeType = MIMETypeFileAtPath(path)
//    if([supportedMimeTypesForDownload().contains(mimeType)])
//    {
//        if([*mimeType isEqualToString:@"application/pdf"])
//            shouldConvert = false;
//    }
//    else {
//        *mimeType = nil;
//    }
//    return shouldConvert;
//}
//
