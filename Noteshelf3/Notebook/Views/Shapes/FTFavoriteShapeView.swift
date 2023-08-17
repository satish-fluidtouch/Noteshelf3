//
//  FTShapeView.swift
//  Noteshelf3
//
//  Created by Narayana on 02/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTFavoriteShapeView: View {
    var isSelected: Bool
    let shapeType: FTShapeType
    
    var body: some View {
        self.shapeStateView
            .contentShape(Rectangle())
    }

    private var shapeStateView: some View {
        ZStack {
            self.backGround
                .isHidden(!self.isSelected)
            Image(shapeType.getMiniShapeName())
                .renderingMode(.template)
                .foregroundColor(.label)
                .opacity(self.isSelected ? 1.0 : 0.2)
        }
    }

    private var backGround: some View {
        RoundedRectangle(cornerRadius: 14.0, style: .continuous)
            .frame(width: 28.0, height: 28.0)
            .shadow(color: Color.label.opacity(0.12), radius: 8, x: 0.0, y: 4.0)
            .foregroundColor(Color.appColor(.white100))
    }

}

struct FTFavoriteShapeView_Previews: PreviewProvider {
    static var previews: some View {
        FTFavoriteShapeView(isSelected: true, shapeType: .freeForm)
    }
}
