//
//  FTLoadingView.swift
//  Noteshelf3
//
//  Created by srinivas on 11/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTLoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading")
        }.padding()
    }
}

struct FTLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        FTLoadingView()
    }
}
