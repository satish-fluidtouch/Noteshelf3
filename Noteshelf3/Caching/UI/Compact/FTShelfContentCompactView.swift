//
//  FTShelfContentCompactView.swift
//  Noteshelf3
//
//  Created by Akshay on 16/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShelfContentCompactView: View {
    @State private var selectedPage: Int = 0
    @ObservedObject var photosViewModel = FTShelfContentPhotosViewModel()
    @ObservedObject var audioViewModel = FTShelfContentAudioViewModel()

    var content: [FTShelfPageModel]
    let bookmarksView = FTShelfBookmarksRepresentableView(viewModel: FTShelfBookmarksPageModel())
    var body: some View {
        VStack {
            segmentControl
            TabView(selection: $selectedPage) {
                ForEach(content, id: \.pageId) { page in
                    if page.pageId == 0 {
                        FTShelfContentPhotosView(viewModel: photosViewModel)
                    } else if page.pageId == 1 {
                       FTShelfContentAudioView(viewModel: audioViewModel)
                    } else if page.pageId == 2 {
                        bookmarksView
                     }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    @ViewBuilder
    private var segmentControl: some View {
        ScrollView(.horizontal, showsIndicators: false){
            ScrollViewReader { proxy in
                HStack {
                    ForEach(content, id: \.pageId) { page in
                        FTPageSegmentPillView(title: page.title, icon: page.icon,
                                              isSelected: Binding(get: { page.pageId == selectedPage }, set: { v, t in
                            selectedPage = page.pageId
                        }))
                        .id(page.pageId)
                        .onTapGesture {
                            withAnimation {
                                selectedPage = page.pageId
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .onChange(of: selectedPage) { newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: UnitPoint.center)
                    }
                }
            }
        }
    }
}

struct FTPageSegmentPillView: View {
    let title: String
    let icon: Image
    @Binding var isSelected: Bool

    var body: some View {
        Label {
            Text(title)
                .appFont(for: .regular, with: 16)

        } icon: {
            icon
                .font(.appFont(for: .regular, with: 15))
        }

        .frame(height: 32, alignment: .center)
        .padding(.horizontal, 8)
            .background(isSelected ? Color.appColor(.ftBlue) : Color.clear)
            .addBorder(isSelected ? Color.clear : Color.appColor(.black70), cornerRadius: 10)
            .foregroundColor(isSelected ? Color.white : Color.black)
    }
}

#if DEBUG
struct FTCompactDisplayPreviewPage {
    let title: String

    var body: some View {
        VStack {
            Text(title)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray)
    }
}
#endif
