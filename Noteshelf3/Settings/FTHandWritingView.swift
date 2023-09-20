//
//  FTHandWritingView.swift
//  Noteshelf3
//
//  Created by Rakesh on 09/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

struct FTHandWritingView: View {
    @Environment(\.dismiss) var dismiss
    @State var selecteStyle:WrittingSyle = WrittingSyle.rightTop
    @EnvironmentObject var premiumUser: FTPremiumUser;
    @EnvironmentObject var viewModel: FTHandWringViewModel;

    let columns = [
        GridItem(.fixed(133)),
        GridItem(.fixed(133))
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Section(header:Text("shelf.settings.handWritingRecognition".localized).sectionHeaderStyle()){
                Button {
                    self.viewModel.delegate?.pushScreen()
                } label: {
                    LabeledContent {
                        HStack(spacing: 4.0){
                            Text(FTLanguageResourceManager.shared.currentLanguageDisplayName)
                                .foregroundColor(Color.appColor(.accent))
                            Image(icon: FTIcon.rightArrow)
                                .foregroundColor(Color.appColor(.gray1))
                                .frame(width: 10,height: 24)
                                .fixedSize(horizontal: true, vertical: true)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text("Language".localized)
                                .foregroundColor(Color.label)
                            if !premiumUser.isPremiumUser {
                                Image("premium_dynamic", bundle: nil)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 24)
                                Spacer()
                            }
                        }
                    }
                }
                .sectionitemStyle()
            }
            Section(header:Text("shelf.settings.WritingStyle".localized)
                .sectionHeaderStyle()
                .padding(.top,16),
                    footer:
                        Text("shelf.settings.handWritingDescrption".localized)
                        .sectionFooterStyle()
                        .padding(.top,8)){
                ScrollView{
                    LazyVGrid(columns:columns, alignment: .center, spacing:24) {
                        ForEach(WrittingSyle.allCases, id: \.self) { style in
                            Button(action: {
                                selecteStyle = style
                                let selectedStyleInt:Int
                                switch selecteStyle{
                                case .leftdown:
                                    selectedStyleInt =  0
                                case .rightDown:
                                    selectedStyleInt =  1
                                case .leftStrait:
                                    selectedStyleInt =  2
                                case .rightStrait:
                                    selectedStyleInt =  3
                                case .leftTop:
                                    selectedStyleInt =  4
                                case .rightTop:
                                    selectedStyleInt =  5
                                }
                                self.updateStyle(selectedStyleInt)

                                NotificationCenter.default.post(name: Notification.Name(rawValue: "FTWritingStyleChanged"), object: nil)
                                self.updateDisplay()
                                track("Shelf_Settings_HandwritingRecognition", params: [:], screenName: FTScreenNames.shelfSettings)
                            }, label: {
                                Image(selecteStyle == style ? selecteStyle.selectedModeImageName : style.normalModeImageName)
                                    .frame(width: 85,height: 97)
                            })
                            .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: 0.93))
                        }
                    }
                    .padding(.vertical,32)
                }
                .frame(height: 403)
                .background(Color.appColor(.cellBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .scrollDisabled(true)
            }
            Spacer()
        }
        .padding(.horizontal,24)
        .background(Color.appColor(.formSheetBgColor))
#if !targetEnvironment(macCatalyst)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done".localized) {
                    self.viewModel.delegate?.dismiss()
                }
                .font(.appFont(for: .regular, with: 17))
                .foregroundColor(.appColor(.accent))
            }
        }
#endif
        .onAppear{
            self.updateDisplay()
        }
    }
    private func updateDisplay() {
        let style = self.getWritingStyle()
        switch style{
        case 0:
            selecteStyle = .leftdown
        case 1:
            selecteStyle = .rightDown
        case 2:
            selecteStyle = .leftStrait
        case 3:
            selecteStyle = .rightStrait
        case 4:
            selecteStyle = .leftTop
        case 5:
            selecteStyle = .rightTop
        default:
            selecteStyle = .rightTop
        }
    }

    private func updateStyle(_ styleIndex: Int) {
        let standardUserDefaults = UserDefaults.standard
        standardUserDefaults.set(styleIndex, forKey: WRITING_STYLE_SELECTED)
        standardUserDefaults.synchronize()
    }

    private func getWritingStyle() -> Int {
        return UserDefaults.standard.integer(forKey: WRITING_STYLE_SELECTED)
    }
}

struct FTHandWritingView_Previews: PreviewProvider {
    static var previews: some View {
        FTHandWritingView()
    }
}
struct SectionHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appFont(for: .medium, with: 13))
            .foregroundColor(.appColor(.black50))
            .padding(.leading)
            .padding(.bottom,4)
    }
}

extension View {
    func sectionHeaderStyle() -> some View {
        self.modifier(SectionHeaderModifier())
    }
}

struct SectionFooterModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appFont(for: .regular, with: 12))
            .foregroundColor(.appColor(.black50))
    }
}

extension View {
    func sectionFooterStyle() -> some View {
        self.modifier(SectionFooterModifier())
    }
}

struct SectionItemModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 44)
            .padding(.leading,16)
            .padding(.trailing,10)
            .background(Color.appColor(.cellBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

extension View {
    func sectionitemStyle() -> some View {
        self.modifier(SectionItemModifier())
    }
}

