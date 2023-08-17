//
//  CustomNavBarContainerView.swift
//  Rooms
//
//  Created by srinivas on 12/07/22.
//

import SwiftUI

struct CustomNavBarContainerView<Content: View>: View {
    
    @State private var showBackButton: Bool = true
    @State private var title: String = ""
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavBarView(showBackButton: showBackButton, title: title)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onPreferenceChange(TitlePrefKey.self) { value in
            self.title = value
        }
        
        .onPreferenceChange(ShowBackButtonPrefKey.self) { value in
            self.showBackButton = value
        }
    }
}

struct CustomNavBarContainerView_Previews: PreviewProvider {
    static var previews: some View {
        CustomNavBarContainerView {
            ZStack {
                Color.brown.ignoresSafeArea()
                Text("Hello wwdc 2022")
                    .foregroundColor(.white)
                    .customNavTitle("New Title Here")
                    .customNavBackButtonHidden(false)
            }
        }
    }
}
