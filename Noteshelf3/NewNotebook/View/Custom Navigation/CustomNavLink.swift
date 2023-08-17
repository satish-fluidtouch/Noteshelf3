//
//  CustomNavLink.swift
//  Rooms
//
//  Created by srinivas on 12/07/22.
//

import SwiftUI

// struct NavigationLink<Label, Destination> : View where Label : View, Destination : View {

struct CustomNavLink<Label: View, Destination: View>: View {
    
    let label: Label
    let destination: Destination
    
    init(@ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) {
        self.destination = destination()
        self.label = label()
    }
    
    var body: some View {
        NavigationLink {
            CustomNavBarContainerView {
                destination
            }.navigationBarHidden(true)
        } label: {
           label
        }
    }
}

struct CustomNavLink_Previews: PreviewProvider {
    static var previews: some View {
        CustomNavView {
            CustomNavLink {
                Text("Dest")
            } label: {
                Text("clcik me")
            }
        }

    }
}
