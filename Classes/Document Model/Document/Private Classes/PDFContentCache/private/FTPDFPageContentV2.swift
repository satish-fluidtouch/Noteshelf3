//
//  FTPDFPageContentV2.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 18/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTPDFPageContentV2: NSObject, FTPDFPageCacheContent {
    private(set) var pdfContent: String = "";
    
    private var charRectsData: Data?;
    private(set) lazy var characterRects: [CGRect] = {
        var characterRects :[CGRect] = []
        if let data = charRectsData {
            let characterRectValues:[NSValue]? = NSDataValueConverter.rectValuesArray(from: data)
            characterRectValues?.forEach { (rectValue) in
                let charRect = rectValue.cgRectValue
                characterRects.append(charRect)
            }
        }
        return characterRects
    }();
    
    private var documentUUID: String;
    private var PDFFileName: String;
    private var PDFKitPageIndex: UInt;

    required init(documentID: String,pageProtocol: FTPageProtocol) {
        PDFFileName = pageProtocol.associatedPDFFileName;
        PDFKitPageIndex = pageProtocol.associatedPDFKitPageIndex;
        documentUUID = documentID;
        super.init();
        self.load();
    }
    
    func contentExists() -> Bool {
        if FileManager().fileExists(atPath: self.cachePath.path(percentEncoded: false)) {
            return true;
        }
        return false;
    }
    
    func update(pdfContent: String, charRects: [CGRect]) {
        self.pdfContent = pdfContent;
        self.characterRects = charRects;
    }

    private var cachePath: URL {
        let fileName = FTPDFPageCacheFactory.fileName(self.PDFFileName, pageIndex: self.PDFKitPageIndex);
        let cache = FTDocumentCache.shared.cachedLocation(for: self.documentUUID).appending(path: "PDFContent");
        let cachePath = cache.path(percentEncoded: false)
        var isDir = ObjCBool(false);
        if !FileManager().fileExists(atPath: cachePath, isDirectory: &isDir) || !isDir.boolValue {
            try? FileManager().createDirectory(at: cache, withIntermediateDirectories: true);
        }
        return cache.appending(path: fileName);
    }
    
    private func load() {
        let path = self.cachePath;
        if FileManager().fileExists(atPath: path.path(percentEncoded: false)) {
            do {
                let data = try Data(contentsOf: path);
                if let contents = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String:Any] {
                    if let string = contents["recognisedText"] as? String {
                        self.pdfContent = string;
                    }
                    if let characterRectsData = contents["characterRects"] as? Data{
                        self.charRectsData = characterRectsData;
                    }
                }
            }
            catch {
                
            }
        }
    }
    
    func save() {
        guard !self.pdfContent.isEmpty, !self.characterRects.isEmpty else {
            return;
        }
        
        var dictRep = [String : Any]();
        dictRep["recognisedText"] = self.pdfContent
        dictRep["characterRects"] = NSDataValueConverter.data(withRectValuesArray: self.characterRects)
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: dictRep, format: .xml, options: 0);
            try data.write(to: self.cachePath, options: .atomic)
        }
        catch {
            
        }
    }
        
    func ranges(for searchKey: String) -> [CGRect] {
        let pdfString = pdfContent.lowercased();
        let lowerSearchKey = searchKey.lowercased();
        let ranges = pdfString.ranges(of:lowerSearchKey);
        var rectsToReturn = [CGRect]();
        if !ranges.isEmpty {
            let charRects = self.characterRects;
            let searchkeyLength = lowerSearchKey.count;
            for eachRange in ranges {
                let nsRange = NSRange(eachRange, in: pdfString);
                let index = nsRange.location;
                var rect = CGRect.null
                for i in 0..<searchkeyLength {
                    let rectindex = min(index + i,charRects.count-1);
                    rect = rect.union(charRects[rectindex]);
                }
                if !rect.isNull {
                    rectsToReturn.append(rect);
                }
            }
        }
        return rectsToReturn;
    }
}
