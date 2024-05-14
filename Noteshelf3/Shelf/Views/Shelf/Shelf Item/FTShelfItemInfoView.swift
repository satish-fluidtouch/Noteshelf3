//
//  FTShelfItemInfoView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 11/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
enum FTShelfItemInfoTypes {
    case title
    case location
    case modifiedDate
    case createdDate
    case fileSize

    var displayTitle: String {
        switch self {
        case .title:
            return "Title".localized
        case .location:
            return "shelfItemInfo.where".localized
        case .modifiedDate:
            return "shelfItemInfo.modified".localized
        case .createdDate:
            return "Created".localized
        case .fileSize:
            return "Size";
        }
    }
}

struct FTShelfItemInfoView: View {
    var shelfItemInfo: FTShelfItemInfo
    let infoDetails: [FTShelfItemInfoTypes] = [.title,.location,.modifiedDate,.createdDate,.fileSize]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack {
                    ScrollView {
                        VStack(spacing:0.0) {
                            ForEach(infoDetails.indices,id: \.self) { index in
                                let itemDetailType = infoDetails[index]
                                let isLastItemInList = index == infoDetails.count - 1
                                VStack(spacing:0.0) {
                                    VStack(alignment: .center) {
                                        HStack(alignment: .center) {
                                            Text(itemDetailType.displayTitle)
                                                .appFont(for: .regular, with: 15)
                                                .foregroundColor(Color.appColor(.black70))
                                                .multilineTextAlignment(.trailing)
                                            Spacer(minLength: 12)
                                            Text(shelfItemInfo.getDisplayStringForType(itemDetailType))
                                                .appFont(for: .regular, with: 15)
                                                .foregroundColor(Color.label)
                                                .multilineTextAlignment(.trailing)
                                        }
                                        .padding(.leading,16)
                                        .padding(.trailing,16)
                                    }
                                    .frame(minHeight: 43.0,alignment: .center)
                                    .contentShape(Rectangle())
                                    if !isLastItemInList {
                                        Rectangle()
                                            .frame(height: 0.5,alignment: .bottom)
                                            .foregroundColor(.appColor(.black10))
                                    }
                                }
                            }
                            .background(Color.appColor(.cellBackgroundColor))
                            .cornerRadius(10)
                        }
                        .padding(.bottom, 16)
                    }
                }
                .frame(minHeight:170,maxHeight:.infinity ,alignment: .top)
                .padding(.trailing,16)
                .padding(.leading, 16)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("shelfItem.contexualMenu.getInfo.NavTtile".localized)
                            .appFont(for: .regular, with: 15)
                            .fontWeight(.bold)
                    }
                }
            }
            .background(.regularMaterial)
        }
    }
}

struct FTShelfItemInfoView_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfItemInfoView(shelfItemInfo: FTShelfItemInfo(title: "Sample", location: "Keto/New", modifiedDate: "Sampleee", createdDate: "Sample",fileSize: "100 MB"))
    }
}
struct FTShelfItemInfo {
    var title: String
    var location: String
    var modifiedDate: String
    var createdDate: String
    var fileSize: String = "";

    func getDisplayStringForType(_ type: FTShelfItemInfoTypes) -> String {
        switch type {
        case .title:
            return title
        case .location:
            return location
        case .modifiedDate:
            return modifiedDate
        case .createdDate:
            return createdDate
        case .fileSize:
            return fileSize;
        }
    }
}
