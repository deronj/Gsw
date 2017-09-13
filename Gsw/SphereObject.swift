//
//  SphereObject.swift
//  Gsw
//
//  Created by Deron Johnson on 8/28/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import MetalKit

class SphereObject: MDLMeshObject
{
    public init(size: Float, transform: TRSTransform? = nil, device: MTLDevice) throws
    {
        // Generate meshes
        let allocator = MTKMeshBufferAllocator(device: device)
        
        let mdlMesh = MDLMesh.newEllipsoid(withRadii:vector_float3(size, size, size),
                                           radialSegments:100,
                                           verticalSegments:100,
                                            geometryType:.triangles,
                                            inwardNormals:false,
                                            hemisphere:false,
                                            allocator: allocator)
        
        let mtkMesh = try MTKMesh(mesh:mdlMesh, device:device)
        
        try super.init(mdlMesh:mdlMesh, mtkMesh:mtkMesh, transform:transform, device:device)
    }
}
