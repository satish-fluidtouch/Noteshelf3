
import SwiftUI
import FTStyles

struct FTToastView:  View {
    @ObservedObject var toastConfig: FTToastConfiguration
    var callbackFunction: () -> Void

    @State private var size: CGSize = .zero

    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text(toastConfig.title)
                        .font(Font(toastConfig.titleFont))
                        .foregroundColor(.primary)
                        .multilineTextStyle(lineLimit: 2, aligment: .center)
                    if !toastConfig.subTitle.isEmpty {
                        Text(toastConfig.subTitle)
                            .font(Font(toastConfig.subTitleFont))
                            .foregroundColor(Color.appColor(.black50))
                            .multilineTextStyle(lineLimit: 2, aligment: .center)
                    }
                }
                if let img = toastConfig.image {
                    Image(uiImage: img.resizedImage(toastConfig.imgSize))
                }
            }
            .padding(.horizontal, toastConfig.horzPadding)
            .padding(.vertical, toastConfig.vertPadding)
        }
        .frame(width: size.width)
        .frame(minHeight: size.height)
        .background(Color.appColor(.toastBgColor))
        .cornerRadius(size.height/2.0)
        .border(Color.appColor(.black10), width: 1.0, cornerRadius: size.height/2.0)
        .shadow(color: Color.primary.opacity(0.2), radius: 60, x: 0, y: 10)
        .onAppear {
            size = toastConfig.getToastSize()
        }
    }
}

struct FTToastView_Previews: PreviewProvider {
    static var previews: some View {
        let config = FTToastConfiguration(title: "fddsfsdfsdfsdfsdfsdfsfsfsfsfsfsfsfsfsfsfsfsf", subTitle: "dhfbjdahsdfsdfsdfds")
        FTToastView(toastConfig: config) {
        }
    }
}

class FTToastConfiguration: ObservableObject {
    let title: String
    var image: UIImage? = nil
    var autoRemovalOfToast = true

    @Published var subTitle: String = ""
    private(set) var titleFont = UIFont.appFont(for: .bold, with: 15)
    private(set) var subTitleFont = UIFont.appFont(for: .regular, with: 13)
    private(set) var animationTime: CGFloat = 0.4
    private(set) var imgSize = CGSize(width: 25.0, height: 15.0)
    private(set) var horzPadding: CGFloat = 28.0
    private(set) var vertPadding: CGFloat = 7.0

    private let contentMaxWidth: CGFloat = 250.0
    private let contentMaxHeight: CGFloat = 200.0
    private let contentMinWidth: CGFloat = 70.0
    private let contentMinHeight: CGFloat = 40.0

    init(title: String, subTitle: String = "", image: UIImage? = nil, autoRemovalOfToast: Bool = true) {
        self.title = title
        self.subTitle = subTitle
        self.image = image
        self.autoRemovalOfToast = autoRemovalOfToast
    }

    func getToastSize() -> CGSize {
        let titleSize = self.getTitleSize()
        let subTitleSize = self.getSubTitleSize()
        var reqWidth = max(min(max(titleSize.width, subTitleSize.width), contentMaxWidth), contentMinWidth) + (2.0 * horzPadding)
        if nil != self.image {
            reqWidth += imgSize.width
        }
        var reqHeight = max(min(titleSize.height + subTitleSize.height, contentMaxHeight), contentMinHeight) + (2.0 * vertPadding)
        if max(titleSize.width, subTitleSize.width) > contentMaxWidth {
            reqHeight += 20.0
        }
        return CGSize(width: reqWidth, height: reqHeight)
    }

    private func getTitleSize() -> (width: CGFloat, height: CGFloat) {
        let width = self.title.widthOfString(usingFont: titleFont)
        let height = self.title.heightOfString(usingFont: titleFont)
        return (width, height)
    }

    private func getSubTitleSize() -> (width: CGFloat, height: CGFloat) {
        let width: CGFloat
        let height: CGFloat
        if subTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            width = 0.0
            height = 0.0
        } else {
            width = self.subTitle.widthOfString(usingFont: subTitleFont)
            height = self.subTitle.heightOfString(usingFont: subTitleFont)
        }
        return (width, height)
    }
}

extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }

    func heightOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.height
    }

    func getHeight(using font: UIFont, width: CGFloat) -> CGFloat {
        let textStorage = NSTextStorage(string: self)
        let textContainter = NSTextContainer(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainter)
        textStorage.addLayoutManager(layoutManager)
        textStorage.addAttribute(NSAttributedString.Key.font, value: font, range: NSMakeRange(0, textStorage.length))
        textContainter.lineFragmentPadding = 0.0
        layoutManager.glyphRange(for: textContainter)
        return layoutManager.usedRect(for: textContainter).size.height
    }
}

extension NSAttributedString {
    func getHeight(using font: UIFont, width: CGFloat) -> CGFloat {
        let textStorage = NSTextStorage(attributedString: self)
        let textContainter = NSTextContainer(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainter)
        textStorage.addLayoutManager(layoutManager)
        textStorage.addAttribute(NSAttributedString.Key.font, value: font, range: NSMakeRange(0, textStorage.length))
        textContainter.lineFragmentPadding = 0.0
        layoutManager.glyphRange(for: textContainter)
        return layoutManager.usedRect(for: textContainter).size.height
    }

}
