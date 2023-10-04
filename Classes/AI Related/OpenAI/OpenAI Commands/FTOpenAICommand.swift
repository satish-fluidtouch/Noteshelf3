//
//  FTOpenAICommand.swift
//  Sample AI
//
//  Created by Amar Udupa on 31/07/23.
//

import UIKit

private extension String  {
    var appendingAICommandSuffix: String {
        let stringToReturn =  self.appending("noteshelf.ai.commandSuffix".aiCommandString);
        return stringToReturn.appendingAILangugaeResponse;
    }
    
    var appendingAILangugaeResponse: String {
        return self.appendingFormat("noteshelf.ai.commandLanguageSuffix".aiCommandString, FTUtils.currentLanguageResponseCode());
    }
}

enum FTAICommandResponseType: Int {
    case html,string;
}

class FTAICommand: NSObject {
    var responseType: FTAICommandResponseType {
        return .html;
    }

    var commandType: FTOpenAICommandType = .none;
    var content: String = ""
    var commandToken: String = UUID().uuidString;
    
    func command() -> String {
        if commandType == .generalQuestion {
            return "noteshelf.ai.commandAskAnything".aiCommandString.appendingAICommandSuffix;
        }
        return "";
    }
        
    static func command(for command: FTOpenAICommandType,content:String) -> FTAICommand {
        let aiCommand: FTAICommand;
        switch command {
        case .explain:
            aiCommand = FTAIExplainCommand();
        case .summarize:
            aiCommand = FTAISummarizeCommand();
        case .generateNotes:
            aiCommand = FTAIKeyPointsCommand();
        case .langTranslate:
            aiCommand = FTAITranslateCommand();
        default:
            aiCommand = FTAICommand();
        }
        aiCommand.content = content;
        aiCommand.commandType = command;
        return aiCommand;
    }
    
    var placeholderMessage: String {
        return commandType.placeholderMessage
    }
    
    var executionMessage:String {
        if commandType == .none {
            return "";
        }
        return self.content;
    }
}

class FTAITranslateCommand: FTAICommand {
    var languageCode: String = "English"
    
    override var responseType: FTAICommandResponseType {
        return .string;
    }
    
    override func command() -> String {
        return String(format: "noteshelf.ai.commandTranslate".aiCommandString, languageCode);
    }
    
    override var placeholderMessage: String {
        return "noteshelf.ai.languagePlaceholder".aiLocalizedString;
    }
    
    override var executionMessage: String {
        return String(format: "noteshelf.ai.TranslateToPlaceHolder".aiLocalizedString, languageCode).appending(" \" \(self.content.openAIDisplayString)\"")
    }
}

class FTAIKeyPointsCommand: FTAICommand {
    override func command() -> String {
        return "noteshelf.ai.commandKeyPoints".aiCommandString.appendingAICommandSuffix;
    }
    
    override var executionMessage: String {
        return "noteshelf.ai.generateNotesOn".aiLocalizedString.appending(" \" \(self.content.openAIDisplayString)\"");
    }
}

class FTAISummarizeCommand: FTAICommand {
    override func command() -> String {
        return "noteshelf.ai.commandSummarize".aiCommandString.appendingAICommandSuffix;
    }
    
    override var executionMessage: String {
        return "noteshelf.ai.summarize".aiLocalizedString.appending(" \" \(self.content.openAIDisplayString)\"");
    }
}

class FTAIExplainCommand: FTAICommand {
    override func command() -> String {
        return "noteshelf.ai.commandExplain".aiCommandString.appendingAICommandSuffix;
    }
    
    override var executionMessage: String {
        return "noteshelf.ai.explain".aiLocalizedString.appending(" \" \(self.content.openAIDisplayString)\"");
    }
}

private extension FTUtils {
    static func currentLanguageResponseCode() -> String {
        let curlang = FTUtils.currentLanguage();
        switch curlang.lowercased() {
        case "en":
            return "English";
        case "es":
            return "Spanish";
        case "jp":
            return "Japanese";
        case "zh-Hans":
            return "Chinese Simplified";
        case "zh-Hant":
            return "Chinese Traditional";
        case "ko":
            return "Korean";
        case "it":
            return "Italian";
        case "fr":
            return "French";
        case "de":
            return "German";
        default:
            return "English";
        }
    }
}
