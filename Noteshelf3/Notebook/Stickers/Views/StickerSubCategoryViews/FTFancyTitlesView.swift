//
//  FTFancyTitlesView.swift
//  Noteshelf3
//
//  Created by Rakesh on 25/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTFancyTitlesView: View {
    let stickerSubCategory: FTStickerSubCategory?
    var model: FTStickerCategoriesViewModel?
    @ObservedObject var viewModel = FTStickerRecentItemViewModel()
    @State private var searchText:String = "Write Something..."
    @StateObject var fancytitleviewModel = FTFancyTitlesViewModel()


    var body: some View {
        VStack{
            StickerNavigationView(name: stickerSubCategory?.title ?? "")
            FancyStickerSearchBarView(searchText: $searchText)
            GeometryReader { geometry in
                ScrollView(.vertical,showsIndicators: false){
                    LazyVStack(alignment: .leading, spacing: 30){
                        let fancystickers = loadFancyStickerItems()
                        var newImage = UIImage()
                        ForEach(fancystickers,id: \.self){ item in
                            FancyStickerView(image: fancytitleviewModel.getImage(fancytitlemodel: item, viewWidth: geometry.size.width - 20, searchText: searchText))
                                .onTapGesture {
                                    newImage = getFullImage(searchText: searchText,item:item)
                                    model?.stickerDelegate?.didTapSticker(with: newImage)
                                }
                                .onDrag {
                                    return NSItemProvider(object:FTNSItemProviderImage(image: newImage))
                                }
                        }
                    }
                }
                .padding(10)
            }
        }
        .navigationBarHidden(true)
    }

    private func getFullImage(searchText:String,item:FancytitleModel) -> UIImage {

        let trimmedText =  FTFancyTitleGenerator().formatString(for: NSAttributedString(string: searchText), item: FTFancyFonts(rawValue: item.fontName)!, font: UIFont(name: item.fontName, size: 40.0) ?? UIFont())

        var text:NSAttributedString =  NSAttributedString()
        if item.fontName == FTFancyFonts.BistroSansLine.rawValue{
            text = FTFancyTitleGenerator().newStringForBistroFontForSize(size: item.fontSize, string: trimmedText)
        }else{
            text =  trimmedText
        }
        guard let newImage =  FTFancyTitleGenerator().generateImage(for: text, with:FTFancyItem(selectedFont: UIFont(name:item.fontName, size: item.fontSize) ?? UIFont(), selectedStyle: item.selectedStyle, selectedColor:item.selectedColor, size: item.fontSize, selectedGradient: item.selectedGradient, selectedFontStyle: .Chiprush, plainText: searchText), viewwidth: UIScreen.main.bounds.size.width) else { return UIImage() }
        return newImage
    }

    private func loadFancyStickerItems() -> [FancytitleModel]{

        var fontName:String = ""
        var fontSize:CGFloat = 0.0

        switch stickerSubCategory?.title ?? ""{
        case FancytitlesCategoryNames.superBold.rawValue:
            fontName = FTFancyFonts.Garfolk.rawValue
            fontSize =  40.0
        case FancytitlesCategoryNames.doubleLine.rawValue:
            fontName = FTFancyFonts.AlonaManhatan.rawValue
            fontSize =  50.0
        case FancytitlesCategoryNames.handWritten.rawValue:
            fontName = FTFancyFonts.HighLow.rawValue
            fontSize =  40.0
        case FancytitlesCategoryNames.serif.rawValue:
            fontName = FTFancyFonts.Chiprush.rawValue
            fontSize =  40.0
        case FancytitlesCategoryNames.quirky.rawValue:
            fontName = FTFancyFonts.BistroSansLine.rawValue
            fontSize =  50.0
        case FancytitlesCategoryNames.outline.rawValue:
            fontName = FTFancyFonts.CatalinaAvalonSans.rawValue
            fontSize =  50.0
        case FancytitlesCategoryNames.brush.rawValue:
            fontName = FTFancyFonts.memorita.rawValue
            fontSize =  50.0
        case FancytitlesCategoryNames.fluid.rawValue:
            fontName = FTFancyFonts.memorita.rawValue
            fontSize =  50.0
        default:
            break
        }

        let fancyStickerImages:[FancytitleModel] = [
            FancytitleModel(fontName: fontName, selectedStyle: .style2, selectedColor: " ", selectedGradient: .blue, fontSize: fontSize),
            FancytitleModel(fontName: fontName, selectedStyle: .style3, selectedColor: " ", selectedGradient: .green, fontSize: fontSize),
            FancytitleModel(fontName: fontName, selectedStyle: .style3, selectedColor: " ", selectedGradient: .blue, fontSize: fontSize),
            FancytitleModel(fontName: fontName, selectedStyle: .style3, selectedColor: " ", selectedGradient: .mint, fontSize: fontSize),
            FancytitleModel(fontName: fontName, selectedStyle: .style1, selectedColor: "#0E4BC1", selectedGradient: .blue, fontSize: fontSize),
            FancytitleModel(fontName: fontName, selectedStyle: .style1, selectedColor: "#C1390E", selectedGradient: .blue, fontSize: fontSize),
            FancytitleModel(fontName: fontName, selectedStyle: .style1, selectedColor: "#880EC1", selectedGradient: .blue, fontSize: fontSize)
        ]
        return fancyStickerImages
    }

}
