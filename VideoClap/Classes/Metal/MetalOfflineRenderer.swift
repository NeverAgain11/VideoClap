//
//  MetalOfflineRenderer.swift
//  VideoClap
//
//  Created by lai001 on 2021/3/13.
//

import Foundation

open class MetalOfflineRenderer: NSObject {
    
    open lazy var texture: MTLTexture? = {
        var texture = MetalDevice.share.makeTexture(width: Int(viewportSize.width), height: Int(viewportSize.height), pixelFormat: colorPixelFormat)
        return texture
    }()
    
    open lazy var depthStencilTexture: MTLTexture? = {
        var texture = MetalDevice.share.makeDepthTexture(width: Int(viewportSize.width), height: Int(viewportSize.height), sampleCount: sampleCount)
        return texture
    }()
    
    open var resolveTexture: MTLTexture?
    
    open lazy var currentRenderPassDescriptor: MTLRenderPassDescriptor = {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTexture
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        renderPassDescriptor.depthAttachment.texture = depthStencilTexture
        return renderPassDescriptor
    }()
    
    public let viewportSize: CGSize
    
    open var sampleCount: Int = 1 {
        didSet {
            if MetalDevice.share.device?.supportsTextureSampleCount(sampleCount) == false {
                return
            }
            
            if sampleCount > 1 {
                texture = MetalDevice.share.makeMultisampleTexture(width: Int(viewportSize.width), height: Int(viewportSize.height), pixelFormat: colorPixelFormat, sampleCount: sampleCount)
                resolveTexture = MetalDevice.share.makeTexture(width: Int(viewportSize.width), height: Int(viewportSize.height), pixelFormat: colorPixelFormat)
                currentRenderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
            } else {
                texture = MetalDevice.share.makeTexture(width: Int(viewportSize.width), height: Int(viewportSize.height), pixelFormat: colorPixelFormat)
                resolveTexture = nil
                currentRenderPassDescriptor.colorAttachments[0].storeAction = .store
            }
            depthStencilTexture = MetalDevice.share.makeDepthTexture(width: Int(viewportSize.width), height: Int(viewportSize.height), sampleCount: sampleCount)
            
            currentRenderPassDescriptor.colorAttachments[0].texture = texture
            currentRenderPassDescriptor.colorAttachments[0].resolveTexture = resolveTexture
            currentRenderPassDescriptor.depthAttachment.texture = depthStencilTexture
        }
    }
    
    open var colorPixelFormat: MTLPixelFormat = .rgba8Unorm
    
    open var depthStencilPixelFormat: MTLPixelFormat = .depth32Float
    
    open var clearColor: MTLClearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1) {
        didSet {
            currentRenderPassDescriptor.colorAttachments[0].clearColor = clearColor
        }
    }
    
    public init(viewportSize size: CGSize) {
        viewportSize = size
        super.init()
    }
    
    public func renderToCIImage() -> CIImage? {
        if let texture = resolveTexture ?? texture {
            let imageByteSize = texture.height * texture.width * 4
            let data = UnsafeMutablePointer<UInt8>.allocate(capacity: imageByteSize)
            texture.getBytes(data, bytesPerRow: MemoryLayout<UInt8>.size * texture.width * 4, bytesPerImage: 0, from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0, slice: 0)
            guard let dataProvider = CGDataProvider(dataInfo: nil, data: data, size: imageByteSize, releaseData: releaseDataCallback) else {
                return nil
            }
            guard let bitmapData = dataProvider.data as Data? else { return nil }
            return CIImage(bitmapData: bitmapData,
                           bytesPerRow: 4 * texture.width,
                           size: CGSize(width: texture.width, height: texture.height),
                           format: .RGBA8,
                           colorSpace: CGColorSpaceCreateDeviceRGB())
        } else {
            return nil
        }
    }
    
    public func renderToCGImage() -> CGImage? {
        if let texture = resolveTexture ?? texture {
            let imageByteSize = texture.height * texture.width * 4
            let data = UnsafeMutablePointer<UInt8>.allocate(capacity: imageByteSize)
            texture.getBytes(data, bytesPerRow: MemoryLayout<UInt8>.size * texture.width * 4, bytesPerImage: 0, from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0, slice: 0)
            guard let dataProvider = CGDataProvider(dataInfo: nil, data: data, size: imageByteSize, releaseData: releaseDataCallback) else {
                return nil
            }
            return CGImage(width: texture.width,
                           height: texture.height,
                           bitsPerComponent: 8,
                           bitsPerPixel: 32,
                           bytesPerRow: 4 * texture.width,
                           space: CGColorSpaceCreateDeviceRGB(),
                           bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                           provider: dataProvider,
                           decode: nil,
                           shouldInterpolate: false,
                           intent:.defaultIntent)
        } else {
            return nil
        }
    }
    
    public func renderToUIImage() -> UIImage? {
        if let cgImage = self.renderToCGImage() {
            return UIImage(cgImage: cgImage)
        } else {
            return nil
        }
    }
    
    fileprivate var releaseDataCallback: CGDataProviderReleaseDataCallback = { (directInfo: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) in
        data.deallocate()
    }
    
}
