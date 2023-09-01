//
//  FTStoreCategoriesView.swift
//  FTTemplatesStore
//
//  Created by Siva on 11/07/23.
//

import SwiftUI

struct FTStoreCategoryView: View {
    var templateInfo: StoreInfo

    var body: some View {
        var items = templateInfo.discoveryItems

        let topRows = items.enumerated().filter { element in
            return element.offset%2 == 0
        }

        let bottomRows = items.enumerated().filter { element in
            return element.offset%2 == 1
        }

        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading) {
                HStack {
                    ForEach(topRows,id: \.element) { (index, item) in
                        HStack{
                            let image = UIImage(named: item.fileName, in: storeBundle, with: nil)
                            Image(uiImage: image!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40,height: 40)
                            Text(item.title)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.appColor(.black5))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appColor(.accentBorder), lineWidth: 1))
                        .font(Font.appFont(for: .medium, with: 16))
                        .onTapGesture {
                            // Update sectionType to track events
                            var item = items[index]
                            item.sectionType = templateInfo.sectionType
                            items[index] = item
                            
                            FTStoreActionManager.shared.actionStream.send(.didTapOnDiscoveryItem(items: items, selectedIndex: index))
                        }
                    }
                }

                HStack {
                    ForEach(bottomRows,id: \.element) { (index, item) in
                        HStack{
                            let image = UIImage(named: item.fileName, in: storeBundle, with: nil)
                            Image(uiImage: image!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40,height: 40)
                            Text(item.title)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.appColor(.black5))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appColor(.accentBorder), lineWidth: 1))
                        .font(Font.appFont(for: .medium, with: 16))

                        .onTapGesture {
                            // Update sectionType to track events
                            var item = items[index]
                            item.sectionType = templateInfo.sectionType
                            items[index] = item

                            FTStoreActionManager.shared.actionStream.send(.didTapOnDiscoveryItem(items: items, selectedIndex: index))
                        }
                    }
                }
            }
            .padding(.horizontal, 3)
            .frame(height: 172)
            .background(.clear)
        }
    }
}
