//
//  FTAnnouncementView.swift
//  Noteshelf3
//
//  Created by Rakesh on 07/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTAnnouncementView: View {
    let title: String
    let migrationContentFileName: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        if FTIAPManager.shared.premiumUser.isPremiumUser && FTDocumentMigration.isNS2AppInstalled() && UserDefaults.standard.bool(forKey: "migrationAnnoucementViewToShow") {
            ZStack(alignment: .center) {
                ScrollView {
                    VStack(spacing: 8, content: {
                        Image("Noteshelf_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 128,height: 192)
                            .cornerRadius(10)

                        Text(title)
                            .font(.clearFaceFont(for: .medium, with: 28.0))

                        Text(readAnnouncement(contentFilename: migrationContentFileName))
                            .font(.appFont(for: .regular, with: 15))
                            .multilineTextAlignment(.center)
                    })
                    .padding(.horizontal,24)
                    .multilineTextAlignment(.center)
                }
            }
            .onDisappear{
                UserDefaults.standard.setValue(false, forKey: "migrationAnnoucementViewToShow")
            }
            .overlay(alignment: .bottom) {
                Button {
                    dismiss()
                } label: {
                    Text("OK".localized)
                        .frame(maxWidth: .infinity, minHeight: 36,maxHeight: 36,alignment: .center)
                        .background(Color.appColor(.accent))
                        .foregroundColor(.white)
                        .font(.appFont(for: .medium, with: 15.0))
                        .cornerRadius(10.0)
                }
                .padding(24)
                .shadow(color: .appColor(.accent).opacity(0.24), radius: 8, x: 0, y: 4)
            }
        }
    }
}

#Preview {
    FTAnnouncementView(title: "", migrationContentFileName: "")
}

class FTAnnouncementViewHostingController: UIHostingController<FTAnnouncementView> {

    init() {
        let view = FTAnnouncementView(title: "updatemigration.title".localized, migrationContentFileName: "migrationAnnouncementContent")
        super.init(rootView: view)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
