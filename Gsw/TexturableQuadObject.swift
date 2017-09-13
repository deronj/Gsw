//
//  TexturableQuadObject.swift
//  Gsw
//
//  Created by Deron Johnson on 8/30/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

// A quad that either can optionally have a texture
//
class TexturableQuadObject: Renderable
{
    private class TexturableQuadSubmesh: Subrenderable
    {
        var material: Material

        let _texture: MTLTexture?
        
        let floatSize = MemoryLayout<Float>.size
        
        var geometryBuffer: MTLBuffer!
        var _indexBuffer: MTLBuffer!
        
        let _numVertices = 6
        
        let _numPositionAttrs = 3
        let _numNormalAttrs = 3
        var _numTexCoordAttrs = 0
        var _numVertexAttrs : Int { get {
            return _numPositionAttrs + _numNormalAttrs + _numTexCoordAttrs
        }}
        var _vertexSize : Int { get {
            return floatSize * _numVertexAttrs
        }}

        var vertexDescriptor: MTLVertexDescriptor!

        var _geometryDataUntextured: [Float] = [
            // Tri 0
            // x    y     z       nx   ny   nz
            -1.0, -1.0,  0.0,     0.0, 0.0, -1.0,
            -1.0,  1.0,  0.0,     0.0, 0.0, -1.0,
            1.0,   1.0,  0.0,     0.0, 0.0, -1.0,
            // Tri 1
            1.0,   1.0,  0.0,     0.0, 0.0, -1.0,
            -1.0,  -1.0, 0.0,     0.0, 0.0, -1.0,
            1.0,   -1.0, 0.0,     0.0, 0.0, -1.0]
        
        var _geometryDataTextured: [Float] = [
            // Tri 0
            // x  y    z   nx   ny   nz   s    t
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0,
            // Tri 1
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]
        
        var _indexData: [UInt16] = [
            0, 1, 2,
            3, 4, 5]
        
        init(size: Float, material theMaterial: Material, texture: MTLTexture? = nil, device: MTLDevice)
        {
            material = theMaterial
            _texture = texture
            
            _initGeometryBuffer(size:size, device:device)
            _initIndexBuffer(device:device)
            _createVertexDescriptor()
        }
        
        func _initGeometryBuffer(size: Float, device: MTLDevice)
        {
            // Scale the x and y postion coords
            for vertexIdx in 0..<_numVertices
            {
                _geometryDataUntextured[vertexIdx * _numVertexAttrs ] *= size
                _geometryDataUntextured[vertexIdx * _numVertexAttrs + 1] *= size
            }
            
            if _texture == nil
            {
                // Note: this requires _geometryDataUntextured to be [Float], not [[Float]]
                geometryBuffer = device.makeBuffer(bytes:&_geometryDataUntextured, length:_numVertices * _vertexSize)
            }
            else
            {
                _numTexCoordAttrs = 2
                
                // Interleave the position and normal attributes in with the texture coordinates
                // (We do this in this way because we wish to only define these attributes once
                // and because basic Swift isn't very good at precise dynamically allocated array size control.
                //
                // TODO: An alternative is to use ContiguousArray, but I'm not very familiar with this type.
                //
                // (Note: The array initializer syntax appears to allocate a ContigousArray)
                //
                for vertexIdx in 0..<_numVertices
                {
                    for attrIdx in 0..<(_numPositionAttrs + _numNormalAttrs)
                    {
                        _geometryDataTextured[vertexIdx * _numVertexAttrs + attrIdx] =
                            _geometryDataUntextured[vertexIdx * _numVertexAttrs + attrIdx]
                    }
                }
                
                geometryBuffer = device.makeBuffer(bytes:&_geometryDataTextured, length:_numVertices * _vertexSize)
            }
        
            geometryBuffer.label = "Quad Vertices"
            
            /* For Debug: Print first part of vertex buffer
            let pVertsRaw = geometryBuffer.contents()
            let pVertsOpaque = OpaquePointer(pVertsRaw)
            var pVertsFloat = UnsafeMutablePointer<Float>(pVertsOpaque)
            for idx in 0..<10
            {
                print("vertexAttr[\(idx)] = \(pVertsFloat.pointee)")
                pVertsFloat = pVertsFloat.advanced(by:1)
            }
            */
        }
        
        internal func _initIndexBuffer(device: MTLDevice)
        {
            _indexBuffer = device.makeBuffer(bytes:&_indexData, length:_indexData.count * MemoryLayout<UInt16>.size)
            _indexBuffer.label = "Quad Indices"
        }

        internal func _createVertexDescriptor()
        {
            let bufLayout = MTLVertexBufferLayoutDescriptor()
            bufLayout.stride = floatSize * _numVertexAttrs
            bufLayout.stepFunction = .perVertex
            bufLayout.stepRate = 1
            
            let positionAttr = MTLVertexAttributeDescriptor()
            positionAttr.format = .float3
            positionAttr.offset = 0
            positionAttr.bufferIndex = 0

            let normalAttr = MTLVertexAttributeDescriptor()
            normalAttr.format = .float3
            normalAttr.offset = MemoryLayout<Float>.size * _numPositionAttrs
            normalAttr.bufferIndex = 0

            vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0] = positionAttr
            vertexDescriptor.attributes[1] = normalAttr
            
            if _texture != nil
            {
                let texCoordAttr = MTLVertexAttributeDescriptor()
                texCoordAttr.format = .float2
                texCoordAttr.offset = MemoryLayout<Float>.size * (_numPositionAttrs + _numNormalAttrs)
                texCoordAttr.bufferIndex = 0
                vertexDescriptor.attributes[2] = texCoordAttr
            }
            vertexDescriptor.layouts[0] = bufLayout
            
            vertexDescriptor!.layouts[0].stepRate = 1
            vertexDescriptor!.layouts[0].stepFunction = .perVertex
        }
        
        func encode(to encoder: MTLRenderCommandEncoder)
        {
            if let tex = _texture
            {
                encoder.setFragmentTexture(tex, at:Int(DiffuseTextureBindIndex.rawValue))
            }

            encoder.setFragmentBuffer(material.materialBuffer, offset:material.materialBufferOffset,
                                      at:Int(MaterialBufferBindIndex.rawValue))
            
            encoder.drawIndexedPrimitives(type:.triangle, indexCount:_indexData.count, indexType:.uint16, indexBuffer:_indexBuffer, indexBufferOffset:0)
        }
    }
    
    public var label: String? = "Anonymous Object"
    
    public var subrenderables: Array<Subrenderable> {
        get { return [_submesh] }
    }

    private let _submesh: TexturableQuadSubmesh
    
    internal var _vertexDescriptor: MTLVertexDescriptor!
    public var vertexDescriptor: MTLVertexDescriptor {
        get { return _submesh.vertexDescriptor }
    }
    
    public var vertexBufferInfo: VertexBufferInfo {
        get {
            return (buffer:_submesh.geometryBuffer, offset:0)
        }
    }
    
    public var transform: TRSTransform?
    
    public var animator: Animator?
    
    // The default has no special options set
    public var vertexShaderOptions = VertexShaderOptions()
    
    // defaultMaterials true means use a default material for each submesh. Otherwise create a material based on the MDL submesh's material
    //
    init(size: Float, material: Material, texture: MTLTexture? = nil, transform theTransform: TRSTransform? = nil, device: MTLDevice) throws
    {
        _submesh = TexturableQuadSubmesh(size:size, material:material, texture:texture, device:device)
        transform = theTransform
    }
    
    public func setMaterial(_ material: Material)
    {
        _submesh.material = material
    }
}
