//
//  FTShareContentView.swift
//  Noteshelf3
//
//  Created by Narayana on 02/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles
import FTCommon

struct FTShareContentView: View {
    @ObservedObject var viewModel: FTShareFormatViewModel
    @State private var isExapanded = false
    private let formatOptions: [RKExportFormat] = [kExportFormatImage, kExportFormatPDF, kExportFormatNBK]

    var body: some View {
        ZStack(alignment: .bottom) {
            stickyFooterView
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .center, spacing: 16) {
                            preview
                            mainmenuSection
                            optionsandHideview(proxy: proxy)
                        }
                    }
                }
                .padding(.bottom, 76.0)
        }
        .background(Color.appColor(.panelBgColor))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
    }

    @ViewBuilder
    private var preview: some View {
        FTSharePreviewView()
            .frame(height: 298,alignment:.center)
            .padding(.horizontal,24)
            .environmentObject(viewModel)
            .padding(.top, 15)
    }

    @ViewBuilder
    private var mainmenuSection: some View {
        VStack(spacing: 0.0) {
            VStack(spacing: 0) {
                ForEach(formatOptions.indices, id: \.self) { index in
                    let option = formatOptions[index]
                    HStack(spacing: FTSpacing.large) {
                        Image(icon: option.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24.0, height: 24.0)
                            .foregroundColor(.appColor(.accent))
                            .font(Font.appFont(for: .regular, with: 15.0))

                        Text(option.displayTitle)
                            .appFont(for: .regular, with: 17)
                            .foregroundColor(.primary)

                        Spacer()

                        if option == viewModel.selectedFormat {
                            Image(icon: .checkmark)
                                .imageScale(.small)
                        }
                    }
                        .frame(height:44)
                        .padding(.horizontal, FTSpacing.large)
                        .contentShape(Rectangle())
                        .background(Color.appColor(.cellBackgroundColor))

                        .onTapGesture {
                          trackFormat(option)
                            viewModel.selectedFormat = option
                            if option == kExportFormatNBK {
                                isExapanded = false
                            }
                        }

                    if(index < formatOptions.count - 1) {
                        FTDividerLine()
                    }
                }
            }
        }
        .cornerRadius(10)
        .padding(.horizontal, FTSpacing.extraLarge)
    }
    
    private func trackFormat(_ format: RKExportFormat) {
        if viewModel.selectedFormat != format {
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.share_format_tap, params: ["format": format.param])
        }
    }

    @ViewBuilder
    private func optionsandHideview(proxy:ScrollViewProxy) -> some View{
        DisclosureGroup(
            isExpanded: $isExapanded,
            content: {
                FTExportOptionsView()
                    .environmentObject(viewModel)
                    .padding(.horizontal, FTSpacing.extraLarge)
            },
            label: {
                Color.clear.overlay(alignment: .center) {
                    HStack(spacing: 6) {
                        Text(isExapanded ? viewModel.hide : viewModel.options)
                            .font(.appFont(for: .regular, with: 13.0))
                            .foregroundColor(Color.appColor(.accent))

                        Image(icon: isExapanded ? .upChevron : .downChevron)
                            .font(.appFont(for: .semibold, with: 11))
                            .frame(width: 12,height: 16,alignment: .center)
                            .foregroundColor(Color.appColor(.accent))
                    }
                }
                .macOnlyTapAreaFixer()
                .macOnlyPlainButtonStyle()
            }
        )
        .isHidden(viewModel.selectedFormat == kExportFormatNBK)
        .accentColor(Color.clear)
        .id(1).onChange(of: isExapanded) { value in
            if value && viewModel.selectedFormat != kExportFormatNBK {
                runInMainThread(0.2) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(1)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stickyFooterView: some View {
        VStack(spacing: 0){
            if viewModel.canShowSaveToCameraRollOption {
                footerView
            } else {
                shareButton
            }
        }
        .padding(.horizontal, FTSpacing.extraLarge)
        .padding(.bottom, FTSpacing.extraLarge)
        .padding(.top, FTSpacing.large)
        .macOnlyPlainButtonStyle()
    }

    private var shareButton : some View {
        Button(action: {
            self.viewModel.handleShareAction()
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.share_share_tap)
        }) {
            Text(viewModel.share)
                .appFont(for: .medium, with: 15.0)
                .padding(FTSpacing.extraLarge)
                .frame(height: 36)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .foregroundColor(Color.white)
        }
        .background(Color.appColor(.accent)).cornerRadius(10)
    }

    @ViewBuilder
    var footerView: some View {
        HStack(spacing: 16.0){
            Button(action: {
                self.viewModel.handleAddCameraRollAction()
                FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.share_savetocamera_tap)
            }) {
                Text(viewModel.saveToCameraroll)
                    .appFont(for: .medium, with: 15.0)
                    .padding(FTSpacing.extraLarge)
                    .frame(height: 36)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .foregroundColor(Color.appColor(.accent))
            }
                .border(Color.appColor(.accent),
                        width:1.0,
                        cornerRadius: 10)
                .buttonStyle(PlainButtonStyle())

            shareButton
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text(viewModel.cancel)
                .appFont(for: .medium, with: 17.0)
                .foregroundColor(.appColor(.accent))
                .onTapGesture {
                    self.viewModel.handleCancelAction()
                    FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.share_cancel_tap)
                }
        }
        ToolbarItem(placement: .principal) {
            Text(viewModel.titleShare)
                .font(.clearFaceFont(for: .medium, with: 20))
        }
    }
}

struct FTExportOptionsView: View {
    @State var options: [FTShareOptionStatus] = []
    @EnvironmentObject var viewModel: FTShareFormatViewModel

    var body: some View {
        VStack(alignment:.center,spacing: 0.0) {
            ForEach($options.indices, id: \.self) { index in
                let currentOption = options[index].option
                let status = options[index].status
                HStack {
                    Text(currentOption.title)
                        .appFont(for: .regular, with: 16)
                        .foregroundColor(.primary)
                    Spacer()
                    Toggle(isOn: $options[index].status) {
                    }
                    .greenStyle()
                    .onChange(of: options[index].status) { _ in
                        let str = options[index].status ? "on" : "off"
                        FTNotebookEventTracker.trackNotebookEvent(with: options[index].option.eventName, params: ["toggle": str])
                    }
                }.frame(height: 44)
                    .padding(.horizontal, FTSpacing.large)
                    .onChange(of: status, perform: { newStatus in
                        self.viewModel.saveStatus(for: currentOption, status: newStatus)
                    })

                if index < viewModel.exportOptions.count - 1 {
                    FTDividerLine()
                }
            }
        }
        .background(Color.appColor(.cellBackgroundColor))
        .cornerRadius(10)
        .padding(.top, FTSpacing.large)
        .onAppear {
            self.options = self.viewModel.exportOptions
        }
    }
}

struct FTDividerLine: View {
    var leftPadding: CGFloat = -20;
    var body: some View {
        Color.appColor(.black10)
            .padding(.horizontal, leftPadding)
            .frame(maxWidth: .infinity,maxHeight: 0.5)
    }
}

struct FTShareContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ZStack {
                Color.red
                FTShareContentView(viewModel: FTShareFormatViewModel(option: .allPages, pages: []))
            }
        }
    }
}
