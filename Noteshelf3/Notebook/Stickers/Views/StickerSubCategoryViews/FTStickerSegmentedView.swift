//
//  FTStickerMenuView.swift
//  StickerModule
//
//  Created by Rakesh on 14/03/23.
//

import SwiftUI

struct FTStickerSegmentedView: View {
    @EnvironmentObject private var viewModel: FTStickerCategoriesViewModel

    @Binding var selection: String
    var onTapMenu: (String)->()
    
    var body: some View {
        ScrollViewReader{ proxy in
        ScrollView(.horizontal,showsIndicators: false) {
                HStack{
                    ForEach(viewModel.menuItems, id: \.self) { item in
                        Text(item.localized)
                            .padding()
                            .frame(height: 36.0)
                            .appFont(for: .medium, with: 13)
                            .foregroundColor(selection == item ? Color.white : Color.appColor(.black70))
                            .background(selection == item ? Color.appColor(.darkBlack) : Color.appColor(.black5))
                            .cornerRadius(10)
                            .onTapGesture {
                                selection = item
                                onTapMenu(item)
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    proxy.scrollTo(item,anchor: .center)
                                }
                            }
                    }
                }
                .padding(5)
            }
        }
        .padding(.trailing,-15)
        .padding(.leading,-10)
        .onChange(of: viewModel.recentStickerItems, perform: { newValue in
            selection = viewModel.menuItems[0]
        })
        .onFirstAppear{
            selection = viewModel.menuItems[0]
        }
    }
}
