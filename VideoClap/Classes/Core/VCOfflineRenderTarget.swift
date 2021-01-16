//
//  VCOfflineRenderTarget.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/16.
//

import Foundation

public class VCOfflineRenderTarget: NSObject, VCRenderTarget {
    
    public func contextChanged() {
        
    }
    
    public func draw(images: [String : CIImage], blackImage: CIImage) -> CIImage? {
        var finalFrame: CIImage?
        
        finalFrame = images.sorted { (lhs, rhs) -> Bool in
            return lhs.value.indexPath > rhs.value.indexPath
        }.reduce(finalFrame) { (result, args: (key: String, value: CIImage)) -> CIImage? in
            return result?.composited(over: args.value) ?? args.value
        }
        finalFrame = finalFrame?.composited(over: blackImage) ?? blackImage // 让背景变为黑色，防止出现图像重叠
        
        return finalFrame
    }
    
}
