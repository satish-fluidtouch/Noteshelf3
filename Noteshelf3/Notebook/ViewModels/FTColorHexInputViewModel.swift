//
//  FTColorHexInputViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 26/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import Combine
import FTCommon

class FTColorHexInputViewModel: ObservableObject {
    @Published var text: String = ""
    private var subCancellable: AnyCancellable!
    private var validCharSet = CharacterSet(charactersIn: "#0123456789abcdefABCDEF")

    init() {
        subCancellable = $text.sink { val in
            //check if the new string contains any invalid characters
            if val.rangeOfCharacter(from: self.validCharSet.inverted) != nil {
                //clean the string (do this on the main thread to avoid overlapping with the current ContentView update cycle)
                runInMainThread {
                    self.text = String(self.text.unicodeScalars.filter {
                        self.validCharSet.contains($0)
                    })
                }
            } else {
                    if val.count > 6 {
                        runInMainThread {
                            self.text = String(self.text.prefix(6)).uppercased()
                        }
                    }
            }
        }
    }

    deinit {
        subCancellable.cancel()
    }
}
