//
//  MetalViewController.swift
//  VideoClap_Example
//
//  Created by lai001 on 2021/2/23.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Metal
import UIKit
import SnapKit
import MetalKit
import GLKit
import VideoClap
import Photos

extension UIColor {
    
    var float4: simd_float4 {
        if let components = cgColor.components, components.count == 4 {
            return simd_float4(Float(components[0]), Float(components[1]), Float(components[2]), Float(components[3]))
        }
        return simd_float4(repeating: 0)
    }
    
    var mtlClearColor: MTLClearColor {
        if let components = cgColor.components, components.count == 4 {
            return MTLClearColor(red: Double(components[0]), green: Double(components[1]), blue: Double(components[2]), alpha: Double(components[3]))
        }
        return MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
}

class MetalViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    lazy var slider: UISlider = {
        let sliedr = UISlider()
        sliedr.minimumValue = 0
        sliedr.maximumValue = 360
        sliedr.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
        return sliedr
    }()
    
    lazy var slider1: UISlider = {
        let sliedr = UISlider()
        sliedr.minimumValue = 0
        sliedr.maximumValue = 360
        sliedr.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
        return sliedr
    }()
    
    lazy var slider2: UISlider = {
        let sliedr = UISlider()
        sliedr.minimumValue = 0
        sliedr.maximumValue = 360
        sliedr.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
        return sliedr
    }()
    
    lazy var saveItem: UIBarButtonItem = {
        return UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveButtonDidTap(_:)))
    }()
    
    lazy var renderView: MTKView = {
        let renderView = MTKView(frame: .zero, device: MetalDevice.share.device)
//        renderView.delegate = self
        renderView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        renderView.depthStencilPixelFormat = .depth32Float
        renderView.clearDepth = 1.0
        renderView.framebufferOnly = false
        return renderView
    }()
    
    let A = Vertex(position: simd_float3(-1, 1, -1), color: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1).float4)
    let B = Vertex(position: simd_float3(-1, -1, -1), color: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1).float4)
    let C = Vertex(position: simd_float3(1, -1, -1), color: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1).float4)
    let D = Vertex(position: simd_float3(1, 1, -1), color: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1).float4)
    
    let Q = Vertex(position: simd_float3(-1, 1, 1), color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1).float4)
    let R = Vertex(position: simd_float3(1, 1, 1), color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1).float4)
    let S = Vertex(position: simd_float3(-1, -1, 1), color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1).float4)
    let T = Vertex(position: simd_float3(1, -1, 1), color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1).float4)
    
    lazy var verticesArray: [Vertex] = {
        var verticesArray: [Vertex] = []
        verticesArray.append(contentsOf: [R,T,S ,Q,R,S])
        verticesArray.append(contentsOf: [A,B,C ,A,C,D])
        
        verticesArray.append(contentsOf: [Q,S,B ,Q,B,A])
        verticesArray.append(contentsOf: [D,C,T ,D,T,R])
        
        verticesArray.append(contentsOf: [Q,A,D ,Q,D,R])
        verticesArray.append(contentsOf: [B,S,T ,B,T,C])
        return verticesArray
    }()
    
    var vertexBuffer: MTLBuffer?
    
    var pipelineState: MTLRenderPipelineState?
    
    var depthStencilState: MTLDepthStencilState?
    
    var mvpMatrix: simd_float4x4 = .init()
    
    lazy var perspectiveMatrix: simd_float4x4 = MLKMatrix4MakePerspective(MLKMathDegreesToRadians(85.0),
                                                                          Float(self.view.bounds.size.width / self.view.bounds.size.height),
                                                                          0.01,
                                                                          600)
    var cameraPosition = simd_float3(0, 0, 1)
    let cameraUp = simd_float3(0, 1, 0)
    var cameraFront = simd_float3(0, 0, 1)
    
    lazy var lookAtMatrix = MLKMatrix4MakeLookAt(cameraPosition, cameraPosition - cameraFront, cameraUp)
    
    var rotation: Float = 0.0
    
    var fps = 1.0 / 120.0
    
    var time = Date().timeIntervalSince1970
    
    lazy var texture: MTLTexture? = {
        var texture = MetalDevice.share.loadTexture(from: resourceURL(filename: "test1.jpg").unsafelyUnwrapped)
        return texture
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            if #available(iOS 10.0, *) {
                try FileManager.default.removeItem(at: FileManager.default.temporaryDirectory)
                try FileManager.default.createDirectory(at: FileManager.default.temporaryDirectory, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            
        }
        
        navigationItem.rightBarButtonItem = saveItem
        
        setupUI()
        vertexBuffer = MetalDevice.share.makeBuffer(bytes: verticesArray, length: verticesArray.count * MemoryLayout<Vertex>.size, options: [])
        lookAtMatrix = MLKMatrix4RotateWithVector3(lookAtMatrix, MLKMathDegreesToRadians(90.0), simd_float3(0, 1, 0))
        
        do {
            let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
            pipelineStateDescriptor.label = "Render Pipeline"
            pipelineStateDescriptor.sampleCount = renderView.sampleCount;
            pipelineStateDescriptor.vertexFunction = MetalDevice.share.makeFunction(name: "basicVertex")
            pipelineStateDescriptor.fragmentFunction = MetalDevice.share.makeFunction(name: "basicFragment")
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = renderView.colorPixelFormat;
            pipelineStateDescriptor.depthAttachmentPixelFormat = renderView.depthStencilPixelFormat;
            if #available(iOS 11.0, *) {
                pipelineStateDescriptor.vertexBuffers[0].mutability = .immutable
            } else {
                // Fallback on earlier versions
            }
            pipelineState = try? MetalDevice.share.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
        
        do {
            let depthDescriptor = MTLDepthStencilDescriptor()
            depthDescriptor.depthCompareFunction = .lessEqual
            depthDescriptor.isDepthWriteEnabled = true
            depthStencilState = MetalDevice.share.makeDepthStencilState(descriptor: depthDescriptor)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.draw(in: renderView)
    }
    
    func setupUI() {
        view.addSubview(renderView)
        view.addSubview(slider)
        view.addSubview(slider1)
        view.addSubview(slider2)
        
        renderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        slider.snp.makeConstraints { (make) in
            make.bottom.equalTo(slider1.snp.top).offset(-10)
            make.left.right.equalTo(slider2)
            make.height.equalTo(slider2)
        }
        
        slider1.snp.makeConstraints { (make) in
            make.bottom.equalTo(slider2.snp.top).offset(-10)
            make.left.right.equalTo(slider2)
            make.height.equalTo(slider2)
        }
        
        slider2.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(50)
            make.height.equalTo(50)
        }
    }
    
    @objc func saveButtonDidTap(_ sender: UIBarButtonItem) {
        if let texture = renderView.currentDrawable?.texture {
            let closure = VCHelper.measure()
            var url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(Date().description(with: Locale.current)).png")
            MetalDevice.share.saveTexture(texture, format: .png, url: url)
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            } completionHandler: { (_, _) in
                
            }
            url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(Date().description(with: Locale.current)).jpeg")
            MetalDevice.share.saveTexture(texture, format: .jpeg, url: url)
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            } completionHandler: { (_, _) in
                
            }
            log.debug(closure())
        }
    }
    
    @objc func valueChanged(_ sender: UISlider) {
        if (Date().timeIntervalSince1970 - time) > fps {
            let closure = VCHelper.measure()
            self.draw(in: renderView)
            log.debug(closure())
        }
        time = Date().timeIntervalSince1970
    }
    
}

extension MetalViewController: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else { return }
        guard let commandBuffer = MetalDevice.share.makeCommandBuffer() else { return }
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).mtlClearColor
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        guard let pipelineState = pipelineState else { return }
        
        defer {
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
        do {
            // ---
            rotation += 1
            var modelMatrix: simd_float4x4 = matrix_identity_float4x4
            modelMatrix = MLKMatrix4RotateWithVector3(modelMatrix, MLKMathDegreesToRadians(slider.value), simd_float3(1, 0, 0))
            modelMatrix = MLKMatrix4RotateWithVector3(modelMatrix, MLKMathDegreesToRadians(slider1.value), simd_float3(0, 1, 0))
            modelMatrix = MLKMatrix4RotateWithVector3(modelMatrix, MLKMathDegreesToRadians(slider2.value), simd_float3(0, 0, 1))
            modelMatrix = MLKMatrix4TranslateWithVector3(modelMatrix, simd_float3(-1.2, -1.2, 10))
            lookAtMatrix = MLKMatrix4MakeLookAt(cameraPosition, cameraPosition - cameraFront, cameraUp)
            mvpMatrix = perspectiveMatrix * lookAtMatrix * modelMatrix
            
            let uniformsBuffer: MTLBuffer? = MetalDevice.share.makeBuffer(bytes: &mvpMatrix, length: MemoryLayout<simd_float4x4>.size)
            // ---
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setDepthStencilState(depthStencilState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
            renderEncoder.setVertexTexture(texture, index: 2)
            renderEncoder.setFragmentTexture(texture, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                         vertexCount: verticesArray.count,
                                         instanceCount: verticesArray.count / 3)
        }
        
        do {
            var modelMatrix: simd_float4x4 = matrix_identity_float4x4
            modelMatrix = MLKMatrix4RotateWithVector3(modelMatrix, MLKMathDegreesToRadians(slider.value), simd_float3(1, 0, 0))
            modelMatrix = MLKMatrix4RotateWithVector3(modelMatrix, MLKMathDegreesToRadians(slider1.value), simd_float3(0, 1, 0))
            modelMatrix = MLKMatrix4RotateWithVector3(modelMatrix, MLKMathDegreesToRadians(slider2.value), simd_float3(0, 0, 1))
            modelMatrix = MLKMatrix4TranslateWithVector3(modelMatrix, simd_float3(1.2, 1.2, 20))
            mvpMatrix = perspectiveMatrix * lookAtMatrix * modelMatrix
            let uniformsBuffer: MTLBuffer? = MetalDevice.share.makeBuffer(bytes: &mvpMatrix, length: MemoryLayout<simd_float4x4>.size)
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                         vertexCount: verticesArray.count,
                                         instanceCount: verticesArray.count / 3)
        }
    }
    
}
