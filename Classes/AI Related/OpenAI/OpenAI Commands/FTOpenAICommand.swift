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
    var content: FTPageContent = FTPageContent();
    var enteredContent: String = "";
    var commandToken: String = UUID().uuidString;
    
    private var contentToExecute: String {
        return self.content.content.appending(enteredContent);
    }

    func command() -> String {
        if commandType == .generalQuestion {
            return String(format: "noteshelf.ai.commandAskAnything".aiCommandString, contentToExecute,FTUtils.currentLanguageResponseCode());
        }
        return contentToExecute;
    }
        
    static func command(for command: FTOpenAICommandType,content:FTPageContent,enteredContent: String) -> FTAICommand {
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
        case .cleanUp:
            aiCommand = FTAICleanUpCommand();
        default:
            aiCommand = FTAICommand();
        }
        aiCommand.content = content;
        aiCommand.enteredContent = enteredContent;
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
        return contentToExecute;
    }
}

class FTAITranslateCommand: FTAICommand {
    var languageCode: String = "English"
    
    private var contentToExecute: String {
        return self.content.content;
    }

    override var responseType: FTAICommandResponseType {
        return .string;
    }
    
    override func command() -> String {
        return String(format: "noteshelf.ai.commandTranslate".aiCommandString, contentToExecute,languageCode);
    }
    
    override var placeholderMessage: String {
        return "noteshelf.ai.languagePlaceholder".aiLocalizedString;
    }
    
    override var executionMessage: String {
        return String(format: "noteshelf.ai.TranslateToPlaceHolder".aiLocalizedString, languageCode).appending(" \" \(contentToExecute.openAIDisplayString)\"")
    }
}

class FTAIKeyPointsCommand: FTAICommand {
    private var contentToExecute: String {
        return self.content.content;
    }

    override func command() -> String {
        return String(format: "noteshelf.ai.commandKeyPoints".aiCommandString, contentToExecute,FTUtils.currentLanguageResponseCode());
    }
    
    override var executionMessage: String {
        return "noteshelf.ai.generateNotesOn".aiLocalizedString.appending(" \" \(contentToExecute.openAIDisplayString)\"");
    }
}

class FTAISummarizeCommand: FTAICommand {
    private var contentToExecute: String {
        return self.content.content;
    }

    override func command() -> String {
        return String(format: "noteshelf.ai.commandSummarize".aiCommandString, contentToExecute,FTUtils.currentLanguageResponseCode());
    }
    
    override var executionMessage: String {
        return "noteshelf.ai.summarize".aiLocalizedString.appending(" \" \(contentToExecute.openAIDisplayString)\"");
    }
}

class FTAIExplainCommand: FTAICommand {
    private var contentToExecute: String {
        return self.content.content;
    }

    override func command() -> String {
        return String(format: "noteshelf.ai.commandExplain".aiCommandString, contentToExecute, FTUtils.currentLanguageResponseCode());
    }
    
    override var executionMessage: String {
        return "noteshelf.ai.explain".aiLocalizedString.appending(" \" \(contentToExecute.openAIDisplayString)\"");
    }
}

class FTAICleanUpCommand: FTAICommand {
    private var contentToExecute: String {
        return self.content.nonPDFContent;
    }
    
    override func command() -> String {
        return String(format: "noteshelf.ai.cleanupContent".aiCommandString, self.contentToExecute).appendingAILangugaeResponse;
    }
    
    override var executionMessage: String {
        return "Clean up in progress"
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
