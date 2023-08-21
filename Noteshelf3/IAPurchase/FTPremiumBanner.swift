//
//  FTPremiumBanner.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 08/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI

struct FTPremiumBanner: View {
    @EnvironmentObject var viewModel : FTSidebarViewModel
    @EnvironmentObject var premiumUser : FTPremiumUser

    var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 10) {
                Image("premium_icon", bundle: nil)
                    .frame(width: 36, height: 36, alignment: .center)
                    .scaledToFit()

                VStack(alignment: .leading, spacing: 4) {
                    Text("iap.bannerTitle".localized)
                        .font(.appFont(for: .bold, with: 15))
                        .multilineTextAlignment(.leading)
                    Text(String(format: "iap.booksleft".localized, NSNumber(value: max(premiumUser.maxBookLimitForFree - premiumUser.numberOfBookCreate,0))))
                        .multilineTextAlignment(.leading)
                        .font(.appFont(for: .regular, with: 13))
                        .foregroundColor(Color.appColor(.accent))

                    Spacer()

                    Button {
                        viewModel.delegate?.didTapOnUpgradeNow();
                    } label: {
                        Text("iap.upgradeNow".localized)
                            .font(.appFont(for: .bold, with: 13))
                            .foregroundColor(Color.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .frame(height: 28,alignment: .leading)
                    .background(Color("premium_bg"))
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.04), radius: 0.5, x: 0, y: 3)
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 3)
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
