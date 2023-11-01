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
    @State private var orientation = UIDevice.current.orientation

    private func gridItems(size viewSize: CGSize) -> [GridItem] {
        let isPortrait = orientation.isPortrait
        var numberOfColoums: Int
        numberOfColoums = viewSize.width > 1023 ? 5 : viewSize.width > 700 ? 4 : 3
        return Array(repeating: GridItem(.flexible(minimum:50), spacing: 2), count: numberOfColoums)
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
                LazyVGrid(columns: gridItems(size: proxy.size), spacing: 2) {
                    ForEach(viewModel.audio) { audio in
                        let size = itemSize(for: proxy.size)
                        FTShelfAudioItemView(audio: audio)
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
                                Text(audio.title)
                                    .appFont(for: .medium, with: 14)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(1)
                                    .foregroundColor(Color.white)
                                    .padding(.all,8)
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
        var itemsPerRow: CGFloat
        itemsPerRow = viewSize.width > 1023 ? 5 : viewSize.width > 700 ? 4 : 3
        itemsPerRow = horizontalSizeClass == .compact ? 2 : itemsPerRow
        let iterimSpacing: CGFloat = (itemsPerRow - 1)*cellSpacing
        let width: CGFloat = (viewSize.width-iterimSpacing)/itemsPerRow
        let size = CGSize(width: width, height: width)
        return size
    }
}

struct FTShelfAudioItemView: View {

    let audio: FTShelfAudio

    var body: some View {
        Color(.appColor(.accent))
            .overlay(content: {
                HStack{
                    VStack(alignment: .leading,spacing: 8) {
                        Image(systemName: "volume.2.fill")
                            .frame(width: 28,height: 24)
                            .   font(.appFont(for: .medium, with: 20))
                        VStack(alignment: .leading,spacing: 2){
                            Text(audio.audioTitle)
                                .lineLimit(2)
                                .foregroundColor(.white)
                            Text(audio.duration)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .appFont(for: .medium, with: 13)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.all,8)
                .appFont(for: .medium, with: 10)
                .foregroundColor(Color.white)
            })
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
