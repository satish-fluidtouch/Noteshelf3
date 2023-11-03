//
//  FTAdBannerView.swift
//  Noteshelf3
//
//  Created by Rakesh on 03/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTAdBannerView: View{
    fileprivate let FTWatchAdDoNotShowDefaultsKey = "watch_banner_do_not_show";
    fileprivate let FTWatchAdLastShownTimeDefaultsKey = "watch_banner_last_shown";
    @State private var isBannerVisible = true
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View{
        if isBannerVisible{
            GroupBox(content: {
                HStack(spacing: 20){
                    Image("banner_watch_Icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80,height: 80)

                    VStack(alignment: .leading,spacing: 20){
                        Text("WatchAdInfo".localized)
                            .foregroundColor(Color.label)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 30){
                            Button {
                                UserDefaults.standard.set(true, forKey: FTWatchAdDoNotShowDefaultsKey);
                                UserDefaults.standard.synchronize()
                                self.removeBannerAd()
                            } label: {
                                Text("Dismiss".localized)
                                    .padding()
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.label)
                                    .frame(height: 30)
                                    .border(.appColor(.black70), width: 0.5, cornerRadius: 4.0)
                            }
                            Button {
                                UserDefaults.standard.set(Date.now + 2.0, forKey: FTWatchAdLastShownTimeDefaultsKey)
                                UserDefaults.standard.synchronize()
                                self.removeBannerAd()
                            } label: {
                                Text("RemindMeLater".localized)
                                    .padding()
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.label)
                                    .frame(height: 30)
                                    .border(.appColor(.black70), width: 0.5, cornerRadius: 4.0)
                            }
                        }
                    }
                }
            })
            .backgroundStyle(Color.appColor(.watchViewBg))
            .padding(.horizontal,sizeClass == .compact ? 8 : 30)
//            .shadow(color: .gray, radius: 5, x: 0, y: 2)
            .onAppear{
                addBannerIfNeeded()
                isBannerVisible = canShowWatchBanner()
            }
        }else{
            EmptyView()
        }
    }
    private func canShowWatchBanner() -> Bool {
        let thresholdDuration = Double(60*60*24);
        let donotShow = UserDefaults.standard.bool(forKey: FTWatchAdDoNotShowDefaultsKey);
        if(donotShow) {
            return false
        }

        let lastshowndate = UserDefaults.standard.double(forKey: FTWatchAdLastShownTimeDefaultsKey);
        let currentdate = Date.timeIntervalSinceReferenceDate
        if(lastshowndate == 0 || ((currentdate-lastshowndate) > thresholdDuration)) {
            return true
        }
        return false
    }
    private func addBannerIfNeeded() {
            self.updateBannerAd(nil)
            NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: nil) { notification in
                self.updateBannerAd(notification)
            }

            NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTUbiquitousKeyValueStoreChangedLocally), object: nil, queue: nil) { notification in
                self.updateBannerAd(notification)
            }
        }
    private func updateBannerAd(_ notification: Notification?) {
        if(NSUbiquitousKeyValueStore.default.isWatchPaired()) {
            if !NSUbiquitousKeyValueStore.default.isWatchAppInstalled() {
                isBannerVisible = true
            } else {
                //remove
                removeBannerAd()
            }
        }
    }
    private func removeBannerAd() {
        withAnimation {
            isBannerVisible = false
        }
    }
}

#Preview {
    FTAdBannerView()
}
