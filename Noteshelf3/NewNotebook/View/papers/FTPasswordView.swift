//
//  FTPasswordView.swift
//  Noteshelf3
//
//  Created by Narayana on 28/04/22.
//

import FTStyles
import SwiftUI
import FTNewNotebook

protocol FTPasswordViewDelegate: NSObject {
    func dismissPasswordView()
}
struct FTPasswordView: View {
    @StateObject var viewModel: FTPasswordViewModel
    @State private var pwd = ""
    @State private var hint = ""
    @State private var confirmPwd = ""
    @State private var useBiometric = false
    @State private var showAlert = false

    @FocusState private var pwdFocused
    @FocusState private var confirmPwdFocused
    @FocusState private var hintFocused
    weak var passwordDelegate: FTPasswordDelegate?
    weak var viewDelegate: FTPasswordViewDelegate?
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading,spacing:16) {
                    self.pwdMessageView
                    self.pwdTextFieldView
                    self.confirmPwdTextFieldView
                    self.hintView
                    self.footerView
                } .padding(.horizontal)
                    .padding(.bottom,16)
            }
            .toolbar {
                self.toolBar
            }
        }
        .background(.thickMaterial)
            .onAppear {
            }
            .alert("Alert", isPresented: $showAlert) {
            } message: {
                Text("Password and Confirm Password must be same")
            }
            .onAppear {
                self.pwd = viewModel.passwordDetails?.pin ?? ""
                self.hint = viewModel.passwordDetails?.hint ?? ""
                self.confirmPwd = viewModel.passwordDetails?.pin ?? ""
            }
    }

    private var pwdMessageView: some View {
        Text(viewModel.passwordInfo)
            .foregroundColor(Color.appColor(.black70))
            .appFont(for: .regular, with: 14)
            .multilineTextAlignment(.center)
            .padding(.top,4)
    }

    private var pwdTextFieldView: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            Text(viewModel.passwordText)
                .foregroundColor(.primary)
                .appFont(for: .regular, with: 17)

            SecureField(viewModel.passwordPlaceHolder, text: $pwd)
                .frame(height: 36.0)
                .ftTextFieldStyle()
                .focused($pwdFocused)
                .onSubmit {
                    self.confirmPwdFocused = true
                }
        }
    }

    private var confirmPwdTextFieldView: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            Text(viewModel.confirmPasswordText)
                .foregroundColor(.primary)
                .appFont(for: .regular, with: 17)

            SecureField(viewModel.passwordPlaceHolder, text: $confirmPwd)
                .frame(height: 36.0)
                .ftTextFieldStyle()
                .focused($confirmPwdFocused)
                .onSubmit {
                    self.hintFocused = true
                }
        }
    }

    private var hintView: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            Text(viewModel.hintText)
                .foregroundColor(.primary)
                .appFont(for: .regular, with: 17)

            TextField(viewModel.passwordPlaceHolder, text: $hint)
                .frame(height: 36.0)
                .ftTextFieldStyle()
                .focused($hintFocused)
        }
    }

    private var footerView: some View {
        VStack {
            if self.viewModel.toShowBiometricOption {
                self.biometricToggleView
                Divider()
                self.lockNotebooksToggleView
            } else {
                self.lockNotebooksToggleView
            }
        }.frame(height: self.viewModel.toShowBiometricOption ? 108.0 : 64)
            .background(Color.systemBackground)
            .cornerRadius(10.0)
    }

    private var biometricToggleView: some View {
        Toggle(isOn: $useBiometric) {
            Text(viewModel.biometricText)
                .foregroundColor(.primary)
                .appFont(for: .regular, with: 17)

        }.padding(.horizontal)
    }

    private var lockNotebooksToggleView: some View {
        Toggle(isOn: $viewModel.lockNotebooksInBg) {
            Text(viewModel.lockNotebooksInBgLocalisedText)
                .foregroundColor(.primary)
                .appFont(for: .regular, with: 17)

        }.padding(.horizontal)
    }

    @ToolbarContentBuilder
    private var toolBar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(viewModel.cancel) {
                self.viewDelegate?.dismissPasswordView()
                self.passwordDelegate?.didTapCancelPassword()
            }
            .foregroundColor(Color.appColor(.accent))
            .appFixedFont(for: .regular, with: isLargerTextEnabled(for: dynamicTypeSize) ? FTFontSize.largeSize : FTFontSize.regularSize)

        }
        ToolbarItem(placement: .principal) {
            Text(viewModel.passwordTitle)
                .foregroundColor(.primary)
                .font(.clearFaceFixedFont(for: .medium, with: 20))
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(viewModel.save) {
                if self.pwd  == self.confirmPwd {
                    self.viewDelegate?.dismissPasswordView()
                    self.passwordDelegate?.didTapSavePasswordWith(pin: self.pwd, hint: self.hint, useBiometric: self.useBiometric)
                } else {
                    self.showAlert = true
                }
            }
            .foregroundColor(Color.appColor(.accent).opacity(self.toEnableSave() ? 1.0 : 0.6))
            .appFixedFont(for: .regular, with: isLargerTextEnabled(for: dynamicTypeSize) ? FTFontSize.largeSize : FTFontSize.regularSize)
            .disabled(!self.toEnableSave())
        }
    }

    func toEnableSave() -> Bool {
        var toEnableSave = false
        if !self.pwd.isEmpty && !self.confirmPwd.isEmpty && !self.hint.isEmpty {
            toEnableSave = true
        }
        return toEnableSave
    }
}
