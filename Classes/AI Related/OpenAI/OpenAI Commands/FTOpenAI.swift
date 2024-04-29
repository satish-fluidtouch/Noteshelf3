//
//  FTOpenAI.swift
//  Sample AI
//
//  Created by Amar Udupa on 31/07/23.
//

import UIKit
import OpenAI
import Reachability

class FTOpenAI: NSObject {
    private static let OPEN_API_TOKEN = "iNjifsU5TqNBH1nmsgW5/8qFS4Z/wq3+qYU6rk2UwsOAEklKL3/HEcUOWs2wWGrZdz+Mg4HNulwj6nhzMd4YFg==";
//    private static let OPEN_API_TOKEN = "4+FtplzHDydfBYWfA394OmfY9A6JjNNzZ1DSzYxTwKVEpqq2hUpYgX15qjQd7LSxk5fWlcxI4aWfAJo/emgffA==";

    private lazy var openAI: OpenAI = {
        //Generate Encrypted key by adding proper one to Open api token
        //Once generated store the encrupted key as a value to the same
        //going forward use the encrypted key as a token
        //let encryptedKey = FTUtils.encryptString(FTOpenAI.OPEN_API_TOKEN, allowDefaultValue: false, privateKey: nil)
        let decryptedKey = FTUtils.decryptString(FTOpenAI.OPEN_API_TOKEN, allowDefaultValue: false, privateKey: nil)
        return OpenAI(apiToken: decryptedKey ?? "");
    }();
    static let shared = FTOpenAI();
    private var currentcommand: FTAICommand?;
    
    
    func execute(command: FTAICommand
                 ,onUpdate: @escaping ((FTOpenAIResponse,Error?,_ token: String) -> (Void))
                 ,onCompletion: @escaping  ((Error?,_ token:String) -> (Void))) {
        
        guard let connection = Reachability.forInternetConnection(),connection.currentReachabilityStatus() != NetworkStatus.NotReachable  else {
            onCompletion(FTOPenAIError.noInternetConnection,command.commandToken);
            return;
        }
        
        currentcommand = command;
        
#if DEBUG || BETA
        let commandString: String = command.debugCommand;
#else
        let commandString: String = command.command();
#endif
        let response = FTOpenAIResponse();
        var messages = [ChatQuery.ChatCompletionMessageParam]();
        if let msg = ChatQuery.ChatCompletionMessageParam(role: ChatQuery.ChatCompletionMessageParam.Role.system, content: commandString) {
            messages.append(msg);
        }
        else {
            FTLogError("OPENAI-system-msg faile")
        }
        if let msg1 = ChatQuery.ChatCompletionMessageParam(role: ChatQuery.ChatCompletionMessageParam.Role.user, content: command.contentToExecute) {
            messages.append(msg1);
        }
        else {
            FTLogError("OPENAI-user-msg faile")
        }
        var targettedError: Error?;
#if DEBUG || BETA
        let query = ChatQuery(messages: messages, model: FTOpenAI.debugModel,temperature: 0.2)
#else
        let query = ChatQuery(messages: messages, model: .gpt3_5Turbo,temperature: 0.2)
#endif
        openAI.chatsStream(query: query) { partialResult in
            guard self.currentcommand == command else {
                return;
            }
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
                    FTLogError("OpenAI-Error", attributes: ["reason": error.localizedDescription])
                    onUpdate(response,error,command.commandToken);
                }
            }
        } completion: { error in
            DispatchQueue.main.async {
                if let _error = error {
                    targettedError = _error;
                    FTLogError("OpenAI-Error", attributes: ["reason": _error.localizedDescription])
                }
                onCompletion(targettedError,command.commandToken);
            }
        };
    }
    
    func cancelCurrentExecution() {
        self.currentcommand = nil;
    }
}

struct FTOPenAIError {
    static let noInternetConnection: NSError = NSError(domain: "FTOpenAI", code: Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue), userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("NoInternetConnection", comment: "No Internet Connection")]);
    
    static func isNoInternetConnectionError(_ error:NSError) -> Bool {
        return (error.domain == "FTOpenAI" && error.code == Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue));
    }
}
