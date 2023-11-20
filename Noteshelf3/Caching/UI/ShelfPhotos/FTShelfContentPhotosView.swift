//
//  FTShelfContentPhotosView.swift
//  Noteshelf
//
//  Created by Akshay on 21/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShelfContentPhotosView: View  {
    @ObservedObject var viewModel: FTShelfContentPhotosViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    private func gridItems(size viewSize: CGSize) -> [GridItem] {
        var numberOfColumns: Int
        numberOfColumns =  (viewSize.width > 1125) ? 6 : (viewSize.width > 1023 ? 5 : (viewSize.width > 700 ? 4 : 3))
        numberOfColumns = horizontalSizeClass == .compact ? 2 : numberOfColumns
        return Array(repeating: GridItem(.flexible(minimum:50), spacing: 2), count: numberOfColumns)
    }
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .loaded:
                contentView
            case .empty:
                emptyStateView
            case .partiallyLoaded:
                if !viewModel.media.isEmpty {
                    contentView
                } else {
                    ProgressView()
                }
            }
        }
        .padding(.horizontal, 0)
            .onFirstAppear {
            Task {
                await viewModel.buildCache()
            }
        }
    }

    var contentView: some View {
         GeometryReader { proxy in
            ScrollView {
                LazyVGrid(columns: gridItems(size: proxy.size), spacing: 2) {
                    ForEach(viewModel.media, id: \.id) { media in
                        let size = itemSize(for: proxy.size)
                        MediaItemView(media: media)
                            .frame(width: size.width, height: size.width)
                            .clipped()
                            .overlay(alignment: .bottomLeading) {
                                Image("gradient")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width, height: size.width/2)
                                    .clipped()
                            }
                            .overlay(alignment: .bottomLeading) {
                                Text(media.title)
                                    .appFont(for: .medium, with: 15)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(1)
                                    .foregroundColor(Color.white)
                                    .padding(.all,8)
                            }
                            .onAppear {
                                media.fetchImage()
                            }
                            .onDisappear {
                                media.unloadImage()
                            }
                            .onTapGesture {
                                viewModel.onSelect?(media)
                                track(EventName.shelf_photo_page_tap, screenName: ScreenName.shelf_photos)
                            }
                            .contextMenu {
                                Button {
                                    viewModel.openInNewWindow?(media)
                                    track(EventName.shelf_photo_openinnewwindow_tap, screenName: ScreenName.shelf_photos)
                                } label: {
                                    Text("OpenInNewWindow".localized)
                                }
                            } preview: {
                                FTMediaPreviewPageView(media: media)
                                    .onAppear {
                                        track(EventName.shelf_photo_page_longpress, screenName: ScreenName.shelf_photos)
                                    }
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        FTNoResultsView(noResultsImageName: "noPhotos", title: NSLocalizedString("shelf.trash.noPhotosTitle", comment: "No photos"), description: NSLocalizedString("shelf.trash.noPhotosDescrption", comment: "Pages with photos will appear here"))
    }

    private func itemSize(for viewSize: CGSize) -> CGSize {
        let cellSpacing: CGFloat = 2
        var itemsPerRow: CGFloat
        itemsPerRow =  (viewSize.width > 1125) ? 6 : (viewSize.width > 1023 ? 5 : (viewSize.width > 700 ? 4 : 3))
        itemsPerRow = horizontalSizeClass == .compact ? 2 : itemsPerRow
        let iterimSpacing: CGFloat = (itemsPerRow - 1)*cellSpacing
        let width: CGFloat = (viewSize.width-iterimSpacing)/itemsPerRow
        let size = CGSize(width: width, height: width)
        return size
    }
}

struct MediaItemView: View {
    @ObservedObject var media: FTShelfMedia

    var body: some View {
        if let image = media.mediaImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } else {
            Color.gray
                .opacity(0.3)
        }
    }
}

struct FTMediaPreviewPageView: View {
    let media: FTShelfMedia
    @State var isLoading: Bool = true
    @State var image: UIImage = UIImage(systemName: "photo")!

    var body: some View {
        if isLoading {
            Color.gray
                .opacity(0.3)
                .overlay {
                    ProgressView()
                }
                .onAppear(perform: {
                    fetchThumbnail()
                })
        } else {
            Image(uiImage: image)
        }
    }

    private func fetchThumbnail() {
        guard let docItem = media.document else {
            return
        }

        let openRequest = FTDocumentOpenRequest(url: docItem.URL, purpose: .read);
        FTNoteshelfDocumentManager.shared.openDocument(request: openRequest) { (token, document, error) in
            if let doc = document {
                doc.pages()[media.page].thumbnail()?.thumbnailImage(onUpdate: { thumb, _ in
                    if let thumb = thumb {
                        image = thumb
                    }
                    FTNoteshelfDocumentManager.shared.closeDocument(document: doc, token: token) { isClosed in
                        cacheLog(.info, "isClosed", isClosed)
                    }
                    isLoading = false
                })
            } else {
                isLoading = false
            }
        }

    }
}

struct FTShelfContentPhotosView_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfContentPhotosView(viewModel: FTShelfContentPhotosViewModel())
    }
}
