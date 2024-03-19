//
//  FTNoResultsView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 02/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTNoResultsView: View {
    var noResultsImageName: String
    var title: String
    var description: String = ""
    var learnMoreLink: String = ""
    var showLearnMoreLink: Bool = false
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0.0) {
                Image(uiImage: UIImage(named: noResultsImageName)!)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64, alignment: Alignment.center)
                    .padding(.bottom, 16)

                Text(title)
                    .fontWeight(.semibold)
                    .font(.clearFaceFont(for: .medium, with: 22))
                    .foregroundColor(.primary)
                    .padding(.bottom,8)

                Text(description)
                    .fontWeight(.regular)
                    .appFont(for: .regular, with: 15)
                    .frameStyle(isLargeSize: isLargerTextEnabled(for: dynamicTypeSize))
                    .multilineTextAlignment(.center)
                    .lineSpacing(0)
                    .kerning(-0.41)
                    .padding(.bottom,8)
                    .foregroundColor(Color.appColor(.black70))

                if showLearnMoreLink{
                    NavigationLink(destination: Text("Learn more link page")) {
                        Text("Learn more")
                            .fontWeight(.regular)
                            .appFont(for: .regular, with: 13)
                            .foregroundColor(Color(hex: "#305EF7"))
                    }
                }
            }
            Spacer()
        }.ignoresSafeArea()
    }
}

struct FTNoResultsView_Previews: PreviewProvider {
    static var previews: some View {
        FTNoResultsView(noResultsImageName: "trash", title: "Trash is Empty", description: "", learnMoreLink: "Learn More", showLearnMoreLink: false)
    }
}

private struct FrameStyleModifier: ViewModifier {
    var isLargeSize = false
    func body(content: Content) -> some View {
        if isLargeSize {
            content
                .frame(minWidth: 234, alignment: .center)
                .padding(.horizontal, 8)
        } else {
            content
                .frame(width: 234, alignment: .center)
        }
    }
}

private extension View {
    func frameStyle(isLargeSize: Bool) -> some View {
        self.modifier(FrameStyleModifier(isLargeSize: isLargeSize))
    }
}
