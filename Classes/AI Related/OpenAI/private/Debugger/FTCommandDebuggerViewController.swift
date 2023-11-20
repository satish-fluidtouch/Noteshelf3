//
//  FTCommandDebuggerViewController.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 26/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import OpenAI

#if DEBUG || BETA
extension FTOpenAI {
    static var debugModel: Model = .gpt3_5Turbo;
}

extension FTAICommand {
    var debugCommand: String {
        get {
            if let command = UserDefaults.standard.string(forKey: "debug_command_\(self.commandType.rawValue)") {
                return command;
            }
            return self.command();
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "debug_command_\(self.commandType.rawValue)")
        }
    }
}

class FTCommandDebuggerViewController: UIViewController {
    @IBOutlet weak var textView: UITextView?;
    
    var aiCommand: FTAICommand?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView?.text = aiCommand?.debugCommand;
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneTapped(_:)))
        
        let menuItem = UIDeferredMenuElement{ items in
            var menuItems = [UIMenuElement]();
            let menu3o5Item = UIAction(title: .gpt3_5Turbo
                                       ,state: (FTOpenAI.debugModel == .gpt3_5Turbo) ? .on : .off ) { [weak self] _ in
                FTOpenAI.debugModel = .gpt3_5Turbo;
            }
            menuItems.append(menu3o5Item);

            let menu4Item = UIAction(title: .gpt4
                                     ,state: (FTOpenAI.debugModel == .gpt4) ? .on : .off) { [weak self] _ in
                FTOpenAI.debugModel = .gpt4;
            }
            menuItems.append(menu4Item);
            
            items(menuItems)
        }
        let barButton = UIBarButtonItem(title:"GPT Model", menu: UIMenu(children: [menuItem]));
        self.navigationItem.rightBarButtonItems = [doneButton,barButton]
    }
    
    @objc private func doneTapped(_ sender: Any?) {
        if let command = self.textView?.text,!command.isEmpty {
            self.aiCommand?.debugCommand = command;
        }
        self.dismiss(animated: true);
    }
}

extension FTNoteshelfAIViewController {
    func addDebugCommandButton() {
        var buttons = [UIBarButtonItem]();
        if let currentButton = self.navigationItem.rightBarButtonItem {
            buttons.append(currentButton);
        }
        if let rightBarButtons = self.navigationItem.rightBarButtonItems {
            buttons.append(contentsOf: rightBarButtons)
        }
        let barButton = UIBarButtonItem(title: "Clean-Up", style: .plain, target: self, action: #selector(self.showDebugCommandViewControlelr(_:)))
        buttons.append(barButton);
        
        self.navigationItem.rightBarButtonItems = buttons
    }
    
    @objc private func showDebugCommandViewControlelr(_ sender: Any?) {
        if let debugController = UIStoryboard.instantiateAIViewController(withIdentifier: "FTCommandDebuggerViewController") as? FTCommandDebuggerViewController {
            let command = FTAICleanUpCommand();
            command.commandType = .cleanUp;
            debugController.aiCommand = command;
            
            let navController = UINavigationController(rootViewController: debugController);
            self.present(navController, animated: true);
        }
    }
}
#endif
