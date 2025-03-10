//
//  FTEditableView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/04/22.
//

import FTStyles
import SwiftUI
import FTCommon

struct FTEditableView: View {
    @EnvironmentObject var item: FTSideBarItem
    var placeHolder: String
    var onButtonSubmit: (_ title:String)-> Void?
    let useTextfieldForEditing: Bool = false
    let keyboardHideNotification = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
    @FocusState private var titleIsFocused: Bool
    @State var showEditableField: Bool = false
    @State var textFieldText: String = ""
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var viewModel: FTSidebarViewModel

    var body: some View {
                Label {
                    HStack {
                        if showEditableField {
                            TextField(placeHolder, text: $textFieldText)
                                .font(.appFont(for: .regular, with: 17))
                                .focused($titleIsFocused)
                                .foregroundColor(.appColor(.black1))
                                .onSubmit {
                                    didTapSubmitOrKeyboardHideOption()
                                }
                                .onAppear {
                                    runInMainThread(0.2) {
                                        self.titleIsFocused = true
                                    }
                                }
                        } else {
                            HStack(alignment: .center) {
                                Text(NSLocalizedString("NewCategory", comment: "New Category"))
                                    .appFont(for: .regular, with: 17)
                                    .foregroundColor(.appColor(.black1))
                                Spacer()
                            }
                            .frame(height: 44,alignment:.leading)
                            .contentShape(Rectangle())
                            .if(!showEditableField) { view in
                                view.onTapGesture {
                                    viewModel.endEditingActions()
                                    showEditableField = true
                                    track(EventName.sidebar_addnewcategory_tap, screenName: ScreenName.sidebar)
                                }
                            }
                        }
                    }
                    .frame(height: 44,alignment:.leading)
                } icon: {
                if item.isEditing {
                    Image(icon:item.type == .category ? FTIcon.folder : FTIcon.number )
                            .frame(width: 24, height: 24, alignment: SwiftUI.Alignment.center)
                            .padding(.trailing,4)
                            .font(Font.appFont(for: .regular, with: 20))
                            .foregroundColor(.appColor(.black1))
                } else {
                    Image(icon: FTIcon.plusCircle)
                        .frame(width: 24, height: 24, alignment: SwiftUI.Alignment.center)
                        .font(Font.appFont(for: .regular, with: 20))
                        .foregroundColor(.appColor(.black1))
                        .padding(.trailing,4)
                        .onTapGesture {
                            showEditableField = true
                        }
                }
            }
        .onReceive(keyboardHideNotification) { _ in
            didTapSubmitOrKeyboardHideOption()
        }
    }
    private func didTapSubmitOrKeyboardHideOption(){
        let isTextEmpty = textFieldText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
        if !isTextEmpty, item.type != .addnewCategory {
            item.title = textFieldText
        }
        self.onButtonSubmit(textFieldText)
        textFieldText = ""
        showEditableField = false
    }
}
