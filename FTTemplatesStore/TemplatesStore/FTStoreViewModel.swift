//
//  FTStoreViewModel.swift
//  FTTemplates
//
//  Created by Siva on 15/02/23.
//

import UIKit
import Combine

enum FTStoreSectionType: Int {
    case banner = 0
    case category = 1
    case templates = 2
    case stickers = 3
    case journals = 4
    case userJournals = 5
}

internal typealias TemplatesStoreDatasource = UITableViewDiffableDataSource<Int, Discover>
internal typealias TemplatesStoreSnapshot = NSDiffableDataSourceSnapshot<Int, Discover>

class FTStoreViewModel {
    enum Input {
        case reloadTableView
    }

    enum Output {
        case fetchTemplatesDidSuccess
        case fetchTemplatesDidFail(error: FTTemplatesServiceError)
    }

    private let storeServiceApi: FTLocalServiceApi
    private var cancellables = Set<AnyCancellable>()
    private var input: PassthroughSubject<FTStoreViewModel.Input,Never> = .init()
    private let output: PassthroughSubject<Output, Never> = .init()

    var datasource: TemplatesStoreDatasource!
    var snapshot = TemplatesStoreSnapshot()

    init(storeServiceApi: FTLocalServiceApi = FTLocalService()) {
        self.storeServiceApi = storeServiceApi
    }

    func reloadTableView() {
        input.send(.reloadTableView)
    }

    func transform() -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            switch event {
            case .reloadTableView:
                self?.handleTemplatesStore()
            }
        }.store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }

    func storeSectionInfo(at section: Int) -> StoreInfo? {
        let sectionType = self.snapshot.sectionIdentifiers[section]
        let sectionItem = self.snapshot.itemIdentifiers(inSection: sectionType).first
        return sectionItem
    }
    
    func sectionForInspirations() -> Int {
        return self.snapshot.itemIdentifiers.firstIndex { $0.sectionType == FTStoreSectionType.userJournals.rawValue } ?? 0
    }

    func sectionForBanners() -> Int {
        return self.snapshot.itemIdentifiers.firstIndex { $0.sectionType == FTStoreSectionType.banner.rawValue } ?? 0
    }

    private func handleTemplatesStore() {
        storeServiceApi.fetchTemplates().sink {[weak self] completion in
            if case .failure(let error) = completion {
                self?.output.send(.fetchTemplatesDidFail(error: error))
            }
        } receiveValue: { [weak self] response in
            let discovers = response.discover
            guard let self = self else {
                return
            }
            guard self.datasource != nil else { return }

            self.snapshot.deleteAllItems()

            if discovers.isEmpty {
                self.datasource.apply(self.snapshot, animatingDifferences: true)
                return
            }
            for (index, discover) in discovers.enumerated() {
                self.snapshot.appendSections([index])
                self.snapshot.appendItems([discover], toSection: index)
            }
            self.datasource.apply(self.snapshot, animatingDifferences: true)
            self.output.send(.fetchTemplatesDidSuccess)
        }.store(in: &cancellables)
    }

}
