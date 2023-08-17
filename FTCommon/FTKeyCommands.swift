//
//  FTKeyCommands.swift
//  FTCommon
//
//  Created by Amar on 21/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc public protocol FTKeyCommandAction: NSObjectProtocol {
    @objc optional func didTapOnClose(_ sender: UIKeyCommand);
    @objc optional func didTapMoveNextPage(_ sender: UIKeyCommand);
    @objc optional func didTapMovePreviousPage(_ sender: UIKeyCommand);
}

public class FTKeyCommand: NSObject {
    public  static var closeModalWindow: UIKeyCommand {
        let commnand = UIKeyCommand(input: UIKeyCommand.inputEscape
                                    , modifierFlags: UIKeyModifierFlags()
                                    , action: #selector(FTKeyCommandAction.didTapOnClose(_:)));
        commnand.wantsPriorityOverSystemBehavior = true;
        return commnand;
    }
    
    public  static func nextPage(_ mdoifier: UIKeyModifierFlags = UIKeyModifierFlags()) -> UIKeyCommand {
        let commnand = UIKeyCommand(input: UIKeyCommand.inputRightArrow
                                    , modifierFlags: mdoifier
                                    , action: #selector(FTKeyCommandAction.didTapMoveNextPage(_:)));
        commnand.wantsPriorityOverSystemBehavior = true;
        return commnand;
    }
    
    public  static func previousPage(_ mdoifier: UIKeyModifierFlags = UIKeyModifierFlags()) -> UIKeyCommand {
        let commnand = UIKeyCommand(input: UIKeyCommand.inputLeftArrow
                                    , modifierFlags: mdoifier
                                    , action: #selector(FTKeyCommandAction.didTapMovePreviousPage(_:)));
        commnand.wantsPriorityOverSystemBehavior = true;
        return commnand;
    }

}
