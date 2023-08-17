//
//  FTShelfCollection.swift
//  Noteshelf
//
//  Created by Amar on 17/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTShelfCollection: NSObjectProtocol {

    static func shelfCollection(_ onCompletion : @escaping ((FTShelfCollection?) -> Void));

    func collection(withTitle title: String) -> FTShelfItemCollection?;
    func refreshShelfCollection(onCompletion : @escaping (() -> Void));

    func documentsDirectory() -> URL;

    func shelfs(_ onCompletion : @escaping (([FTShelfItemCollection]) -> Void));

    func createShelf(_ title: String,
                     onCompletion : @escaping ((NSError?, FTShelfItemCollection?) -> Void));

    func deleteShelf(_ shelf: FTShelfItemCollection,
                     onCompletion : @escaping ((NSError?, FTShelfItemCollection?) -> Void));

    func renameShelf(_ shelf: FTShelfItemCollection,
                     title: String,
                     onCompletion : @escaping ((NSError?, FTShelfItemCollection?) -> Void));
}

extension FTShelfCollection {
    func collection(withTitle title: String) -> FTShelfItemCollection? {
        assert(false, "collection: is not supported by default")
        return nil;
    }

    func documentsDirectory() -> URL {
        assert(false, "documentsDirectory is not supported by default")
        return NSURL() as URL;
    }

    func refreshShelfCollection(onCompletion : @escaping (() -> Void)) {
        assert(false, "refreshShelfCollection: is not supported by default")
    }

    func createShelf(_ title: String,
                     onCompletion : @escaping ((NSError?, FTShelfItemCollection?) -> Void)) {
        assert(false, "createShelf:onCompletion: is not supported by default")
    }

    func deleteShelf(_ shelf: FTShelfItemCollection,
                     onCompletion : @escaping ((NSError?, FTShelfItemCollection?) -> Void)) {
        assert(false, "deleteShelf:onCompletion: is not supported by default")
    }

    func renameShelf(_ shelf: FTShelfItemCollection,
                     title: String,
                     onCompletion : @escaping ((NSError?, FTShelfItemCollection?) -> Void)) {
        assert(false, "renameShelf:title:onCompletion: is not supported by default")
    }

}
