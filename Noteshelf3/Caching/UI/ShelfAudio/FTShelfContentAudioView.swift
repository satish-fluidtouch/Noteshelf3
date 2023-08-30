//
//  FTShelfContentAudioView.swift
//  Noteshelf3
//
//  Created by Akshay on 09/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShelfContentAudioView: View {
    @ObservedObject var viewModel: FTShelfContentAudioViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    private var gridItems: [GridItem] {
        var numberOfColoums = 4
        if horizontalSizeClass == .compact {
            numberOfColoums = 3
        }
        return Array(repeating: GridItem(.flexible(minimum:50), spacing: 2), count: numberOfColoums)
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
            }
        }
        .padding(.horizontal, 0)
        .onFirstAppear {
            Task {
                await viewModel.buildCache()
            }
        }
    }

    let gradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: Color.appColor(.black50), location: 0),
            .init(color: .clear, location: 0.4)
        ]),
        startPoint: .bottom,
        endPoint: .top
    )

    var contentView: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVGrid(columns: gridItems, spacing: 2) {
                    ForEach(viewModel.audio) { audio in
                        let size = itemSize(for: proxy.size)
                        FTShelfAudioItemView(audio: audio)
                            .frame(width: size.width, height: size.width)
                            .clipped()
                            .overlay(alignment: .bottomLeading) {
                                gradient
                                    .blur(radius: 20) /// blur the overlay
                                    .padding(-20) /// expand the blur a bit to cover the edges
                                    .clipped() // prevent blur overflow
                            }
                            .onTapGesture {
                                viewModel.onSelect?(audio)
                                track(EventName.shelf_recording_page_tap, screenName: ScreenName.shelf_recordings)
                            }
                            .contextMenu {
                                Button {
                                    viewModel.openInNewWindow?(audio)
                                    track(EventName.shelf_recording_openinnewwindow_tap, screenName: ScreenName.shelf_recordings)
                                } label: {
                                    Text("OpenInNewWindow".localized)
                                }
                            } preview: {
                                FTAudioPreviewPageView(audio: audio)
                                    .onAppear {
                                        track(EventName.shelf_recording_page_longpress, screenName: ScreenName.shelf_recordings)
                                    }
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        FTNoResultsView(noResultsImageName: "noRecordings", title: NSLocalizedString("shelf.trash.noRecordingsTitle", comment: "Record some audio"), description: NSLocalizedString("shelf.trash.noRecordingsDescrption", comment: "Pages with audio recordings will appear here."))
    }

    private func itemSize(for viewSize: CGSize) -> CGSize {
        let cellSpacing: CGFloat = 2
        var itemsPerRow: CGFloat = 4
        if horizontalSizeClass == .compact {
            itemsPerRow = 3
        }

        let iterimSpacing: CGFloat = (itemsPerRow - 1)*cellSpacing

        let width: CGFloat = (viewSize.width-iterimSpacing)/itemsPerRow
        let size = CGSize(width: width, height: width)
        return size
    }
}

struct FTShelfAudioItemView: View {

    let audio: FTShelfAudio

    var body: some View {
        if audio.isProtected {
            Color.gray
                .opacity(0.3)
                .overlay {
                    Image(systemName: "lock")
                }
        } else {
            Color(.appColor(.accent)).overlay(content: {
                VStack(spacing: 4) {
                    Image(systemName: "volume.2.fill")
                        .font(.title)
                    Text(audio.duration)
                }
                .appFont(for: .medium, with: 10)
                .foregroundColor(Color.white)
            })
        }
    }
}

struct FTAudioPreviewPageView: View {
    let audio: FTShelfAudio
    @State var isLoading: Bool = true
    @State var image: UIImage = UIImage(systemName: "volume.2.fill")!

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
        guard let docItem = audio.document else {
            return
        }

        let openRequest = FTDocumentOpenRequest(url: docItem.URL, purpose: .read);
        FTNoteshelfDocumentManager.shared.openDocument(request: openRequest) { (token, document, error) in
            if let doc = document {
                doc.pages()[audio.page].thumbnail()?.thumbnailImage(onUpdate: { thumb, _ in
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


struct FTShelfContentAudioView_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfContentAudioView(viewModel: FTShelfContentAudioViewModel())
    }
}
