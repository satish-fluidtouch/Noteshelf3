//
//  FTOnboardingGetStartedView.swift
//  Noteshelf3
//
//  Created by Rakesh on 21/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

struct FTWelcomeView: View {
    @State private var xoffset: CGFloat = 0
    weak var delegate: FTGetstartedHostingViewcontroller?
    @ObservedObject var viewModel: FTGetStartedItemViewModel
    @Environment(\.dismiss) var dismiss
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    var source: FTSourceScreen
    private var itemSize: CGFloat {
        return (idiom == .phone ? 144 : 180)
    }
    private var fontSize: CGFloat {
        return idiom == .phone ? 36 : 52
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0){
            Spacer(minLength: 0)

            headerView

            Spacer(minLength: 0)

            VStack(spacing: 16){
                gridLeftToRight
                gridRightToLeft
            }
            .shadow(color:.appColor(.welcomeBtnColor).opacity(0.12), radius: 30, x: 0, y: 30)

            Spacer(minLength: 0)

            footerView

            Spacer(minLength: 0)

                .onAppear {
                    withAnimation(.linear(duration: 200).repeatForever(autoreverses: false)) {
                        xoffset = -itemSize * CGFloat((viewModel.getstartedList.count * 2))
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(gradient: Gradient(colors: [.appColor(.welcometopGradiantColor), .appColor(.welcomeBottonGradiantColor)]), startPoint: .top, endPoint: .bottom))
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 16){
            Image(viewModel.appLogo)
                .resizable()
                .scaledToFit()
                .frame(height: 48.0)

            VStack(spacing: 0){
                Text(viewModel.headerTopTitle)
                    .font(.clearFaceFont(for: .regular, with: fontSize))
                HStack(spacing: 0){
                    Text(viewModel.headerbottomfirstTitle)
                        .font(.clearFaceFont(for: .regular, with: fontSize))
                    Text("\(viewModel.headerbottomsecondTitle) ")
                        .font(.clearFaceFont(for: .regularItalic, with: fontSize))
                }
            }
        }
        .foregroundColor(.black)
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
//        .macOnlyPlainButtonStyle()
        .shadow(color: .appColor(.welcomeBtnColor).opacity(0.24), radius: 16.0, x: 0, y: 12.0)
        .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: 0.93))
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
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
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
                                    .padding(.top, idiom == .phone ? 90 : 120)
                                    .padding(.horizontal, 23)
                            }
                    }
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

