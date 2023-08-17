//
//  NSData256+Extension.swift
//  Noteshelf
//
//  Created by Sameer on 12/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import CommonCrypto

extension NSData {
    @objc func AES256EncryptWithKey(_ key:NSString) -> NSData? {
        let keyData = key.data(using: String.Encoding.utf8.rawValue)! as NSData
        let bufferData    = NSMutableData(length: self.count + kCCBlockSizeAES128)
        let bufferPointer = bufferData?.mutableBytes
        let bufferLength  = size_t(bufferData!.length)
        var numBytesEncrypted: Int = 0
        let operation: CCOperation = UInt32(kCCEncrypt)
        let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options:   CCOptions   = UInt32(kCCOptionPKCS7Padding)
        let dataBytes = self.bytes
        let cryptStatus = CCCrypt(operation,
                algoritm,
                options,
                keyData.bytes, size_t(kCCKeySizeAES256),
                nil,
                dataBytes, self.count,
                bufferPointer, bufferLength,
                &numBytesEncrypted)
        if cryptStatus == kCCSuccess, let bufferData = bufferData {
             let dataToReturn = NSData(bytesNoCopy: bufferData.mutableBytes, length: numBytesEncrypted, freeWhenDone: false)
             return dataToReturn
        }
        return nil
    }
    
    @objc func AES256DecryptDataWithKey(_ key: NSString) -> NSData {
        let keyData = key.data(using: String.Encoding.utf8.rawValue)! as NSData
        let keyBytes = keyData.bytes
        let keyLength = size_t(kCCKeySizeAES256)
        let dataLength  = self.count
        let dataBytes = self.bytes
        let bufferData    = NSMutableData(length: Int(dataLength) + kCCBlockSizeAES128)
        let bufferPointer = bufferData?.mutableBytes
        let bufferLength  = size_t(bufferData!.length)
        let operation: CCOperation = UInt32(kCCDecrypt)
        let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options:   CCOptions   = UInt32(kCCOptionPKCS7Padding)
        var numBytesDecrypted: Int = 0
        let cryptStatus = CCCrypt(operation,
            algoritm,
            options,
            keyBytes, keyLength,
            nil,
            dataBytes, dataLength,
            bufferPointer, bufferLength,
            &numBytesDecrypted)
        
        if cryptStatus == kCCSuccess {
            let dataToReturn = NSData(bytesNoCopy: bufferData!.mutableBytes, length: numBytesDecrypted, freeWhenDone: false)
            let stringValue = NSString(data: dataToReturn as Data, encoding: String.Encoding.utf8.rawValue)

            if (stringValue == nil) || (stringValue == "") {
                return AES256DecryptDataWithDefaultKey(key)
            }
            return dataToReturn
        } else {
            return NSData()
        }
    }
    
    @objc func AES256DecryptDataWithDefaultKey(_ key: NSString) -> NSData {
        let keyData = key.data(using: String.Encoding.utf8.rawValue)! as NSData
        let keyBytes = keyData.bytes
        let keyLength = size_t(kCCKeySizeAES256)
        let dataLength  = self.count
        let dataBytes = self.bytes
        let bufferData    = NSMutableData(length: Int(dataLength) + kCCBlockSizeAES128)
        let bufferPointer = bufferData?.mutableBytes
        let bufferLength  = size_t(bufferData!.length)
        let operation: CCOperation = UInt32(kCCDecrypt)
        let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options:   CCOptions   = UInt32(kCCOptionPKCS7Padding)
        var numBytesDecrypted: Int = 0
        let cryptStatus = CCCrypt(operation,
            algoritm,
            options,
            keyBytes, keyLength,
            nil,
            dataBytes, dataLength,
            bufferPointer, bufferLength,
            &numBytesDecrypted)
        if UInt32(cryptStatus) == UInt32(kCCSuccess), let bufferData = bufferData {
            let dataToReturn = NSData(bytesNoCopy: bufferData.mutableBytes, length: numBytesDecrypted, freeWhenDone: false)
            return dataToReturn
        } else {
            print("Error: \(cryptStatus)")
            return NSData()
        }
    }
}
