//
//  FTNoteshelfAITranslateViewController.swift
//  Sample AI
//
//  Created by Amar Udupa on 28/07/23.
//

import UIKit

enum FTTranslateOption: Int,CaseIterable {
    case engish,german,french,italian,japanese,spanish,korean,chineseSimplified,chineseTraditional;
    
    static func languageOption(title: String) -> FTTranslateOption? {
        switch title.openAITrim().lowercased() {
        case FTTranslateOption.engish.title.lowercased():
            return FTTranslateOption.engish;
        case FTTranslateOption.german.title.lowercased():
            return FTTranslateOption.german;
        case FTTranslateOption.french.title.lowercased():
            return FTTranslateOption.french;
        case FTTranslateOption.italian.title.lowercased():
            return FTTranslateOption.italian;
        case FTTranslateOption.japanese.title.lowercased():
            return FTTranslateOption.japanese;
        case FTTranslateOption.spanish.title.lowercased():
            return FTTranslateOption.spanish;
        case FTTranslateOption.korean.title.lowercased():
            return FTTranslateOption.korean;
        case FTTranslateOption.chineseSimplified.title.lowercased():
            return FTTranslateOption.chineseSimplified;
        case FTTranslateOption.chineseTraditional.title.lowercased():
            return FTTranslateOption.chineseTraditional;
        default:
            return nil;
        }
    }
    
    var title: String {
        switch self {
        case .engish:
            return "English";
        case .german:
            return "German";
        case .french:
            return "French";
        case .italian:
            return "Italian";
        case .japanese:
            return "Japanese";
        case .spanish:
            return "Spanish";
        case .korean:
            return "Korean";
        case .chineseSimplified:
            return "Chinese Simplified";
        case .chineseTraditional:
            return "Chinese Traditional";
        }
    }
    
    var displayTitle: String {
        switch self {
        case .engish:
            return "noteshelf.ai.translateToEnglish".aiLocalizedString;
        case .german:
            return "noteshelf.ai.translateToGerman".aiLocalizedString;
        case .french:
            return "noteshelf.ai.translateToFrench".aiLocalizedString;
        case .italian:
            return "noteshelf.ai.translateToItalian".aiLocalizedString;
        case .japanese:
            return "noteshelf.ai.translateToJapanese".aiLocalizedString;
        case .spanish:
            return "noteshelf.ai.translateToSpanish".aiLocalizedString;
        case .korean:
            return "noteshelf.ai.translateToKorean".aiLocalizedString;
        case .chineseSimplified:
            return "noteshelf.ai.translateToChineseSimplified".aiLocalizedString;
        case .chineseTraditional:
            return "noteshelf.ai.translateToChineseTraditional".aiLocalizedString;
        }
    }

    var supportsHandWritingRecognition: Bool {
        switch self {
        case .engish,.french,.german,.italian,.spanish:
            return true;
        default:
            return false;
        }
    }
}

protocol FTNoteshelfAITranslateViewControllerDelegate: NSObjectProtocol {
    func translateController(_ controller: FTNoteshelfAITranslateViewController,didSelectLanguage language: FTTranslateOption);
}

private class FTAITranslateTableViewCell: UITableViewCell {
    static let cellIdentifier = "FTAITranslateTableViewCell";
}

class FTNoteshelfAITranslateViewController: UIViewController {
    weak var delegate: FTNoteshelfAITranslateViewControllerDelegate?
    @IBOutlet private weak var aiTableView: UITableView?;

    override func viewDidLoad() {
        super.viewDidLoad()
        self.aiTableView?.layer.cornerRadius = 10.0
        self.aiTableView?.register(FTAITranslateTableViewCell.self, forCellReuseIdentifier: FTAITranslateTableViewCell.cellIdentifier);
    }
}

extension FTNoteshelfAITranslateViewController: UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: FTAITranslateTableViewCell.cellIdentifier, for: indexPath);
        tableCell.backgroundColor = UIColor.appColor(.cellBackgroundColor);
        return tableCell;
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let optioncell = cell as? FTAITranslateTableViewCell, let aitoption = FTTranslateOption(rawValue: indexPath.row) {
            optioncell.contentView.backgroundColor = UIColor.appColor(.cellBackgroundColor);
            optioncell.textLabel?.text = aitoption.displayTitle;
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FTTranslateOption.allCases.count;
    }
     
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        if let aitoption = FTTranslateOption(rawValue: indexPath.row) {
            self.delegate?.translateController(self, didSelectLanguage: aitoption);
        }
    }
}
