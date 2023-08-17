//
//  CustomNavBarView.swift
//  Rooms
//
//  Created by srinivas on 12/07/22.
//

import SwiftUI

struct CustomNavBarView: View {
    @Environment (\.dismiss) var back
    let showBackButton: Bool
    let title: String
    
   
    init(showBackButton: Bool, title: String) {
        self.showBackButton = showBackButton
        self.title = title
    }
    
    var body: some View {
        HStack {
            if showBackButton {
                backButton
            }
            Spacer()
            titleText
            Spacer()
            closeButton
            
        }.padding()
            .accentColor(.white)
            .foregroundColor(.white)
            .background(.gray)
        
    }
}

struct CustomNavBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CustomNavBarView(showBackButton: false, title: "Title here")
            Spacer()
        }
    }
}

extension CustomNavBarView {
    
    private var backButton: some View {
        Button{
            back()
        }label: {
            Image(systemName: "chevron.left")
        }
    }
    
    private var titleText: some View {
        Text(title)
    }
    
    private var closeButton: some View {
        Button{
           back()
        }label: {
            Image(systemName: "xmark.circle.fill")
        }
    }
}
