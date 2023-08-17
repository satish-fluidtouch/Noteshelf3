//
//  FTAppearanceView.swift
//  Noteshelf3
//
//  Created by Rakesh on 10/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI


struct FTAppearanceView: View {
    let viewModel = FTAppearanceViewModel()
    @AppStorage("Shelf_ShowDate") var showDateonShelf: Bool = false
    @State var theme: FTShelfTheme = UserDefaults.standard.shelfTheme;
    weak var delegate: FTAppearanceViewHostingControllerNavDelegate?

    var body: some View {
        ZStack {
            List {
                Section {
                    ForEach(FTShelfTheme.allThemes, id: \.self) { themeType in
                        FTThemeView(themeType: themeType,curTheme: $theme)
                            .frame(height: 44.0)
                    }
                }
                Section {
                    Toggle(viewModel.showDateonShelf, isOn: $showDateonShelf)
                        .frame(height: 44.0)
                        .padding(.horizontal,16)
                        .font(.appFont(for: .regular, with: 17))
                        .onChange(of: showDateonShelf) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "Shelf_ShowDate")
                            NotificationCenter.default.post(name: Notification.Name(rawValue: FTShelfShowDateChangeNotification), object: nil)
                        }
                        .toggleStyle(.switch)
                        .background(Color.appColor(.cellBackgroundColor))
                        .listRowInsets(EdgeInsets())
                }
            }
            .scrollContentBackground(.hidden)
#if !targetEnvironment(macCatalyst)
            .padding(.top,-35)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        self.delegate?.dismiss()
                    }
                    .font(.appFont(for: .regular, with: 17))
                    .foregroundColor(.appColor(.accent))
                }
            }
#else
            .padding(.top,-35+FTGlobalSettingsController.macCatalystTopInset)
#endif
        }
        .background(Color.appColor(.formSheetBgColor))
    }
}

private struct FTThemeView : View {
    var themeType: FTShelfTheme;
    @Binding var curTheme: FTShelfTheme;
    var isHighlighted = false;
    var body: some View {
        Button {
            curTheme = themeType;
            UserDefaults.standard.shelfTheme = curTheme;
        } label: {
            HStack {
                Text(themeType.localizedString)
                    .font(.appFont(for: .regular, with: 17))
                Spacer()
                if(curTheme == themeType) {
                    Image(icon: .checkmark)
//                        .foregroundColor(.black)
                }
            }
            .contentShape(Rectangle())
        }
        .frame(maxHeight: .infinity)
        .buttonStyle(.plain)
        .padding(.horizontal,16)
        .background(Color.appColor(.cellBackgroundColor))
        .listRowInsets(EdgeInsets())
    }
}

struct FTAppearanceView_Previews: PreviewProvider {
    static var previews: some View {
        FTAppearanceView()
    }
}

extension UserDefaults {
    var shelfTheme: FTShelfTheme {
        get {
            return FTShelfTheme(rawValue: UserDefaults.standard.integer(forKey: "Shelf_Theme")) ?? .System
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "Shelf_Theme")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ThemeChange"), object: nil,userInfo: ["theme":newValue]);
        }
    }
}

struct FTPrimaryButtonStyle: ButtonStyle {
    private var highlightColor: Color {
        let color = UIColor.lightGray.withAlphaComponent(0.5);
        return Color(uiColor: color);
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration
            .label
            .frame(maxWidth: .infinity,maxHeight: .infinity)
            .background(configuration.isPressed ? highlightColor : Color.clear)
    }
}
