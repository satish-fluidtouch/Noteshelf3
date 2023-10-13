//
//  FTOpenAICommandType.swift
//  Sample AI
//
//  Created by Amar Udupa on 31/07/23.
//

import UIKit

enum FTOpenAICommandType: Int {
    static let supportedCommands̉: [FTOpenAICommandType] = [.generateNotes,.summarize,.explain,.langTranslate]; //.cleanUp
    case summarize,explain,generateNotes,langTranslate,generalQuestion,cleanUp,none
    
    var placeholderMessage: String {
        switch self {
        case .langTranslate:
            return "noteshelf.ai.languagePlaceholder".aiLocalizedString;
        case .explain:
            return "noteshelf.ai.explain".aiLocalizedString;
        case .generateNotes:
            return "noteshelf.ai.generateNotesOn".aiLocalizedString;
        case .summarize:
            return "noteshelf.ai.summarize".aiLocalizedString;
        case .cleanUp:
            return "Clean up";
        case .none:
            return "noteshelf.ai.askAnything".aiLocalizedString
        default:
            return "noteshelf.ai.enterTopic".aiLocalizedString;
        }
    }
    
    var placeHolderContent: String {
        switch self {
        case .langTranslate:
            return "noteshelf.ai.languagePlaceholder".aiLocalizedString;
        case .explain:
            return "noteshelf.ai.explain".aiLocalizedString;
        case .generateNotes:
            return "noteshelf.ai.generateNotesOn".aiLocalizedString;
        case .summarize:
            return "noteshelf.ai.summarize".aiLocalizedString;
        case .cleanUp:
            return "Provide content";
        default:
            return "noteshelf.ai.provideContent".aiLocalizedString;
        }
    }
    
    var image: UIImage {
        switch self {
        case .generateNotes:
            return UIImage(named: "generate") ?? UIImage();
        case .summarize:
            return UIImage(named: "summary") ?? UIImage();
        case .explain:
            return UIImage(named: "explain") ?? UIImage();
        case .langTranslate:
            return UIImage(named: "translate") ?? UIImage();
        case .cleanUp:
            return UIImage(named: "generate") ?? UIImage();
        default:
            return UIImage();
        }
    }
    
    func title(content: String) -> String {
        switch self {
        case .generateNotes:
            if content.isEmpty {
                return "noteshelf.ai.generateNotes".aiLocalizedString;
            }
            return "noteshelf.ai.generateNotesOn".aiLocalizedString;
        case .summarize:
            return "noteshelf.ai.summarize".aiLocalizedString;
        case .explain:
            return "noteshelf.ai.explain".aiLocalizedString;
        case .langTranslate:
            return "noteshelf.ai.translate".aiLocalizedString;
        case .cleanUp:
            return "Clean Up: ";
        default:
            return "";
        }
    }

}
