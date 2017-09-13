//
//  MatrixUtils.swift
//  Gsw
//
//  Created by Deron Johnson on 5/24/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//
// TODO: Apple Copyright

import simd

func matrix_from_perspective_fov_aspectLH(_ fovY: Float, _ aspect: Float, _ nearZ: Float, _ farZ: Float) -> matrix_float4x4
{
    let yscale: Float = 1.0 / tan(fovY * 0.5) // 1 / tan == cot
    let xscale: Float = yscale / aspect
    let q = farZ / (farZ - nearZ)
    
    var m: matrix_float4x4 = matrix_identity_float4x4
    m.columns.0 = vector_float4(xscale, 0.0, 0.0, 0.0)
    m.columns.1 = vector_float4(0.0, yscale, 0.0, 0.0)
    m.columns.2 = vector_float4(0.0, 0.0, q, 1.0)
    m.columns.3 = vector_float4(0.0, 0.0, q * -nearZ, 0.0)
    
    return m
}

// Computes extracts a 3x3 matrix from the upper left of a 4x4 matrix
func matrix_from_upper_left(_ inMat: matrix_float4x4) -> matrix_float3x3
{
    let c0 = inMat.columns.0
    let c1 = inMat.columns.1
    let c2 = inMat.columns.2
    
    let outMat = matrix_float3x3(columns: (
        vector_float3(c0.x, c0.y, c0.z),
        vector_float3(c1.x, c1.y, c1.z),
        vector_float3(c2.x, c2.y, c2.z)
    ))

    return outMat;
}

func matrix_from_translation(_ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4
{
    var m = matrix_identity_float4x4
    m.columns.3 = vector_float4(x, y, z, 1.0)
    return m;
}

func matrix_from_rotation(_ radians: Float, _ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4
{
    let v = vector_normalize(vector_float3(x, y, z))
    let cosval = cos(radians)
    let cosp = 1.0 - cosval
    let sinval = sin(radians)
    
    var m : matrix_float4x4 = matrix_identity_float4x4
    m.columns.0 = vector_float4(
            cosval + cosp * v.x * v.x,
            cosp * v.x * v.y + v.z * sinval,
            cosp * v.x * v.z - v.y * sinval,
            0.0)
    m.columns.1 = vector_float4(
            cosp * v.x * v.y - v.z * sinval,
            cosval + cosp * v.y * v.y,
            cosp * v.y * v.z + v.x * sinval,
            0.0)
    m.columns.2 = vector_float4(
            cosp * v.x * v.z + v.y * sinval,
            cosp * v.y * v.z - v.x * sinval,
            cosval + cosp * v.z * v.z,
            0.0)
    m.columns.3 = vector_float4(0.0, 0.0, 0.0, 1.0)

    return m;
}

func matrix_from_scale(_ sx: Float, _ sy: Float, _ sz: Float) -> matrix_float4x4
{
    var m : matrix_float4x4 = matrix_identity_float4x4
    m.columns.0 = vector_float4(sx, 0.0, 0.0, 0.0)
    m.columns.1 = vector_float4(0.0, sy, 0.0, 0.0)
    m.columns.2 = vector_float4(0.0, 0.0, sz, 0.0)
    m.columns.3 = vector_float4(0.0, 0.0, 0.0, 1.0)

    return m
}

func matrix3x3_rotation(_ radians: Float, _ axis: vector_float3) -> matrix_float3x3
{
    let axis = vector_normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = axis.x, y = axis.y, z = axis.z
    
    var m : matrix_float3x3 = matrix_identity_float3x3
    m.columns.0 = vector_float3(ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st)
    m.columns.1 = vector_float3(x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st)
    m.columns.2 = vector_float3(x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci)
    
    return m
}

func lookAtMatrix(eye eyeVec: vector_float3, center centerVec: vector_float3, up upVec: vector_float3) -> matrix_float4x4
{
    let z = vector_normalize(eyeVec - centerVec);
    let x = vector_normalize(vector_cross(upVec, z));
    let y = vector_cross(z, x);
    let t = vector_float3(-vector_dot(x, eyeVec), -vector_dot(y, eyeVec), -vector_dot(z, eyeVec))
    
    var m : matrix_float4x4 = matrix_identity_float4x4
    m.columns.0 = vector_float4(x.x, y.x, z.x, 0)
    m.columns.1 = vector_float4(x.y, y.y, z.y, 0)
    m.columns.2 = vector_float4(x.z, y.z, z.z, 0)
    m.columns.3 = vector_float4(t.x, t.y, t.z, 1)
    
    return m
}

extension float3
{
    static func == (left: float3, right: float3) -> Bool
    {
        return left.x == right.x && left.y == right.y && left.z == right.z
    }
    
    static func != (left: float3, right: float3) -> Bool
    {
        return left.x != right.x || left.y != right.y || left.z != right.z
    }
}

