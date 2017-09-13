//
//  MDLSubmeshObject.swift
//  Gsw
//
//  Created by Deron Johnson on 5/27/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import MetalKit

class MDLSubmeshObject: Subrenderable
{
    public var material: Material
    
    private var _submesh: MTKSubmesh!
    private let _device: MTLDevice

    init(mtkSubmesh: MTKSubmesh, mdlSubmesh: MDLSubmesh, device: MTLDevice, defaultMaterial: Bool = true)
    {
        _submesh = mtkSubmesh;
        _device = device
        
        if defaultMaterial
        {
            material = Material(device:device)
        }
        else
        {
            guard mdlSubmesh.material != nil else { fatalError("Model IO submesh material is empty") }

            material = Material(device:_device)
            _initMaterialFromSubmesh(mdlSubmesh.material!)
        }
    }

    private func _initMaterialFromSubmesh(_ mdlMat: MDLMaterial)
    {
        
        // Iterate material properties
        for idx in 0..<mdlMat.count
        {
            let property = mdlMat[idx]
            if let prop = property
            {
                switch prop.name
                {
                    case "baseColorMap":
                        if prop.type == .string
                        {
                            let propString = prop.stringValue
                            if let propStr = propString
                            {
                                let textureFileName = URL(string:propStr)!.lastPathComponent
                                if let tex = TextureLoader.loadTexture(textureFileName, device:_device)
                                {
                                    material.diffuseTexture = tex
                                }
                                else
                                {
                                    fatalError("Cannot load texture \(textureFileName)")
                                }
                            }
                        }

                    case "specularColor":
                        if prop.type == .float4
                        {
                            material.specular = prop.float4Value
                        }
                        else
                        {
                            let val = prop.float3Value
                            material.specular = float4(val.x, val.y, val.z, 1.0)
                        }
                
                    case "emission":
                        if prop.type == .float4
                        {
                            material.emission = prop.float4Value
                        }
                        else
                        {
                            let val = prop.float3Value
                            material.emission = float4(val.x, val.y, val.z, 1.0)
                        }
                    
                    default: break
                }
            }
        }
    }

    public func encode(to encoder: MTLRenderCommandEncoder)
    {
        if let tex = material.diffuseTexture
        {
            encoder.setFragmentTexture(tex, at:Int(DiffuseTextureBindIndex.rawValue))
        }

        encoder.setFragmentBuffer(material.materialBuffer, offset:material.materialBufferOffset,
                                  at:Int(MaterialBufferBindIndex.rawValue))
        
        encoder.drawIndexedPrimitives(type:_submesh.primitiveType, indexCount: _submesh.indexCount, indexType:_submesh.indexType,
                                      indexBuffer:_submesh.indexBuffer.buffer, indexBufferOffset:_submesh.indexBuffer.offset)
    }
}
