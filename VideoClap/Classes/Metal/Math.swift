//
//  Math.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/24.
//

import Foundation
import simd
import UIKit
import GLKit

public func MLKMatrix4MakeLookAt(_ eye: simd_float3, _ target: simd_float3, _ up: simd_float3) -> simd_float4x4 {
    let simds = simd_float4x4(GLKMatrix4MakeLookAt(eye.x, eye.y, eye.z, target.x, target.y, target.z, up.x, up.y, up.z))
    return simds
    
    let forward = normalize(eye - target)
    let right = cross(normalize(up), forward)
    let cUp = cross(forward, right)
    var camToWorld = simd_float4x4()
    
    camToWorld[0][0] = right.x
    camToWorld[0][1] = right.y
    camToWorld[0][2] = right.z
    camToWorld[1][0] = cUp.x
    camToWorld[1][1] = cUp.y
    camToWorld[1][2] = cUp.z
    camToWorld[2][0] = forward.x
    camToWorld[2][1] = forward.y
    camToWorld[2][2] = forward.z
    camToWorld[3][0] = eye.x
    camToWorld[3][1] = eye.y
    camToWorld[3][2] = eye.z
    return camToWorld;
}

public func MLKMatrix4MakePerspective(_ fovy: Float, _ aspect: Float, _ near: Float, _ far: Float) -> simd_float4x4 {
    let scaleY = 1.0 / tan(fovy * 0.5)
    let scaleX = scaleY / aspect
    // f(z) = A * z + B
    // z(0.0, 1.0)
    let B = ( near * far ) / ( near - far )
    let A = B / (-near)
    
    // f(z) = A * z + B
    // z(0.0, 720.0)
//    let A = 720 / (far - near)
//    let B = -A * near
    
    let x = simd_make_float4(scaleX, 0, 0, 0)
    let y = simd_make_float4(0, scaleY, 0, 0)
    let z = simd_make_float4(0, 0, A, 1)
    let w = simd_make_float4(0, 0, B , 0)
    return simd_matrix(x, y, z, w)
}

public func MLKMatrix4ScaleWithVector3(_ matrix: simd_float4x4 , _ scaleVector: simd_float3) -> simd_float4x4 {
    return simd_float4x4(GLKMatrix4ScaleWithVector3(GLKMatrix4(matrix), GLKVector3(scaleVector)))
}

public func MLKMatrix4RotateWithVector3(_ matrix: simd_float4x4 , _ radians: Float, _ axisVector: simd_float3) -> simd_float4x4 {
    return matrix * simd_matrix4x4(simd_quaternion(radians, axisVector))
//    return simd_float4x4(GLKMatrix4RotateWithVector3(GLKMatrix4(matrix), radians, GLKVector3(axisVector)))
}

public func MLKMatrix4TranslateWithVector3(_ matrix: simd_float4x4, _ translationVector: simd_float3) -> simd_float4x4 {
    var t: simd_float4x4 = matrix
    t.columns.3.x += translationVector.x
    t.columns.3.y += translationVector.y
    t.columns.3.z += translationVector.z
    return t
}

public func MLKMathDegreesToRadians(_ degrees: Float) -> Float {
    return degrees / 180.0 * Float.pi
}

public func MLKMathDegreesToRadians(_ degrees: CGFloat) -> CGFloat {
    return degrees / 180.0 * CGFloat.pi
}

public func MLKMathDegreesToRadians(_ degrees: Double) -> Double {
    return degrees / 180.0 * Double.pi
}

public func MLKMathRadiansToDegrees(_ radians: Float) -> Float {
    return radians * 180.0 / Float.pi
}

public func MLKMathRadiansToDegrees(_ radians: CGFloat) -> CGFloat {
    return radians * 180.0 / CGFloat.pi
}

public func MLKMathRadiansToDegrees(_ radians: Double) -> Double {
    return radians * 180.0 / Double.pi
}

extension simd_float4x4 {
    init(_ matrix: GLKMatrix4) {
        self.init(columns: (simd_float4(x: matrix.m00, y: matrix.m01, z: matrix.m02, w: matrix.m03),
                            simd_float4(x: matrix.m10, y: matrix.m11, z: matrix.m12, w: matrix.m13),
                            simd_float4(x: matrix.m20, y: matrix.m21, z: matrix.m22, w: matrix.m23),
                            simd_float4(x: matrix.m30, y: matrix.m31, z: matrix.m32, w: matrix.m33)))
    }
}

extension GLKVector3 {
    
    init(_ vector3: simd_float3) {
        self.init(v: (vector3.x, vector3.y, vector3.z))
    }
    
}

extension GLKMatrix4 {
    
    init(_ matrix: simd_float4x4) {
        self.init(m: (matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z, matrix.columns.0.w,
                      matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z, matrix.columns.1.w,
                      matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z, matrix.columns.2.w,
                      matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z, matrix.columns.3.w))
    }
    
}
