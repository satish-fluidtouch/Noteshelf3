//
//  FTPremiumBanner.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 08/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import FTCommon

struct FTPremiumBanner: View {
    @EnvironmentObject var viewModel : FTSidebarViewModel
    @EnvironmentObject var premiumUser : FTPremiumUser
    @State var height: CGFloat = 136

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                VStack {
                    Image("premium_icon", bundle: nil)
                        .frame(width: 36, height: 36, alignment: .center)
                        .scaledToFit()

                    Spacer()

                    Image("premium_banner_wave")
                        .scaledToFill()
                        .frame(width: 76, height: 76, alignment: .bottomLeading)
                        .foregroundStyle(Color(hex: "0455CF", alpha: 0.2))
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("iap.bannerTitle".localized)
                        .font(.appFont(for: .bold, with: 15))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 4)

                    Text(String(format: "iap.booksleft".localized, NSNumber(value: max(premiumUser.maxBookLimitForFree - premiumUser.numberOfBookCreate,0))))
                        .multilineTextAlignment(.leading)
                        .font(.appFont(for: .regular, with: 13))
                        .foregroundColor(Color.appColor(.accent))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2.5)
                        .background(Color.appColor(.accent).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Spacer()
                        .frame(height: 12)

                    Text("premiumBanner.featureInfo".localized)
                        .foregroundColor(Color.appColor(.black70))
                        .font(.appFont(for: .regular, with: 13))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 0)
                .padding(.bottom, 16)
                .padding(.trailing, 20)
                Spacer()
            }
            .padding(.top, 16)
        }
        .background(
            GeometryReader { geometry in
                Color.appColor(.premiumBannerBgColor)
                    .background(.ultraThinMaterial)
                    .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
            })
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.25)
                .stroke(Color.appColor(.toolbarOutline), lineWidth: 0.5)
        )
        .frame(height: height)
        .onPreferenceChange(HeightPreferenceKey.self) {
            self.height = $0
        }
        .onTapGesture {
            viewModel.delegate?.didTapOnUpgradeNow()
        }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FTPremiumBanner_Previews: PreviewProvider {
    static var previews: some View {
        FTPremiumBanner()
    }
}
