//
//  MonkeyHeadObject.swift
//  Gsw
//
//  Created by Deron Johnson on 8/29/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import MetalKit

class MonkeyHeadObject: MDLMeshObject
{
    // TODO: currently, the resource must contain only one mesh
    let _resourceName = "suzanne.obj"
    
    // Order of vertex attributes
    enum VertexAttributeIndex: Int
    {
        case position = 0
        case normal
        case texCoord
    }
    
    // The vertex format which will be used by the Metal pipeline
    private var _mtlVertexDescriptor = MTLVertexDescriptor()
    
    // The vertex format to be loaded by Model IO
    private var _mdlVertexDescriptor: MDLVertexDescriptor
    
    public init(transform: TRSTransform? = nil, device: MTLDevice) throws
    {
        // Initialize Metal vertex format
        // xyz Nxyz st (interleaved)
        
        let	positionAttr = _mtlVertexDescriptor.attributes[Int(VertexAttributeDescriptorIndexPosition.rawValue)]!
        positionAttr.format = .float3
        positionAttr.offset = 0
        positionAttr.bufferIndex = Int(GeometryVertexBufferBindIndex.rawValue)
        
        let	normalAttr = _mtlVertexDescriptor.attributes[Int(VertexAttributeDescriptorIndexNormal.rawValue)]!
        normalAttr.format = .float3
        normalAttr.offset = 12
        normalAttr.bufferIndex = Int(GeometryVertexBufferBindIndex.rawValue)
        
        let	texCoordAttr = _mtlVertexDescriptor.attributes[Int(VertexAttributeDescriptorIndexTexcoord.rawValue)]!
        texCoordAttr.format = .half2
        texCoordAttr.offset = 24
        texCoordAttr.bufferIndex = Int(GeometryVertexBufferBindIndex.rawValue)
        
        let layout = _mtlVertexDescriptor.layouts[Int(GeometryVertexBufferBindIndex.rawValue)]!
        layout.stride = 28
        layout.stepRate = 1
        layout.stepFunction = .perVertex
        
        // Initialize ModelIO vertex descriptor
        
        _mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(_mtlVertexDescriptor)
        
        let mdlPositionAttr = _mdlVertexDescriptor.attributes[Int(VertexAttributeDescriptorIndexPosition.rawValue)] as! MDLVertexAttribute
        mdlPositionAttr.name = MDLVertexAttributePosition
        
        let mdlNormalAttr = _mdlVertexDescriptor.attributes[Int(VertexAttributeDescriptorIndexNormal.rawValue)] as! MDLVertexAttribute
        mdlNormalAttr.name = MDLVertexAttributeNormal
        
        let mdlTexCoordAttr = _mdlVertexDescriptor.attributes[Int(VertexAttributeDescriptorIndexTexcoord.rawValue)] as! MDLVertexAttribute
        mdlTexCoordAttr.name = MDLVertexAttributeTextureCoordinate
        
        // Load the asset
        let assetURL = Bundle.main.url(forResource:_resourceName, withExtension:nil)
        guard assetURL != nil else { throw MeshError.badUrl }
        let bufferAllocator = MTKMeshBufferAllocator(device:device)
        let asset = MDLAsset(url:assetURL!, vertexDescriptor:_mdlVertexDescriptor, bufferAllocator:bufferAllocator)
        
        // Create MetalKit meshes.
        let mtkMeshes: Array<MTKMesh>
        var mdlMeshes: NSArray?
        do
        {
            mtkMeshes = try MTKMesh.newMeshes(from:asset, device:device, sourceMeshes:&mdlMeshes)
        }
        catch
        {
            throw MeshError.assetNotFound
        }
        guard mdlMeshes != nil else { throw MeshError.invalidSourceMeshes }
        guard mtkMeshes.count == 1 else { throw MeshError.notSingleMeshAsset }
        
        try super.init(mdlMesh:mdlMeshes![0] as! MDLMesh, mtkMesh:mtkMeshes[0], transform:transform, device:device, defaultMaterials:false)
    }
    
    internal override func _createVertexDescriptor()
    {
        // Go with what we configured in init()
        _vertexDescriptor = _mtlVertexDescriptor
    }
    
}
