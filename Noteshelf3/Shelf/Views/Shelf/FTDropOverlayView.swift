//
//  DropOverlayView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 03/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTDropOverlayView: View {
    @EnvironmentObject var viewModel: FTShelfViewModel
    var body: some View {
        ZStack {
            HStack{}
                .zIndex(1)
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .center
                  )
                .background(Color.appColor(.black1).opacity(0.5))
            VStack(spacing: 20.0, content: {
                Image(uiImage: UIImage(named: "dropHereGreen")!)
                Text(NSLocalizedString("shelf.dragAndDrop.dropAnywhere", comment: "Drop anywhere to import the file"))
                    .foregroundColor(Color.black)
            })
            .zIndex(2)
        }
        .ignoresSafeArea()
    }
}

struct DropOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        FTDropOverlayView()
    }
}
