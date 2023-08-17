//
//  FTAddMenuPixabayViewModel.swift
//  Noteshelf
//
//  Created by srinivas on 17/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage
import MobileCoreServices
import Combine
import FTNewNotebook

class FTAddMenuPixabayViewModel {
    
    var searchText = CurrentValueSubject<String, Never>("")
    var items = CurrentValueSubject<[FTMediaLibraryModel], Never>([FTMediaLibraryModel]())
    
    
    private let manager = FTMediaLibraryManager()
    
    var subscriptions = Set<AnyCancellable>()
    
    var errorText: ((String?) -> Void)?
    
    typealias downloadResult = (([UIImage], Error?) -> Void)
    
    private var errorDesc: String? {
        didSet {
            errorText?(errorDesc)
        }
    }
    
    fileprivate let clipartFilter = FTPixabayClipartFilter()
    
    var isFeteching = CurrentValueSubject<Bool, Never>(false)
    
    let api = FTUnsplashAPI()
    
    init() {
        searchText
            .filter { !$0.isEmpty }
            .sink { [weak self] keyword in
                guard let self = self else { return }
                if !keyword.isEmpty {
                    let _ = Task {
                            self.manager.searchPixabay(type: FTPixabayResponseModel.self,
                                                       service: FTPixabayPostService.search(query: keyword, imageType: "Wallpapers", sort: .popular, amount: 20, page: 1)) { response in
                               
                                DispatchQueue.main.async {
                                    switch response {
                                        case let .successWith(posts):
                                            let mediaLibraryArray = posts.hits.map { $0.asOpenMediaLibrary() }
                                            let filtered = self.clipartFilter.filterClipart(mediaLibraryArray)
                                            self.items.value = filtered
                                        case let .failureWith(error):
                                        self.errorDesc = error.rawValue
                                    }
                                }
                            }
                    }
                }
            }.store(in: &subscriptions)
    }
    
    
    func fetchPixabay(pageNo: Int = 1) async {
        let keyword = searchText.value
        manager.searchPixabay(type: FTPixabayResponseModel.self,
                              service: FTPixabayPostService.search(query: keyword, imageType: keyword, sort: .popular, amount: 20, page: pageNo)) { response in
            switch response {
                case let .successWith(posts):
                    print("posts \(posts)")
                    let mediaLibraryArray = posts.hits.map { $0.asOpenMediaLibrary() }
                    let filtered = self.clipartFilter.filterClipart(mediaLibraryArray)
                    DispatchQueue.main.async {
                        self.items.value.append(contentsOf: filtered)
                    }
                case let .failureWith(error):
                    print("error \(error)")
            }
        }
        
    }
    

    func downloadItemAt(indices: [Int], _ completion: @escaping downloadResult) {
        let errorSubject = PassthroughSubject<Error, Never>()
        indices.publisher
            .compactMap { items.value[$0] }
            .flatMap { item in
                return self.downloadImage(item: item)
            }
            .collect()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    errorSubject.send(error) // Send the error to the errorSubject
                }
            }, receiveValue: { images in
                completion(images, nil)
            }).store(in: &subscriptions)
        // Observe the errorSubject to capture the error
        errorSubject
            .sink(receiveValue: { error in
                completion([], error)
            })
            .store(in: &subscriptions)
    }
    
    private func downloadImage(item: FTMediaLibraryModel) -> AnyPublisher<UIImage, Error> {
        
        return Future { [self] promise in
            if let image = SDImageCache.shared.imageFromCache(forKey: item.id) {
                debugPrint(" found in cache..\(item.id)")
                promise(.success(image))
            } else {
                let urlString = item.urls?.png_thumb
                _ = Task {
                    do {
                        let image = try await api.downloadImage(with: urlString!)
                        if let image = image {
                            await SDImageCache.shared.store(image, forKey: item.id)
                            debugPrint(" add to cache..\(item.id)")
                            await MainActor.run {
                                promise(.success(image))
                            }
                        }
                    } catch {
                        debugPrint("downloadItemAt catch block \(error.localizedDescription)")
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
        
    }
    
    func fetchSegmentItems() -> [FTMediaCategoryProtocol] {
        
        var arItems = [FTMediaCategoryProtocol]()
        
        arItems.append(USRecentSegmentItem())
        arItems.append(USFeaturedSegmentItem())
        arItems.append(USWallpapersSegmentItem())
        arItems.append(USTravelSegmentItem())
        arItems.append(USNatureSegmentItem())
        arItems.append(USTexturesSegmentItem())
        arItems.append(USBusinessSegmentItem())
        arItems.append(USTechnologySegmentItem())
        arItems.append(USAnimalsSegmentItem())
        arItems.append(USInteriorsSegmentItem())
        arItems.append(USFoodSegmentItem())
        arItems.append(USAthleticsSegmentItem())
        arItems.append(USHealthSegmentItem())
        arItems.append(USFilmSegmentItem())
        arItems.append(USFashionSegmentItem())
        arItems.append(USArtsSegmentItem())
        arItems.append(USHistorySegmentItem())
        return arItems
    }
}
