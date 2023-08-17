//
//  FTNewNoteItem.swift
//  Noteshelf3
//
//  Created by Rakesh on 18/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTNewNoteItem:View{

    let type: FTNewNotePopoverOptions

    var body: some View{
        VStack(alignment: .leading){
                HStack{
                    Image(icon: type.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32.0,height: 32.0)
                        .padding(.leading, 12)

                    LabeledContent {
                        if type == .quickNote {
                            Image(icon: .quickCreateSettings)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16.0,height: 24.0)
                                .font(.appFont(for: .regular, with: 17))
                                .padding(.trailing,16)
                        }
                    } label: {
                        Text(type.displayTitle)
                            .foregroundColor(Color.appColor(.black1))
                            .font(Font.appFont(for: .regular, with: 16))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60.0)
                .background(Color.appColor(.white40))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appColor(.accentNew).opacity(0.1), lineWidth: 1.0)
                )
            }
        }
    }
struct FTNewNoteItem_Previews: PreviewProvider {
    static var previews: some View {
        FTNewNoteItem(type: .quickNote)
    }
}
