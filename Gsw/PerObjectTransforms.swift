//
//  PerObjectTransforms.swift
//  Gsw
//
//  Created by Deron Johnson on 6/19/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

enum PerObjectTransformsError: Error
{
    case noMoreIndices
}

// A singleton which stores the per-object transform matrices in a Metal buffer.
// In order for a matrix to be uploaded into this buffer an index must be allocated for it.
// Note: index 0 is reserved for static objects (which always have model matrix = identity).
// Note: this Metal buffer is called perObjectMatrices in shaders.
//
class PerObjectTransforms
{
    let _numObjects: Int
    let _numTransforms: Int
    
    // Static objects (that is, those without a transform) should bind to this index.
    // The model matrix for this is identity and this is combined with the global transforms.
    public static let STATIC_OBJECT_INDEX: Int = 0
    
    public static let MATRICES_STRIDE = MemoryLayout<PerObjectMatrices>.stride
    
    // This objects's metal buffer set. Bind a buffer in the set to an encoder.
    public let bufferSet: BufferSet

    private var _inUseFlags: Array<Bool>
    
    // Binds to the given encoder the vertex buffer offset for this transform
    public static func setVertexBufferOffset(_ encoder: MTLRenderCommandEncoder, _ transform: Transform?)
    {
        var idx = PerObjectTransforms.STATIC_OBJECT_INDEX
        if let xform = transform
        {
            idx = xform.index
        }
        encoder.setVertexBufferOffset(idx * MATRICES_STRIDE, at:Int(PerObjectMatricesBufferBindIndex.rawValue))
    }

    public init(device: MTLDevice, numTransformableObjects: Int, resourceOptions: MTLResourceOptions = .storageModeShared)
    {
        _numObjects = numTransformableObjects
        // Reserve a slot for the identity (static) transform
        _numTransforms = numTransformableObjects + 1;
        
        bufferSet = BufferSet(device:device, length:PerObjectTransforms.MATRICES_STRIDE * _numTransforms, options:resourceOptions)
        _inUseFlags = Array<Bool>(repeating:false, count:_numTransforms)
        
        // Preallocate the static object index, and load them with identity matrices.
        // (These matrices remain constant throughout the rendering).
        _ = try! allocateIndex()
    }
    
    // Allocate an index within the store to hold a transform. Throws if there are no more indices.
    public func allocateIndex() throws -> Int
    {
        // TODO: For now, simple linear search
        for idx in 0..<_numTransforms
        {
            if !_inUseFlags[idx]
            {
                _inUseFlags[idx] = true
                return idx
            }
        }
        
        throw PerObjectTransformsError.noMoreIndices
    }

    // Return an index to the store
    public func deallocateIndex(_ index: Int)
    {
        guard index != PerObjectTransforms.STATIC_OBJECT_INDEX else { fatalError("Cannot deallocate the static object index") }
        guard _inUseFlags[index] else { fatalError("Returning an index to transform store that wasn't allocated") }
        _inUseFlags[index] = false
    }
    
    public func getBuffer(_ constantBufferIndex: Int) -> MTLBuffer
    {
        return bufferSet[constantBufferIndex]
    }
    
    // Update the static transform with the global transforms
    public func updateStaticTransform(globalTransforms: GlobalTransforms, constantBufferIndex: Int)
    {
        _combineAndUpload(modelMatrix: matrix_identity_float4x4, objectIndex:PerObjectTransforms.STATIC_OBJECT_INDEX, globalTransforms:globalTransforms, constantBufferIndex:constantBufferIndex)
    }

    public func combineAndUpload(modelTransform: Transform, globalTransforms: GlobalTransforms, constantBufferIndex: Int)
    {
        _combineAndUpload(modelMatrix:modelTransform.modelMatrix, objectIndex:modelTransform.index, globalTransforms:globalTransforms, constantBufferIndex:constantBufferIndex)
    }

    private func _combineAndUpload(modelMatrix: matrix_float4x4, objectIndex: Int, globalTransforms: GlobalTransforms, constantBufferIndex: Int)
    {
        var matrices = PerObjectMatrices()
    
        // Normal matrix can be 3x3 because we only use translations, rotations and uniform scales.
        matrices.normalMatrix = matrix_transpose(matrix_invert(matrix_from_upper_left(modelMatrix)))

        // TODO: for some reason, I need to flip the direction of the normals
        //let negateMatrix = matrix_from_diagonal(float3(-1.0))
        //matrices.normalMatrix = matrix_multiply(matrices.normalMatrix, negateMatrix)

        matrices.viewModelMatrix = matrix_multiply(globalTransforms.viewMatrix, modelMatrix)
        matrices.projectionViewModelMatrix =  matrix_multiply(globalTransforms.projectionViewMatrix, modelMatrix)

        // TODO: do these need initialization? viewMatrix, projectionMatrix

         bufferSet[constantBufferIndex].contents().storeBytes(of:matrices, toByteOffset:PerObjectTransforms.MATRICES_STRIDE * objectIndex, as:PerObjectMatrices.self)
    }
}
