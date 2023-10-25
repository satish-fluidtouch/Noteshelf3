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
    @State private var orientation = UIDevice.current.orientation

    private var gridItems: [GridItem] {
        let isSidebarOpen = FTUserDefaults.isSidebarOpen()
        let isPortrait = orientation.isPortrait
        var numberOfColumns: Int
        if isSidebarOpen {
            numberOfColumns = isPortrait ? 3 : 4
        } else {
            numberOfColumns = isPortrait ? 4 : 5
        }
        if horizontalSizeClass == .compact {
            numberOfColumns = 2
        }
        return Array(repeating: GridItem(.flexible(minimum:50), spacing: 2), count: numberOfColumns)
    }
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .loaded:
                contentView
                    .detectOrientation($orientation)
            case .empty:
                emptyStateView
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
                LazyVGrid(columns: gridItems, spacing: 2) {
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
        let isSidebarOpen = FTUserDefaults.isSidebarOpen()
        let isPortrait = orientation.isPortrait
        var itemsPerRow: CGFloat
        if isSidebarOpen {
            itemsPerRow = isPortrait ? 3 : 4
        } else {
            itemsPerRow = isPortrait ? 4 : 5
        }
        if horizontalSizeClass == .compact {
            itemsPerRow = 2
        }
        let iterimSpacing: CGFloat = (itemsPerRow - 1)*cellSpacing
        let width: CGFloat = (viewSize.width-iterimSpacing)/itemsPerRow
        let size = CGSize(width: width, height: width)
        return size
    }
}

struct MediaItemView: View {
    let media: FTShelfMedia

    var body: some View {
        AsyncImage(url: media.imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } placeholder: {
            Color.gray
                .opacity(0.3)
                .overlay {
                    ProgressView()
                }
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
