//
//  FTEDownloadConatainerView.swift
//  Noteshelf3
//
//  Created by Fluid Touch on 18/06/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI
import FTCommon

struct FTEDownloadConatainerView: View {
    @EnvironmentObject var viewModel : FTSidebarViewModel
    @EnvironmentObject var premiumUser : FTPremiumUser

    var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        viewModel.delegate?.didTapDownloadBooks();
                    } label: {
                        Text("Tap Here to download")
                            .font(.appFont(for: .bold, with: 13))
                            .foregroundColor(Color.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 3)
                            .frame(height: 28,alignment: .center)
                            .background(Color.appColor(.accent))
                            .cornerRadius(6)
                            .shadow(color: .black.opacity(0.04), radius: 0.5, x: 0, y: 3)
                            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 3)
                    }
                    .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: .slow))
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 4))
        }
        .frame(height:108)
        .background(Color.appColor(.white50))
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 4)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .inset(by: 0.25)
            .stroke(Color.appColor(.toolbarOutline), lineWidth: 0.5)
        )
    }
}
