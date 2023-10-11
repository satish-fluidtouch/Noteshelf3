//
//  FTSettingsAboutView.swift
//  Noteshelf3
//
//  Created by Rakesh on 17/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import SafariServices

struct FTSettingsAboutView: View {

    weak var delegate: FTAboutNoteShelfViewHostingControllerNavDelegate?
    @ObservedObject var viewModel: FTSettingsAboutViewModel
    @State private var isShowingWebView: Bool = false

    @State private var selectedStyle: SocialMediaTypes?
    @State private var aboutNoteshelfOption: FTAboutNoteshelfOptions?
    @State private var showWebview: Bool = false
    @State private var showWelcome: Bool = false


    let columns = [
        GridItem(.flexible())
    ]

    var body: some View {
        GeometryReader{ proxy in
            ScrollView {
                headerSection
                
                middleSection
                
                footerSection
            }
            .frame(width: proxy.size.width,height: proxy.size.height)
            .background(Color.appColor(.formSheetBgColor))
        }
#if !targetEnvironment(macCatalyst)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done".localized) {
                    self.delegate?.dismiss()
                }
                .font(.appFont(for: .regular, with: 17))
                .foregroundColor(.appColor(.accent))
            }
        }
#endif
    }

    @ViewBuilder
    private var headerSection: some View{
        VStack(alignment: .center,spacing: 0){
            Image(uiImage: Bundle.main.icon ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: 128,height: 128)
                .cornerRadius(32)
                .padding(.vertical,16)

            Text(viewModel.headerTopTitle)
                .font(.clearFaceFont(for: .medium, with: 34))
                .padding(.bottom,4)
            Text(viewModel.headerdescription)
                .font(.appFont(for: .regular, with: 17))
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .padding(.horizontal,25.5)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .center, spacing: 4){
                    Text(viewModel.versionnumber)
                    Text(viewModel.userid)
            }
            .foregroundColor(Color.label).opacity(0.7)
            .font(.appFont(for: .regular, with: 13))
            .padding(.top,16)
        }
    }

    @ViewBuilder
    private var middleSection: some View{
        VStack(alignment: .leading, spacing: 0) {
            aboutNoteshelfOption(option: .visitWebsite)

            FTDividerLine()

            aboutNoteshelfOption(option: .privacyPolicy)
                .if(aboutNoteshelfOption != nil, transform: { view in
                    view.fullScreenCover(isPresented: $isShowingWebView) {
                        if let aboutNoteshelfOption = aboutNoteshelfOption, let url = URL(string: aboutNoteshelfOption.webUrl) {
                            SafariView(url: url)
                        }
                    }
                })
#if !RELEASE && !targetEnvironment(macCatalyst)
            FTDividerLine()
            
            Button {
                showWelcome = true
            } label: {
                LabeledContent {
                    Image(icon: .rightArrow)
                        .foregroundColor(Color.label).opacity(0.5)
                } label: {
                    Text(viewModel.welcomeTourText)
                }
            }
            .macOnlyPlainButtonStyle()
            .modifier(MiddleSectionItemConfig())
            .fullScreenCover(isPresented: $showWelcome) {
                FTWelcomeView(viewModel: FTGetStartedItemViewModel(), source: .settings)
            }
#endif
        }
        .frame(maxWidth: .infinity)
        .background(Color.appColor(.cellBackgroundColor))
        .shadow(color: Color.appColor(.cellBackgroundColor), radius: 0.1)
        .cornerRadius(10)
        .padding(.horizontal,25.5)
        .padding(.top,16)
    }

    @ViewBuilder
    private func aboutNoteshelfOption(option: FTAboutNoteshelfOptions) -> some View{
        Button {
    #if targetEnvironment(macCatalyst)
            if let url = URL(string: option.webUrl) {
                UIApplication.shared.open(url);
            }
    #else
            aboutNoteshelfOption = option
            isShowingWebView = true
    #endif
        } label: {
            HStack {
                Text(option.title)
                Spacer()
                Image(icon: .rightArrow)
                    .foregroundColor(Color.label).opacity(0.5)
            }
            .contentShape(Rectangle())
        }
        .macOnlyPlainButtonStyle()
        .modifier(MiddleSectionItemConfig())
    }

    @ViewBuilder
    private var footerSection: some View{
        VStack{
            LazyHGrid(rows: columns,alignment: .center, spacing:32){
                ForEach(SocialMediaTypes.allCases, id: \.self.url) { type in
                    Image(type.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44,height: 44)
                        .onTapGesture {
#if targetEnvironment(macCatalyst)
                            if let url = URL(string: type.url) {
                                UIApplication.shared.open(url);
                            }
#else
                            selectedStyle = type
                            showWebview = true
#endif
                        }
                }
            }
            .if(selectedStyle != nil, transform: { view in
                view.fullScreenCover(isPresented: $showWebview) {
                    if let selectedStyle = selectedStyle, let url = URL(string: selectedStyle.url) {
                        SafariView(url: url)
                    }
                }
            })
                Text(viewModel.copyrightMessage)
                .font(.appFont(for: .regular, with: 13))
                .foregroundColor(Color.label).opacity(0.7)
                .lineLimit(1)
        }
        .frame(height: 120)
        .padding(.bottom,22)
    }
}

struct MiddleSectionItemConfig: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.appColor(.black1))
            .padding(.horizontal,16)
            .frame(height: 44)
    }
}
struct FTSettingsAboutView_Previews: PreviewProvider {
    static var previews: some View {
        FTSettingsAboutView(viewModel: FTSettingsAboutViewModel())
    }
}

struct SafariView: UIViewControllerRepresentable {
   let url: URL
   func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
       return SFSafariViewController(url: url)
   }
   func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {

   }
}
extension Bundle {
    public var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        else if let iconFiles = infoDictionary?["CFBundleIconFile"] as? String {
            return UIImage(named: iconFiles)
        }
        return nil
    }
}
