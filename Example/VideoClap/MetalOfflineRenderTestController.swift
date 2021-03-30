//
//  MetalOfflineRenderTestController.swift
//  VideoClap_Example
//
//  Created by lai001 on 2021/3/13.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import VideoClap
import Metal
import MetalKit
import Photos

class MetalOfflineRenderTestController: UIViewController {
    
    lazy var offlineRenderer: MetalOfflineRenderer = {
        let renderer = MetalOfflineRenderer(viewportSize: CGSize(width: self.view.bounds.width, height: self.view.bounds.height))
//        renderer.sampleCount = 4
        return renderer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let commandBuffer = MetalDevice.share.makeCommandBuffer() else { return }
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: offlineRenderer.currentRenderPassDescriptor) else { return }
        
        renderImage(renderEncoder: renderEncoder)
        renderCube(renderEncoder: renderEncoder)
        
        renderEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        showImage()
    }
    
    func renderCube(renderEncoder: MTLRenderCommandEncoder) {
        let A = Vertex(position: simd_float3(-1, 1, -1), color: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1).float4)
        let B = Vertex(position: simd_float3(-1, -1, -1), color: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1).float4)
        let C = Vertex(position: simd_float3(1, -1, -1), color: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1).float4)
        let D = Vertex(position: simd_float3(1, 1, -1), color: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1).float4)
        
        let Q = Vertex(position: simd_float3(-1, 1, 1), color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1).float4)
        let R = Vertex(position: simd_float3(1, 1, 1), color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1).float4)
        let S = Vertex(position: simd_float3(-1, -1, 1), color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1).float4)
        let T = Vertex(position: simd_float3(1, -1, 1), color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1).float4)
        
        var verticesArray: [Vertex] = []
        verticesArray.append(contentsOf: [R,T,S ,Q,R,S])
        verticesArray.append(contentsOf: [A,B,C ,A,C,D])
        verticesArray.append(contentsOf: [Q,S,B ,Q,B,A])
        verticesArray.append(contentsOf: [D,C,T ,D,T,R])
        verticesArray.append(contentsOf: [Q,A,D ,Q,D,R])
        verticesArray.append(contentsOf: [B,S,T ,B,T,C])
        
        guard let vertexBuffer = MetalDevice.share.makeBuffer(bytes: verticesArray, length: verticesArray.count * MemoryLayout<Vertex>.size, options: []) else {
            return
        }
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "Render Pipeline"
        pipelineStateDescriptor.vertexFunction = MetalDevice.share.makeFunction(name: "basicVertex")
        pipelineStateDescriptor.fragmentFunction = MetalDevice.share.makeFunction(name: "basicFragment")
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = offlineRenderer.colorPixelFormat
        pipelineStateDescriptor.sampleCount = offlineRenderer.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = offlineRenderer.depthStencilPixelFormat
        guard let pipelineState = try? MetalDevice.share.makeRenderPipelineState(descriptor: pipelineStateDescriptor) else { return }
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true
        guard let depthStencilState = MetalDevice.share.makeDepthStencilState(descriptor: depthDescriptor) else { return }
        
        let perspectiveMatrix: simd_float4x4 = MLKMatrix4MakePerspective(MLKMathDegreesToRadians(85.0),
                                                                         Float(self.view.bounds.size.width / self.view.bounds.size.height),
                                                                         0.01,
                                                                         600)
        let cameraPosition = simd_float3(0, 0, 1)
        let cameraUp = simd_float3(0, 1, 0)
        let cameraFront = simd_float3(0, 0, 1)
        let lookAtMatrix = MLKMatrix4MakeLookAt(cameraPosition, cameraPosition - cameraFront, cameraUp)
        var modelMatrix: simd_float4x4 = matrix_identity_float4x4
        modelMatrix = MLKMatrix4RotateWithVector3(modelMatrix, MLKMathDegreesToRadians(20), simd_float3(1, 0, 0))
        modelMatrix = MLKMatrix4RotateWithVector3(modelMatrix, MLKMathDegreesToRadians(20), simd_float3(0, 1, 0))
        modelMatrix = MLKMatrix4RotateWithVector3(modelMatrix, MLKMathDegreesToRadians(20), simd_float3(0, 0, 1))
        modelMatrix = MLKMatrix4ScaleWithVector3(modelMatrix, simd_float3(2.0, 2.0, 2.0))
        modelMatrix = MLKMatrix4TranslateWithVector3(modelMatrix, simd_float3(-1.2, -1.2, 10))
//        lookAtMatrix = MLKMatrix4MakeLookAt(cameraPosition, cameraPosition - cameraFront, cameraUp)
        var mvpMatrix: simd_float4x4 = perspectiveMatrix * lookAtMatrix * modelMatrix
        guard let uniformsBuffer = MetalDevice.share.makeBuffer(bytes: &mvpMatrix, length: MemoryLayout<simd_float4x4>.size) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                     vertexCount: verticesArray.count,
                                     instanceCount: verticesArray.count / 3)
    }
    
    func renderImage(renderEncoder: MTLRenderCommandEncoder) {
        guard let url = resourceURL(filename: "test1.jpg") else { return }
        guard let testImage = MetalDevice.share.loadTexture(from: url) else { return }
        
        var imageVertexs: [ImageVertex] = []
        imageVertexs.append(ImageVertex(position: simd_float2(1.0, 1.0), textureCoordinate: simd_float2(1.0, 0.0)))
        imageVertexs.append(ImageVertex(position: simd_float2(-1.0, 1.0), textureCoordinate: simd_float2(0.0, 0.0)))
        imageVertexs.append(ImageVertex(position: simd_float2(-1.0, -1.0), textureCoordinate: simd_float2(0.0, 1.0)))
        imageVertexs.append(ImageVertex(position: simd_float2(1.0, 1.0), textureCoordinate: simd_float2(1.0, 0.0)))
        imageVertexs.append(ImageVertex(position: simd_float2(-1.0, -1.0), textureCoordinate: simd_float2(0.0, 1.0)))
        imageVertexs.append(ImageVertex(position: simd_float2(1.0, -1.0), textureCoordinate: simd_float2(1.0, 1.0)))
        guard let vertexBuffer = MetalDevice.share.makeBuffer(bytes: imageVertexs,
                                                              length: imageVertexs.count * MemoryLayout<ImageVertex>.size,
                                                              options: []) else {
            return
        }
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "Image Render Pipeline"
        pipelineStateDescriptor.sampleCount = offlineRenderer.sampleCount
        pipelineStateDescriptor.vertexFunction = MetalDevice.share.makeFunction(name: "imageVertexShader")
        pipelineStateDescriptor.fragmentFunction = MetalDevice.share.makeFunction(name: "imageFragmentShader")
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = offlineRenderer.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = offlineRenderer.depthStencilPixelFormat
        guard let pipelineState = try? MetalDevice.share.makeRenderPipelineState(descriptor: pipelineStateDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(testImage, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                     vertexCount: imageVertexs.count,
                                     instanceCount: imageVertexs.count / 3)
    }
    
    @objc func showImage() {
        let image = offlineRenderer.renderToCIImage()
        let imageView = UIImageView(image: UIImage(ciImage: image.unsafelyUnwrapped))
        self.view.addSubview(imageView)
        imageView.frame = self.view.bounds
        imageView.contentMode = .scaleAspectFit
    }
    
}
