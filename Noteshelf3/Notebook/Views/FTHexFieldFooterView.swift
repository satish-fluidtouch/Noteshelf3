//
//  FTHexFieldFooterView.swift
//  Noteshelf3
//
//  Created by Narayana on 06/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTHexFieldFooterView: View {
    @State var hexChangeToBeObserved: Bool = false
    @Binding var colorSelectModeImage: FTPenColorSelectModeImage

    var colorMode: FTPenColorMode

    @EnvironmentObject var hexInputVm: FTColorHexInputViewModel
    @EnvironmentObject var viewModel: FTPenShortcutViewModel

    var body: some View {
        HStack(spacing: FTSpacing.zero) {
            Text("#")
                .padding(.leading)
                .padding(.trailing, FTSpacing.zero)
            TextField("",
                      text: $hexInputVm.text)
            .padding(.leading, FTSpacing.zero)
            .onChange(of: self.hexInputVm.text) { currentHex in
                if let reqHex = self.getRequiredHex(currentHex: currentHex), hexChangeToBeObserved {
                    self.viewModel.updateCurrentSelection(colorHex: reqHex)
                }
                hexChangeToBeObserved = true
            }
            .onSubmit {
                if let reqHex = self.getRequiredHex(currentHex: self.hexInputVm.text) {
                    self.hexInputVm.text = reqHex
                } else {
                    self.hexInputVm.text = self.viewModel.currentSelectedColor
                }
            }

            Spacer()

            VStack {
            }
            .frame(width: 97.0, height: 23.0)
            .background(Color(hex: self.viewModel.currentSelectedColor))
            .cornerRadius(6.0)
            .shadow(color: Color.appColor(.black4), radius: 1, x: 0.0, y: 3.0)
            .shadow(color: Color.appColor(.black3), radius: 1, x: 0.0, y: 3.0)
            .padding(.trailing, FTSpacing.small)

            if colorMode == .select {
                Image(systemName: colorSelectModeImage.rawValue)
                    .foregroundColor(Color.appColor(.accent))
                    .onTapGesture {
                        if colorSelectModeImage == .add {
                            self.viewModel.addSelectedColorToPresets()
                            self.viewModel.updateCurrentColors()
                            colorSelectModeImage = .done
                        }
                    }
            } else {
                Image(systemName: "eyedropper")
                    .foregroundColor(Color.appColor(.accent))
                    .font(Font.appFont(for: .regular, with: 16.0))
                    .onTapGesture {
                        self.viewModel.didTapOnColorEyeDropper()
                    }
            }
            Spacer()
                .frame(width: 8.0)
        }
        .frame(width: 288.0, height: 36.0)
        .background(Color.appColor(.gray60).opacity(0.12))
        .cornerRadius(10.0)
        .padding(.horizontal)
    }

    private func getRequiredHex(currentHex: String) -> String? {
        if currentHex.count == 6 {
            return currentHex
        } else {
            var reqHex: String = currentHex
            if (currentHex.count > 3) {
                reqHex = (reqHex as NSString).substring(from: 1)
                let uiColor = UIColor(hexString: reqHex)
                reqHex = uiColor.hexString
                return reqHex
            }
            return nil
        }
    }
}

enum FTPenColorSelectModeImage: String {
    case add = "plus.circle.fill"
    case done = "checkmark.circle.fill"
}
