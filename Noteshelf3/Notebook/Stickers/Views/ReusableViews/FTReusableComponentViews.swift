//
//  FTReusableComponentViews.swift
//  StickerModule
//
//  Created by Rakesh on 24/03/23.
//

import SwiftUI
import FTStyles
import MobileCoreServices

struct StickerNavigationView: View {
    let name: String
    var toHideBackButton: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        HStack{
            HStack(alignment: .center){
                if !toHideBackButton {
                    Button {presentationMode.wrappedValue.dismiss() } label: {
                        Image(icon: .leftArrow)
                            .font(Font.appFont(for: .regular, with: 20))
                            .fontWeight(.medium)
                            .foregroundColor(Color.appColor(.accent))
                    }
                    .padding(.leading,0)
                    .padding(.trailing,20)
                }
            }
            Spacer()
            Text(name.localized)
                .font(.clearFaceFont(for: .medium, with: 20))
                .padding(.leading,-30)

            Spacer()
        }
        .padding()
    }
}
struct StickerTileView: View {
    let image: UIImage
    let isFromRecent: Bool
    let title: String

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: isFromRecent ? 100 : 75,height: isFromRecent ? 100 : 75)
        }
        .padding(8)
        .background((title.contains("Doodle")) ? Color.white.opacity(0.7) : ((title.contains("Dark")) ? Color.black : Color.clear))
        .cornerRadius(8)
         .onDrag {
             return NSItemProvider(object:FTNSItemProviderImage(image: image))
         }        
    }
}

struct CategoryTitleHeaderView: View {
    let titleName: String
    
    var body: some View {
        Text(titleName.localized)
            .font(.clearFaceFont(for: .medium, with: 20))
            .foregroundColor(Color.appColor(.black1))
    }
}
struct FancyStickerView: View {
    let image: UIImage

    var body: some View {
            Image(uiImage: image)
            .padding(.leading,10)

    }
}
struct FancyStickerSearchBarView: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            TextField("Write something", text: $searchText)
                .padding(.leading, 8)
            Button(action: {
                self.searchText = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .opacity(searchText == "" ? 0 : 1)
                    .foregroundColor(.gray).opacity(0.5)
            }
            .padding(.trailing, 8)
        }
        .frame(height: 36)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct StickerCategoryTileView: View {
    let image: UIImage
    let title: String?
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120,height: 120)
                .cornerRadius(8)
            
            Text(title?.localized ?? "")
                .appFont(for: .medium, with: 13)
                .foregroundColor(Color.appColor(.black1))
        }
    }
}

struct FTStickerDeleteImage:View{
    let imagename: String
    
    var body: some View {
        ZStack{
            Image(systemName: imagename)
                .frame(width: 25, height: 25)
                .foregroundColor(Color.appColor(.darkRed))
                .background(Color.white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.appColor(.grayDim), lineWidth: 0.75)
                )
        }
    }
}

struct FTReusableComponentViews_Previews: PreviewProvider {
    static var previews: some View {
        FTStickerDeleteImage(imagename: "")
    }
}

class FTNSItemProviderImage: NSObject, NSItemProviderWriting {
   private var image: UIImage
    init(image: UIImage) {
        self.image = image
    }
    
    static var writableTypeIdentifiersForItemProvider: [String] {
        return [kUTTypePNG as String]
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 1)
            let imageData = image.pngData()
            completionHandler(imageData, nil)
        return progress
    }
}

