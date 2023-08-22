//
//  FTOnboardingGetStartedView.swift
//  Noteshelf3
//
//  Created by Rakesh on 21/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTWelcomeView: View {
    @State private var xoffset: CGFloat = 0
    private let itemSize: CGFloat = 180
    weak var delegate: FTGetstartedHostingViewcontroller?
    @ObservedObject var viewModel: FTGetStartedItemViewModel
    var source: FTSourceScreen
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(alignment: .center, spacing: 0){
            Spacer(minLength: 60)

            headerView

            VStack(spacing: -30){
                gridLeftToRight
                gridRightToLeft
            }

            footerView

            Spacer(minLength: 60)
                .onAppear {
                    withAnimation(.linear(duration: 200).repeatForever(autoreverses: false)) {
                        xoffset = -itemSize * CGFloat((viewModel.getstartedList.count * 2))
                    }
                }
        }
        .background(LinearGradient(gradient: Gradient(colors: [.appColor(.welcometopGradiantColor), .appColor(.welcomeBottonGradiantColor)]), startPoint: .top, endPoint: .bottom))
    }
    
    @ViewBuilder
    private var headerView: some View {
        Image(viewModel.appLogo)
            .resizable()
            .scaledToFit()
            .frame(height: 48.0)
            .padding(.bottom,16)
        Text(viewModel.headerTopTitle)
            .foregroundColor(.black)
            .font(.clearFaceFont(for: .regular, with: 52))

        HStack{
            Text(viewModel.headerbottomfirstTitle)
            Text(viewModel.headerbottomsecondTitle)
                .italic(true)
        }
        .foregroundColor(.black)
        .font(.clearFaceFont(for: .regular, with: 52))
        .multilineTextAlignment(.center)
        .padding(.bottom,36)
    }
    @ViewBuilder
    private var footerView: some View {
        Button {
            if source == .regular{
                self.delegate?.dismiss()
            }else{
                self.dismiss()
            }
        } label: {
            Text(viewModel.btntitle)
                .frame(width: 280,height: 48)
                .foregroundColor(.white)
                .font(.clearFaceFont(for: .medium, with: 20))
                .background(Color.appColor(.welcomeBtnColor))
                .cornerRadius(16)
        }
        .macOnlyPlainButtonStyle()
        .shadow(color: .appColor(.welcomeBtnColor).opacity(0.24), radius: 16.0, x: 0, y: 12.0)
    }
    @ViewBuilder
    private var gridLeftToRight: some View {
        GridItemView(xpositionOffset: xoffset, itemSize: itemSize, getStartedItems: viewModel.getstartedList,angle:Angle(degrees: 0))
    }
    @ViewBuilder
    private var gridRightToLeft: some View {
        GridItemView(xpositionOffset: xoffset, itemSize: itemSize, getStartedItems: viewModel.getstartedList, angle: Angle(degrees: 180))
            .rotationEffect(Angle(degrees: -180))
    }
}
struct GridItemView: View {
    var xpositionOffset: CGFloat
    let itemSize: CGFloat
    let getStartedItems:[FTGetStartedViewItems]
    let angle: Angle

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<getStartedItems.count * 3, id: \.self) { item in
                    let iteminfo = getStartedItems[item % getStartedItems.count]
                    ZStack(alignment: .bottom) {
                        Image(iteminfo.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: itemSize)
                            .overlay(alignment: .top) {
                                Text(iteminfo.displayTitle)
                                    .foregroundColor(Color.appColor(.neroColor))
                                    .font(.system(size: 12,weight: .medium))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(height: 60, alignment: .center)
                                    .padding(.top, 80)
                                    .padding(.horizontal, 23)
                            }
                    }
                    .padding(.trailing, -45)
                }
            }
            .rotationEffect(angle)
            .offset(x: xpositionOffset)
        }
        .allowsHitTesting(false)
    }
}

struct FTOnboardingGetStartedView_Previews: PreviewProvider {
    static var previews: some View {
        FTWelcomeView(viewModel: FTGetStartedItemViewModel(), source: .regular)
    }
}

