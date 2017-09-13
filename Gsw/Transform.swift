//
//  Transform.swift
//  Gsw
//
//  Created by Deron Johnson on 6/26/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

class Transform
{
    public var modelMatrix = matrix_identity_float4x4

    // The index in the transform store
    public let index: Int
    
    private let _perObjectTransforms: PerObjectTransforms
    
    // The offset of this transform's matrix in the PerObjectTransforms buffer
    public var bufferOffset : Int {
        get { return index * PerObjectTransforms.MATRICES_STRIDE }
    }
    
    public init (_ theMatrix: matrix_float4x4, perObjectTransforms: PerObjectTransforms)
    {
        modelMatrix = theMatrix
        _perObjectTransforms = perObjectTransforms

        do {
            index = try _perObjectTransforms.allocateIndex()
        } catch {
            fatalError("No more space in transform store")
        }
    }
    
    // Inits transform to identity
    public convenience init(perObjectTransforms: PerObjectTransforms)
    {
        self.init(matrix_identity_float4x4, perObjectTransforms:perObjectTransforms)
    }
    
    deinit
    {
        _perObjectTransforms.deallocateIndex(index)
    }
}
