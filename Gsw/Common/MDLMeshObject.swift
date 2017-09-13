//
//  MDLMeshObject.swift
//  Gsw
//
//  Created by Deron Johnson on 6/16/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import MetalKit
import ModelIO

enum MeshError: String, Error {
    case badUrl = "Cannot form resource URL"
    case assetNotFound = "Cannot find mesh asset"
    case invalidSourceMeshes = "Invalid source meshes"
    case notSingleMeshAsset = "Asset must contain only one mesh"
    case unsupportedNumberOfVertexBuffers = "Unsupported Number of Vertex Buffers"
}

// A renderable object whose geometry is specified by a mesh
class MDLMeshObject: Renderable
{
    public var label: String? = "Anonymous Object"
    
    var subrenderables: Array<Subrenderable> {
        get { return _submeshes }
    }
    
    // By default, this is derived from the MTKMesh, with no instancing. The subclass can override this via _createVertexDescriptor().
    internal var _vertexDescriptor: MTLVertexDescriptor!
    public var vertexDescriptor: MTLVertexDescriptor {
        get { return _vertexDescriptor }
    }
    
    public var vertexBufferInfo: VertexBufferInfo {
        get {
            let mtkMeshBuffer = _mtkMesh.vertexBuffers[0]
            return (buffer:mtkMeshBuffer.buffer, offset:mtkMeshBuffer.offset)
        }
    }
    
    public var transform: TRSTransform?
    
    public var animator: Animator?
    
    // The default has no special options set
    public var vertexShaderOptions = VertexShaderOptions()

    private let _mdlMesh: MDLMesh
    private let _mtkMesh: MTKMesh
    private var _submeshes = Array<MDLSubmeshObject>()

    // defaultMaterials true means use a default material for each submesh. Otherwise create a material based on the MDL submesh's material
    //
    init(mdlMesh: MDLMesh, mtkMesh: MTKMesh, transform theTransform: TRSTransform? = nil, device: MTLDevice, defaultMaterials: Bool = true) throws
    {
        guard mtkMesh.vertexBuffers.count == 1 else { throw MeshError.unsupportedNumberOfVertexBuffers }
        
        _mdlMesh = mdlMesh
        _mtkMesh = mtkMesh
        
        // Create an array to hold this mesh's submeshes.
        for idx in 0..<mtkMesh.submeshes.count
        {
            // Create our own app specifc submesh to hold the MetalKit submesh.
            let mdlSubmesh = mdlMesh.submeshes?[idx] as! MDLSubmesh
            let submesh = MDLSubmeshObject(mtkSubmesh:mtkMesh.submeshes[idx],
                                         mdlSubmesh:mdlSubmesh,
                                         device:device,
                                         defaultMaterial:defaultMaterials)
            _submeshes.append(submesh)
        }
                
        _createVertexDescriptor()
        
        transform = theTransform
    }
    
    // Subclass Responsibility

    internal func _createVertexDescriptor()
    {
        // Create a vertex descriptor from the MTKMesh
        _vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(_mdlMesh.vertexDescriptor)
        _vertexDescriptor!.layouts[0].stepRate = 1
        _vertexDescriptor!.layouts[0].stepFunction = .perVertex
    }

    public func setMaterial(_ material: Material)
    {
        for submesh in _submeshes
        {
            submesh.material = material
        }
    }
 }
