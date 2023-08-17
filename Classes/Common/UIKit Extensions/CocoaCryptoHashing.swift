//
//  CocoaCryptoHashing.swift
//  Noteshelf
//
//  Created by Sameer on 12/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import CommonCrypto

extension NSData {
    @objc func md5HexHash() -> NSString? {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(self.bytes, CC_LONG(self.count), &digest)
        var digestHex = ""
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        if let string = String(cString:digestHex, encoding: .utf8) {
            return string as NSString
        }
        return nil
    }

    @objc func md5Hash() -> NSData {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(self.bytes, CC_LONG(self.count), &digest)
        return NSData(bytes: &digest, length: Int(CC_MD5_DIGEST_LENGTH))
    }
}
