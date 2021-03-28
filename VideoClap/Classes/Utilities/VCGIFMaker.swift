//
//  VCGIFMaker.swift
//  VideoClap
//
//  Created by lai001 on 2021/3/26.
//

import Foundation
import MobileCoreServices

public struct VCGIFFeedInfo {
    let cgImage: CGImage?
    let imageProperties: [CFString : Any]?
    let isCancel: Bool
}

public class VCGIFMaker: NSObject {
    
    public var url: URL?
    public var autoRemove: Bool = false
    public var fileProperties: [CFString : Any]? = nil
    public var count: Int = 0
    
    public func start(feedClosure: (Int) -> VCGIFFeedInfo,
                      closure: @escaping (_ error: Error?) -> Void) {
        guard let url = self.url else { return }
        if autoRemove, FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error {
                closure(error)
                return
            }
        }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, count, nil) else {
            closure(NSError(domain: "VCGIFMaker", code: 1, userInfo: [NSLocalizedFailureReasonErrorKey:"Image destination is nil"]))
            return
        }
        var dic: CFDictionary?
        if fileProperties != nil {
            dic = [kCGImagePropertyGIFDictionary: fileProperties] as CFDictionary
        }
        CGImageDestinationSetProperties(destination, dic)
        for index in 0..<count {
            let info = feedClosure(index)
            if info.isCancel {
                CGImageDestinationFinalize(destination)
                closure(NSError(domain: "VCGIFMaker", code: 2, userInfo: [NSLocalizedFailureReasonErrorKey:"Cancel"]))
                return
            }
            
            var dic: CFDictionary?
            if info.imageProperties != nil {
                dic = [kCGImagePropertyGIFDictionary: info.imageProperties] as CFDictionary
            }
            if let cgImage = info.cgImage {
                CGImageDestinationAddImage(destination, cgImage, dic)
            }
        }
        CGImageDestinationFinalize(destination)
        closure(nil)
    }
    
}
