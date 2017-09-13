//
//  CubeObject.swift
//  Gsw
//
//  Created by Deron Johnson on 6/19/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import MetalKit

class CubeObject: MDLMeshObject
{
    public init(size: Float, transform: TRSTransform? = nil, device: MTLDevice) throws
    {
        // Generate meshes
        let allocator = MTKMeshBufferAllocator(device: device)
        let mdlMesh = MDLMesh.newBox(withDimensions: vector_float3(size, size, size),
                                     segments: vector_uint3(1, 1, 1),
                                     geometryType: .triangles,
                                     inwardNormals: true/*TODO*/,
                                     allocator: allocator)

        let mtkMesh = try MTKMesh(mesh:mdlMesh, device:device)
        
        try super.init(mdlMesh:mdlMesh, mtkMesh:mtkMesh, transform:transform, device:device)
    }
}
