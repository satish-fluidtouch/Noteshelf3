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
    @State private var isBannerVisible = false
    @StateObject private var watchComponenet = FTWatchComponentModel();
    
    var body: some View{
        let learnMore = "LearnMore".localized
        ZStack {
            if isBannerVisible {
                ZStack {
                    HStack(spacing: 16){
                        Image("iWatchEmpty")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32,height: 32)
                        
                        VStack(alignment: .leading){
                            Text("WatchAdInfoTitle".localized)
                                .foregroundColor(Color.label)
                                .font(.system(size: 15).weight(.bold))
                            
                            HStack {
                                Text("WatchAdInfoSubTitle".localized)
                                    .foregroundColor(Color.label)
                                    .font(.system(size: 13))
                                +
                                Text("  [\(learnMore)](https://www.noteshelf.net)")
                                    .foregroundColor(.appColor(.accent))
                                    .font(.appFont(for: .medium, with: 14))
                            }
                        }
                        
                        Menu {
                            Button("Dismiss".localized, action: dismissAction)
                            Button("RemindMeLater".localized, action: remindMelaterAction)
                        } label: {
                            Label("", image: "close_banner_icon")
                        }
                    }
                    .frame(minHeight: 58.0)
                    .padding(EdgeInsets(top: 4.0, leading: 4.0, bottom: 4.0, trailing: 4.0))
                }
                .background(Color.appColor(.white50))
                .background(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.25)
                        .stroke(Color.appColor(.toolbarOutline), lineWidth: 0.5)
                )
                .cornerRadius(12)
            }
        }
        .onAppear{
            isBannerVisible = watchComponenet.isBannerVisible;
        }
        .onChange(of: watchComponenet.isBannerVisible, perform: { newValue in
            withAnimation {
                isBannerVisible = newValue;
            }
        })
    }
    
    func remindMelaterAction(){
        UserDefaults.standard.set(Date.timeIntervalSinceReferenceDate, forKey: FTWatchAdLastShownTimeDefaultsKey)
        UserDefaults.standard.synchronize()
        self.watchComponenet.isBannerVisible = false;
    }
    
    func dismissAction(){
        UserDefaults.standard.set(true, forKey: FTWatchAdDoNotShowDefaultsKey);
        UserDefaults.standard.synchronize()
        self.watchComponenet.isBannerVisible = false;
    }
}

class FTWatchComponentModel: NSObject,ObservableObject {
    fileprivate let FTWatchAdDoNotShowDefaultsKey = "watch_banner_do_not_show";
    fileprivate let FTWatchAdLastShownTimeDefaultsKey = "watch_banner_last_shown";

    @Published var isBannerVisible: Bool = false;
    
    private weak var ubiquityExternalChangeObserver: NSObjectProtocol?;
    private weak var ubiquityLocalChangeObserver: NSObjectProtocol?;
    
    override init() {
        super.init();
        self.updateBannerAd(nil)
        self.addObservers();
    }
    
    deinit {
        if let observer = self.ubiquityExternalChangeObserver {
            NotificationCenter.default.removeObserver(observer);
        }
        if let observer = self.ubiquityLocalChangeObserver {
            NotificationCenter.default.removeObserver(observer);
        }
    }
    
    private func addObservers() {
        self.ubiquityExternalChangeObserver = NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: nil) { notification in
            self.updateBannerAd(notification)
        }

        self.ubiquityLocalChangeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTUbiquitousKeyValueStoreChangedLocally), object: nil, queue: nil) { notification in
            self.updateBannerAd(notification)
        }
    }
    
    private func updateBannerAd(_ notification: Notification?) {
        if(NSUbiquitousKeyValueStore.default.isWatchPaired()) {
            if !NSUbiquitousKeyValueStore.default.isWatchAppInstalled() {
                self.isBannerVisible = canShowWatchBanner()
            } else {
                //remove
                self.isBannerVisible = false
            }
        } else {
            self.isBannerVisible = false
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
}
