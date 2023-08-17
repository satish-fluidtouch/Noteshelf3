//
//  FTQuotesProvider.swift
//  Template Generator
//
//  Created by sreenu cheedella on 27/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

class FTQuoteInfo: NSObject {
    var quote : String = "";
    var author : String = "";
}

class FTQuotesProvider: NSObject {

//    static let shared = FTQuotesProvider();
    
    private var quotesArray : [[String : String]] = [[String : String]]();
    func getQutote() -> FTQuoteInfo {
        if(quotesArray.isEmpty) {
            self.loadQuotes();
        }
        let currentIndex = Int.random(in: 0...quotesArray.count-1)
        let quote = quotesArray[currentIndex];
        quotesArray.remove(at: currentIndex)
        let quoteInfo = FTQuoteInfo.init();
        quoteInfo.quote = quote["Quote"] ?? "No Quote";
        quoteInfo.author = quote["Author"] ?? "No Name";
        return quoteInfo;
    }
    
    private func loadQuotes() {
        if let fileURL = Bundle.main.url(forResource: "Quotes", withExtension: "plist") {
            quotesArray = NSArray.init(contentsOf: fileURL) as! [[String:String]];
        }
    }
}
