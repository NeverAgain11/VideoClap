//
//  MetalDevice.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/22.
//

import Foundation
import Metal
import MetalKit
import MobileCoreServices

public enum ImageFormat {
    case png
    case jpeg
}

public class MetalDevice: NSObject {
    
    public static let share = MetalDevice()
    
    public let device: MTLDevice?
    
    init(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        self.device = device
        super.init()
    }
    
    public internal(set) lazy var commandQueue: MTLCommandQueue? = {
        return device?.makeCommandQueue()
    }()
    
    public internal(set) lazy var defaultLibrary: MTLLibrary? = {
        if let url = VCHelper.defaultMetalLibURL() {
            do {
                let lib = try device?.makeLibrary(filepath: url.path)
                return lib
            } catch let error {
                log.error(error)
            }
        }
        return nil
    }()
    
    public func makeFunction(name: String) -> MTLFunction? {
        return defaultLibrary?.makeFunction(name: name)
    }
    
    public func makeRenderPipelineState(descriptor: MTLRenderPipelineDescriptor) throws -> MTLRenderPipelineState? {
        return try device?.makeRenderPipelineState(descriptor: descriptor)
    }
    
    public func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MTLResourceOptions = []) -> MTLBuffer? {
        return device?.makeBuffer(bytes: bytes, length: length, options: options)
    }
    
    public func makeCommandBuffer() -> MTLCommandBuffer? {
        return commandQueue?.makeCommandBuffer()
    }
    
    public func makeRenderPassDescriptor(renderPassColorAttachmentDescriptor: MTLRenderPassColorAttachmentDescriptor) -> MTLRenderPassDescriptor {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0] = renderPassColorAttachmentDescriptor
        return renderPassDescriptor
    }
    
    public func makeDepthStencilState(descriptor: MTLDepthStencilDescriptor) -> MTLDepthStencilState? {
        return device?.makeDepthStencilState(descriptor: descriptor)
    }
    
    public func makeTexture(width: Int, height: Int, pixelFormat: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {
        let texture2DDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                                           width: width,
                                                                           height: height,
                                                                           mipmapped: false)
        texture2DDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        return device?.makeTexture(descriptor: texture2DDescriptor)
    }
    
    public func makeDepthTexture(width: Int, height: Int, sampleCount: Int = 1) -> MTLTexture? {
        let texture2DDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
                                                                           width: width,
                                                                           height: height,
                                                                           mipmapped: false)
        texture2DDescriptor.usage = [.renderTarget]
        texture2DDescriptor.storageMode = .private
        if sampleCount > 1 {
            texture2DDescriptor.sampleCount = sampleCount
            texture2DDescriptor.textureType = .type2DMultisample
        }
        let texture = device?.makeTexture(descriptor: texture2DDescriptor)
        return texture
    }
    
    public func makeMultisampleTexture(width: Int, height: Int, pixelFormat: MTLPixelFormat = .bgra8Unorm, sampleCount: Int = 4) -> MTLTexture? {
        let texture2DDescriptor = MTLTextureDescriptor()
        texture2DDescriptor.width = width
        texture2DDescriptor.height = height
        texture2DDescriptor.pixelFormat = pixelFormat
        texture2DDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        texture2DDescriptor.textureType = .type2DMultisample
        texture2DDescriptor.sampleCount = sampleCount
        return device?.makeTexture(descriptor: texture2DDescriptor)
    }
    
    public func loadTexture(from url: URL, options: [MTKTextureLoader.Option : Any]? = nil) -> MTLTexture? {
        guard let device = self.device else { return nil }
        let textureLoader = MTKTextureLoader(device: device)
        let texture = try? textureLoader.newTexture(URL: url, options: options)
        return texture
    }
    
    public func loadTexture(cgImage: CGImage, options: [MTKTextureLoader.Option : Any]? = nil) -> MTLTexture? {
        guard let device = self.device else { return nil }
        let textureLoader = MTKTextureLoader(device: device)
        let texture = try? textureLoader.newTexture(cgImage: cgImage, options: options)
        return texture
    }
    
    public func loadTexture(cgImage: CGImage, options: [MTKTextureLoader.Option : Any]? = nil, completionHandler: @escaping MTKTextureLoader.Callback) {
        guard let device = self.device else {
            completionHandler(nil, NSError(domain: "MetalDevice", code: 1, userInfo: [NSLocalizedFailureReasonErrorKey : "device nil"]))
            return
        }
        let textureLoader = MTKTextureLoader(device: device)
        textureLoader.newTexture(cgImage: cgImage, options: options, completionHandler: completionHandler)
    }
    
    public func saveTexture(_ texture: MTLTexture, format: ImageFormat, compressionQuality: CGFloat = 1.0, url: URL) -> Bool {
        if MetalDevice.share.device == nil {
            return false
        }
        
        if var ciImage = CIImage(mtlTexture: texture, options: [CIImageOption.colorSpace : CGColorSpaceCreateDeviceRGB()]) {
            ciImage = ciImage.transformed(by: .init(scaleX: 1, y: -1))
            let context = CIContext(mtlDevice: MetalDevice.share.device.unsafelyUnwrapped)
            var pixelFormat = CIFormat.BGRA8
            if texture.pixelFormat == .rgba8Unorm {
                pixelFormat = CIFormat.RGBA8
            }
            switch format {
            case .jpeg:
                do {
                    if #available(iOS 10.0, *) {
                        try context.writeJPEGRepresentation(of: ciImage, to: url, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
                        return true
                    } else {
                        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent, format: pixelFormat, colorSpace: CGColorSpaceCreateDeviceRGB()),
                           let data = UIImage(cgImage: cgImage).jpegData(compressionQuality: compressionQuality)
                        {
                            try data.write(to: url)
                            return true
                        }
                    }
                } catch let error {
                    
                }
                
            case .png:
                do {
                    if #available(iOS 11.0, *) {
                        try context.writePNGRepresentation(of: ciImage, to: url, format: pixelFormat, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
                        return true
                    } else {
                        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent, format: pixelFormat, colorSpace: CGColorSpaceCreateDeviceRGB()),
                           let data = UIImage(cgImage: cgImage).pngData()
                        {
                            try data.write(to: url)
                            return true
                        }
                    }
                } catch let error {
                    
                }
            }
        }
        return false
    }
    
    fileprivate var releaseDataCallback: CGDataProviderReleaseDataCallback = { (directInfo: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) in
        data.deallocate()
    }
    
    func pixelBufferToMTLTexture(pixelBuffer: CVPixelBuffer, texturePixelFormat: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {
        guard let device = self.device else { return nil }
        var texture: MTLTexture?
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var textureCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache) != kCVReturnSuccess {
            return nil
        }
        var textureOut: CVMetalTexture?
        if CVMetalTextureCacheCreateTextureFromImage(nil,
                                                     textureCache.unsafelyUnwrapped,
                                                     pixelBuffer,
                                                     nil,
                                                     texturePixelFormat,
                                                     width,
                                                     height,
                                                     0,
                                                     &textureOut) == kCVReturnSuccess {
            texture = CVMetalTextureGetTexture(textureOut.unsafelyUnwrapped)
            return texture
        } else {
            return nil
        }
    }
    
}
