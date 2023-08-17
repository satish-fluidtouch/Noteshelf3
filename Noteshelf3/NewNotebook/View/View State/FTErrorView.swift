//
//  FTErrorView.swift
//  Noteshelf3
//
//  Created by srinivas on 11/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTErrorView: View {
    
    let errorMessage: String
    
    var body: some View {
        Text(errorMessage)
            .font(.body)
            .fontWeight(.semibold)
    }
}

struct FTFailedView_Previews: PreviewProvider {
    static var previews: some View {
        FTErrorView(errorMessage: "sample error message")
    }
}
