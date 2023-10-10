//
//  FTOpenAI.swift
//  Sample AI
//
//  Created by Amar Udupa on 31/07/23.
//

import UIKit
import OpenAI

class FTOpenAI: NSObject {
    private static let OPEN_API_TOKEN = "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";
//    private static let OPEN_API_TOKEN = "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";

    private lazy var openAI: OpenAI = {
        return OpenAI(apiToken: FTOpenAI.OPEN_API_TOKEN);
    }();
    static let shared = FTOpenAI();
    
    func execute(command: FTAICommand
                 ,onUpdate: @escaping ((FTOpenAIResponse,Error?,_ token: String) -> (Void))
                 ,onCompletion: @escaping  ((Error?,_ token:String) -> (Void))) {
        
        let commandString: String = command.command();
        let response = FTOpenAIResponse();
        var messages = [Chat]();
        messages.append(Chat(role: .user, content: commandString));
        
        var targettedError: Error?;
        let query = ChatQuery(model: .gpt3_5Turbo, messages: messages,temperature: 0.2)
        openAI.chatsStream(query: query) { partialResult in
            switch partialResult {
            case .success(let result):
                if let content = result.choices.first?.delta.content {
                    if command.responseType == .html {
                        response.appendHtmlResponse(content);
                    }
                    else {
                        response.appendStringRessponse(content);
                    }
                }
                DispatchQueue.main.async {
                    onUpdate(response, nil,command.commandToken);
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    targettedError = error;
                    onUpdate(response,error,command.commandToken);
                }
            }
        } completion: { error in
            DispatchQueue.main.async {
                if nil != error {
                    targettedError = error;
                }
                onCompletion(targettedError,command.commandToken);
            }
        };
    }
}
