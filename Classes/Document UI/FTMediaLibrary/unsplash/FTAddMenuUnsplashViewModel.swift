//
//  FTAddMenuUnsplashViewModel.swift
//  Noteshelf
//
//  Created by srinivas on 13/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//


import UIKit
import Combine
import SDWebImage
import FTNewNotebook
import MobileCoreServices

/// Search  ->
/// 1) seach -> new list
/// 2) loadmore -> append to old list
///
/// Category  -> loadmore
///  1) category -> new list
///  2) loadmore -> append to old list

//@MainActor
class FTAddMenuUnsplashViewModel {
    var searchText = CurrentValueSubject<String, Never>("")
    var items = CurrentValueSubject<[FTUnSplashItem], Never>([FTUnSplashItem]())
    var subscriptions = Set<AnyCancellable>()
    var errorText: ((String?) -> Void)?
    
    typealias downloadResult = (([UIImage], Error?) -> Void)
    
    private var errorDesc: String? {
        didSet {
            errorText?(errorDesc)
        }
    }
    
    var isFeteching = CurrentValueSubject<Bool, Never>(false)

    let api = FTUnsplashAPI()
    
    init() {
        searchText
            .filter { !$0.isEmpty }
            .sink { [weak self] keyword in
                guard let self = self else { return }
                if !keyword.isEmpty {
                    let _ = Task {
                        do {
                            debugPrint("case 1 send request..")
                            let list = try await self.api.fetchUnsplashData(with: keyword)
                            guard let list = list else {
                                return
                            }
                            await MainActor.run {
                                debugPrint(" case 1 received items...")
                                /// category case
                                self.items.value = list
                            }
                        } catch {
                           
                            await MainActor.run {
                                debugPrint("case 1 catch error : \(error.localizedDescription)")
                                self.errorDesc = error.localizedDescription
                            }
                        }
                    }
//                    task.cancel()
                }
            }.store(in: &subscriptions)
    }
    

    
    func fetchUnsplash(pageNo: Int = 1) async {
        let keyword = searchText.value
        debugPrint("loadmore send request \(keyword)")
        isFeteching.value = true
        do {
            let list = try await api.fetchUnsplashData(with: keyword, page: pageNo)
            guard let list = list else {
                isFeteching.value = false
                return
            }
            await MainActor.run {
                debugPrint("loadmore received items...")
                self.isFeteching.value = false
                /// Load more case
                self.items.value.append(contentsOf: list)
            }
            
        } catch {
            await MainActor.run {
                isFeteching.value = false
                debugPrint("case 2 catch error : \(error.localizedDescription)")
                errorDesc = error.localizedDescription
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
            .sink { completion in
                debugPrint("completion")
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        errorSubject.send(error) // Send the error to the errorSubject
                        break
                }
            } receiveValue: { images in
                debugPrint("received : \(images.count)")
                completion(images, nil)
            }.store(in: &subscriptions)

        // Observe the errorSubject to capture the error
        errorSubject
            .sink(receiveValue: { error in
                completion([], error)
            })
            .store(in: &subscriptions)
    }
    
    private func downloadImage(item: FTUnSplashItem) -> AnyPublisher<UIImage, Error> {
        
        return Future { [self] promise in
            if let image = SDImageCache.shared.imageFromCache(forKey: item.id) {
                debugPrint(" found in cache..\(item.id)")
                promise(.success(image))
            } else {
                guard let urlString = item.urls?.regular else { return }
                _ = Task {
                    do {
                        let image = try await api.downloadImage(with: urlString)
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
