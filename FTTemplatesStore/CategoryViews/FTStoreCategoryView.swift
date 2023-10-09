//
//  FTStoreCategoriesView.swift
//  FTTemplatesStore
//
//  Created by Siva on 11/07/23.
//

import SwiftUI
import FTCommon

struct FTStoreCategoryView: View {
    var templateInfo: StoreInfo

    var body: some View {
        let items = templateInfo.discoveryItems

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
                        configureRowViewWith(item: item, items: items, index: index)
                    }
                }

                HStack {
                    ForEach(bottomRows,id: \.element) { (index, item) in
                        configureRowViewWith(item: item, items: items, index: index)
                    }
                }
            }
            .padding(.horizontal, 3)
            .frame(height: 172)
            .background(.clear)
        }
    }

    private func configureRowViewWith(item: DiscoveryItem, items: [DiscoveryItem], index: Int) -> some View {
        Button {
            var _items = items
            // Update sectionType to track events
            _items[index].sectionType = templateInfo.sectionType
            FTStoreActionManager.shared.actionStream.send(.didTapOnDiscoveryItem(items: _items, selectedIndex: index))
        } label: {
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
        }
        .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: .slow))
    }
}


