//
//  StickersCategoriesView.swift
//  ShowStickers
//
//  Created by Rakesh on 01/03/23.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

public protocol FTStickerdelegate : AnyObject {
    func didTapSticker(with image:UIImage)
    func dismiss()
}


struct FTStickerCategoriesView: View {
    
    @ObservedObject var viewModel : FTStickerCategoriesViewModel
    var downloadedViewModel : FTDownloadedStickerViewModel

    @State private var selection: String = ""
    var toHideBackButton: Bool = false

    private let detector: CurrentValueSubject<CGFloat, Never>
    private let publisher: AnyPublisher<CGFloat, Never>
    
    init(model: FTStickerCategoriesViewModel, downloadedViewModel: FTDownloadedStickerViewModel ) {
        let detector = CurrentValueSubject<CGFloat, Never>(0)
        self.publisher = detector
            .debounce(for: .seconds(0.2), scheduler: DispatchQueue.main)
            .dropFirst()
            .eraseToAnyPublisher()
        self.detector = detector
        self.viewModel =  model
        self.downloadedViewModel = downloadedViewModel
        
    }
    
    var body: some View {
        ScrollViewReader{ proxy in
            VStack {
                VStack(spacing: 0){
                    StickerNavigationView(name: "stickersTitle".localized, toHideBackButton: toHideBackButton)
                    FTStickerSegmentedView(selection: $selection, onTapMenu: { selectedmenu in
                        withAnimation{
                            proxy.scrollTo(selectedmenu as String?,anchor: .top)
                        }
                    }).padding(.horizontal,16).padding(.bottom,10)
                }
                ScrollView(showsIndicators: false) {
                    VStack{
                        FTStickerCategoryRecentView()
                            .id("Recents")
                            .padding(.bottom,10)
                        
                        ForEach(viewModel.stickerCategoryModel, id: \.type) { sticker in
                            FTStickerCategoryItemView(stickerCategoryModel:sticker, stickerViewModel: viewModel)
                                .padding(.bottom,10)
                                .id(sticker.title)
                        }
                        if !downloadedViewModel.downloadedStickers.isEmpty {
                            FTDownloadedStickersView(downloadedviewModel: downloadedViewModel, stickerCategoryViewModel: viewModel)
                                .id("downloadedStickers".localized)
                        }
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: FTViewOffsetKey.self,
                                               value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(FTViewOffsetKey.self) { detector.send($0)  }
                }
                .coordinateSpace(name: "scroll")
                .onReceive(publisher) {
                    let value = getSectiontitle(offset: $0)
                    switch value {
                    case 0:
                        selection = viewModel.menuItems[0]
                    case 1:
                        selection = viewModel.menuItems[1]
                    case 2:
                        selection = viewModel.menuItems[2]
                    case 3:
                        selection = viewModel.menuItems[3]
                    case 4:
                        selection = viewModel.menuItems[4]
                    case 5:
                        selection = viewModel.menuItems[5]
                    default:
                        selection = viewModel.menuItems[6]
                    }
                }
                
                .onChange(of: selection) { _ in
                    withAnimation {
                        proxy.scrollTo(selection,anchor: .center)
                    }
                }
                
                .padding(.leading,10)
                .padding(.bottom,20)
                .onFirstAppear {
                    viewModel.getRecents()
                    viewModel.getStickers()
                    downloadedViewModel.validateAndGetDownloadedStickers()
                }
            }
            .environmentObject(viewModel)
        }
    }
    
    private func getSectiontitle(offset:Double)->Int{
        let value = offset/172
        let valueInString = "\(value)".split(separator: ".")
        return Int(valueInString[0].first?.description ?? " ") ?? 0
    }
}

struct FTViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}


