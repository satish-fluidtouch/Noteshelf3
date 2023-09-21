//
//  FTOpenAICommand.swift
//  Sample AI
//
//  Created by Amar Udupa on 31/07/23.
//

import UIKit

private extension String  {
    var appendingAICommandSuffix: String {
        return self.appending("noteshelf.ai.commandSuffix".aiLocalizedString);
    }
}

class FTAICommand: NSObject {
    var commandType: FTOpenAICommandType = .none;
    var content: String = ""
    var commandToken: String = UUID().uuidString;
    
    func command() -> String {
        if commandType == .generalQuestion {
            return "noteshelf.ai.commandAskAnything".aiLocalizedString.appendingAICommandSuffix;
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
    override func command() -> String {
        return String(format: "noteshelf.ai.commandTranslate".aiLocalizedString, languageCode);
    }
    
    override var placeholderMessage: String {
        return "noteshelf.ai.languagePlaceholder".aiLocalizedString;
    }
    
    override var executionMessage: String {
        return String(format: "noteshelf.ai.commandTranslate".aiLocalizedString, languageCode).appending(" \" \(self.content.openAIDisplayString)\"")
    }
}

class FTAIKeyPointsCommand: FTAICommand {
    override func command() -> String {
        return "noteshelf.ai.commandKeyPoints".aiLocalizedString.appendingAICommandSuffix;
    }
    
    override var executionMessage: String {
        return "noteshelf.ai.generateNotesOn".aiLocalizedString.appending(" \" \(self.content.openAIDisplayString)\"");
    }
}

class FTAISummarizeCommand: FTAICommand {
    override func command() -> String {
        return "noteshelf.ai.commandSummarize".aiLocalizedString.appendingAICommandSuffix;
    }
    
    override var executionMessage: String {
        return "noteshelf.ai.summarize".aiLocalizedString.appending(" \" \(self.content.openAIDisplayString)\"");
    }
}

class FTAIExplainCommand: FTAICommand {
    override func command() -> String {
        return "noteshelf.ai.commandExplain".aiLocalizedString.appendingAICommandSuffix;
    }
    
    override var executionMessage: String {
        return "noteshelf.ai.explain".aiLocalizedString.appending(" \" \(self.content.openAIDisplayString)\"");
    }
}
