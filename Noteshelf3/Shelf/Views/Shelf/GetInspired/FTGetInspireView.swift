//
//  FTGetInspireView.swift
//  Noteshelf3
//
//  Created by Rakesh on 02/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import PDFKit

struct FTGetInspireView: View {
    @State private var isExpanded:Bool = true
    @StateObject var viewmodel: FTGetInspiredViewModel
    @EnvironmentObject var sheflViewModel: FTShelfViewModel
    let screenScale = UIScreen.main.scale
    var body: some View {
        VStack(alignment: .leading){
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack{
                    ScrollView(.horizontal,showsIndicators: false){
                        HStack(alignment: .top, spacing:0){
                            ForEach(viewmodel.inspiredList,id: \.self){ listitem in
                                VStack(alignment: .center,spacing: 8){
                                    Image(uiImage: listitem.getinspireImage)
                                        .resizable()
                                        .frame(width: 172,height: 230)
                                        .shadow(color: Color.appColor(.black8), radius: 20,x:0,y:12)
                                        .cornerRadius(4, corners: [.topLeft, .bottomLeft])
                                        .cornerRadius(10, corners: [.topRight, .bottomRight])
                                    Text(listitem.titleLocalizationKey.localized)
                                        .foregroundColor(Color.label)
                                        .font(.appFont(for: .medium, with: 16))
                                }
                                .padding(.top,16)
                                .padding(.trailing,16)
                                .padding(.bottom,24)
                                .shadow(color: Color.appColor(.black16), radius:4, x: 0, y: 2)
                                .onTapGesture {
                                    if let previewUrl = listitem.getPreviewUrl(fileName: listitem.pdfName) {
                                        let url =  previewUrl.appendingPathComponent(listitem.pdfName).appendingPathExtension("pdf")
                                        let title = listitem.titleLocalizationKey.localized;
                                        self.sheflViewModel.delegate?.openGetInspiredPDF(url, title: title);
                                    }
                                }
                            }
                        }
                        .padding(.leading,8)
                    }
                }
            } label: {
                Text("shelf.home.getinspired".localized)
                    .font(.clearFaceFont(for: .medium, with: 22))
                    .padding(.leading,8)
            }
            .padding(.top,24)
            .padding(.trailing,24)
            .padding(.leading,16)
            .if(!isExpanded, transform: { view in
                view.padding(.bottom,24)
            })
            .accentColor(.appColor(.black1))
        }
        .background(Color.appColor(.black5))
        .cornerRadius(16)
        .onFirstAppear {
            viewmodel.fetchInspireList()
        }
    }
    private var shadowImage: UIImage? {
        UIImage(named: "coveredNBShadow")
    }
    private var shadowImageView: some View {
        Image(uiImage: shadowImage!.resizableImage(withCapInsets: shadowImageEdgeInsets, resizingMode: .stretch))
    }
    private var shadowImageEdgeInsets: UIEdgeInsets {
        UIEdgeInsets(top: 50/screenScale, left: 60/screenScale, bottom: 95/screenScale, right: 70/screenScale)
    }
    private var coverPadding: EdgeInsets {
        EdgeInsets(top: 16/screenScale, leading: 40/screenScale, bottom: 64/screenScale, trailing: 40/screenScale)
    }
}

struct FTGetInspireView_Previews: PreviewProvider {
    static var previews: some View {
        FTGetInspireView(viewmodel: FTGetInspiredViewModel())
    }
}

