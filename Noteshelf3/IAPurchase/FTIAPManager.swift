//
//  FTIAPManager.swift
//  Noteshelf3
//
//  Created by Siva on 14/03/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import StoreKit
import FTCommon
import FTTemplatesStore
import Combine

public typealias ProductIdentifier = String

extension FTPremiumUser {    
    func addObsrversIfNeeded() {
        self.updateNoOfBooks(nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.shelfItemDidAddedRemoved(_:)), name: .shelfItemAdded, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.shelfItemDidAddedRemoved(_:)), name: .shelfItemRemoved, object: nil);
    }
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .shelfItemAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shelfItemRemoved, object: nil)
    }
    
    @objc private func shelfItemDidAddedRemoved(_ notification: Notification?) {
        guard FTNoteshelfDocumentProvider.shared.isProviderReady else {
            return;
        }

        if let collection = notification?.object as? FTShelfItemCollection
            ,collection.isNS2Collection() {
            return;
        }
        self.updateNoOfBooks(nil);
    }
    
    func updateNoOfBooks(_ onCompletion: (() -> ())?) {
        guard FTNoteshelfDocumentProvider.shared.isProviderReady else {
            onCompletion?();
            return;
        }
        if FTNoteshelfDocumentProvider.shared.isContentMovingInProgress() {
            onCompletion?();
            return;
        }
        FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(.none, parent: nil, searchKey: nil) { allItems in
            FTNoteshelfDocumentProvider.shared.trashShelfItemCollection { trashCollection in
                trashCollection.shelfItems(.none, parent: nil, searchKey: nil) { items in
                    self.numberOfBookCreate = allItems.count + items.count;
                    onCompletion?();
                }
            }
        }
    }
    
    func prepare(onCompletion: @escaping (() -> ())) {
        self.updateNoOfBooks(onCompletion);
    }
}

class FTIAPManager: NSObject {
    
    var premiumUser = FTPremiumUser();
    
    // MARK: - Custom Types
    enum FTIAPHelperError: Error {
        case noProductIDsFound
        case noProductsFound
        case paymentWasCancelled
        case productRequestFailed
    }
    
    static var ns2_ns3PremiumIdentifier: String {
#if DEBUG
        return "com.fluidtouch.noteshelf3.devpremium.ns2user"
#elseif ADHOC
        return "com.fluidtouch.noteshelf3.betapremium.ns2user"
#else
        return "com.fluidtouch.noteshelf3_premium.ns2user"
#endif
    }

    static var ns3PremiumIdentifier: String {
#if DEBUG
        return "com.fluidtouch.noteshelf3.devpremium"
#elseif ADHOC
        return "com.fluidtouch.noteshelf3.betapremium"
#else
        return "com.fluidtouch.noteshelf3_premium"
#endif
    }

    // MARK: - Properties
    static let shared = FTIAPManager()
    
    var onReceiveProductsHandler: ((Result<[SKProduct], FTIAPHelperError>) -> Void)?
    var onBuyProductHandler: ((Result<Bool, Error>) -> Void)?
    var totalRestoredPurchases = 0
    private var premiumCancellableEvent: AnyCancellable?;
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self);
        FTStoreContainerHandler.shared.premiumUser = premiumUser
    }
    
    func config() {
        premiumUser.isPremiumUser = FTIAPurchaseHelper.shared.isPremiumUser;
        if !premiumUser.isPremiumUser {
            premiumCancellableEvent = FTIAPManager.shared.premiumUser.$isPremiumUser.sink { [weak self] isPremium in
                if isPremium {
                    self?.premiumUser.removeObservers()
                } else {
                    self?.premiumUser.addObsrversIfNeeded();
                }
            }
        }
    }
}

// MARK: - StoreKit API
extension FTIAPManager {
    func getPriceFormatted(for product: SKProduct) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price)
    }
    
    func startObserving() {
        SKPaymentQueue.default().add(self)
    }
    
    func stopObserving() {
        SKPaymentQueue.default().remove(self)
    }
    
    func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    // MARK: - Get IAP Products
    func getProducts(withHandler productsReceiveHandler: @escaping (_ result: Result<[SKProduct], FTIAPHelperError>) -> Void) {
        // Keep the handler (closure) that will be called when requesting for
        // products on the App Store is finished.
        onReceiveProductsHandler = productsReceiveHandler
        
        // Initialize a product request.
        let request = SKProductsRequest(productIdentifiers: self.iapProductsIdentifier())
        
        // Set self as the its delegate.
        request.delegate = self
        
        // Make the request.
        request.start()
    }
    
    // MARK: - Purchase Products
    func buy(product: SKProduct, withHandler handler: @escaping ((_ result: Result<Bool, Error>) -> Void)) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        
        // Keep the completion handler.
        onBuyProductHandler = handler
    }
    
    func restorePurchases(withHandler handler: @escaping ((_ result: Result<Bool, Error>) -> Void)) {
        onBuyProductHandler = handler
        totalRestoredPurchases = 0
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
}

// MARK: - SKPaymentTransactionObserver
extension FTIAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { (transaction) in
            switch transaction.transactionState {
            case .purchased:
                onBuyProductHandler?(.success(true))
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .restored:
                totalRestoredPurchases += 1
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                if let error = transaction.error as? SKError {
                    if error.code != .paymentCancelled {
                        onBuyProductHandler?(.failure(error))
                    } else {
                        onBuyProductHandler?(.failure(FTIAPHelperError.paymentWasCancelled))
                    }
                    print("IAP Error:", error.localizedDescription)
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .deferred, .purchasing: break
            @unknown default: break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if totalRestoredPurchases != 0 {
            onBuyProductHandler?(.success(true))
        } else {
            print("IAP: No purchases to restore!")
            onBuyProductHandler?(.success(false))
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        if let error = error as? SKError {
            if error.code != .paymentCancelled {
                print("IAP Restore Error:", error.localizedDescription)
                onBuyProductHandler?(.failure(error))
            } else {
                onBuyProductHandler?(.failure(FTIAPHelperError.paymentWasCancelled))
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true;
    }
}

// MARK: - SKProductsRequestDelegate
extension FTIAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Get the available products contained in the response.
        let products = response.products
        
        // Check if there are any products available.
        if products.count > 0 {
            // Call the following handler passing the received products.
            onReceiveProductsHandler?(.success(products))
        } else {
            // No products were found.
            onReceiveProductsHandler?(.failure(.noProductsFound))
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        onReceiveProductsHandler?(.failure(.productRequestFailed))
    }
    
    func requestDidFinish(_ request: SKRequest) {
        // Implement this method OPTIONALLY and add any custom logic
        // you want to apply when a product request is finished.
    }
}

// MARK: - FTIAPHelperError Localized Error Descriptions
extension FTIAPManager.FTIAPHelperError: LocalizedError {
    var errorDescription: String? {
        let message: String
        switch self {
        case .noProductIDsFound:
            message = "iap.noProductIDsFound"
        case .noProductsFound:
            message = "iap.noProductsFound"
        case .productRequestFailed:
            message = "iap.productRequestFailed"
        case .paymentWasCancelled:
            message = "iap.paymentWasCancelled"
        }
        return message.localized
    }
}

extension FTIAPManager {
    func iapProductsIdentifier() -> Set<String> {
        var productsIdentifier = Set<String>();
        productsIdentifier.insert(FTIAPManager.ns3PremiumIdentifier);
        if FTDocumentMigration.isNS2AppInstalled() {
            productsIdentifier.insert(FTIAPManager.ns2_ns3PremiumIdentifier);
        }
        return productsIdentifier
    }
}
