//
//  Light.swift
//  Gsw
//
//  Created by Deron Johnson on 8/26/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

// Shared attributes for all types of lights
class Light
{
    internal var lightStruct = LightStruct()
    
    public init()
    {
        lightStruct.ambientColor = vector4(0.0, 0.0, 0.0, 1.0)
        lightStruct.diffuseColor = vector4(0.0, 0.0, 0.0, 1.0)
        lightStruct.specularColor = vector4(0.0, 0.0, 0.0, 1.0)
    }

    public init(ambient: float4, diffuse: float4, specular: float4, position pos: float4)
    {
        lightStruct.ambientColor = ambient
        lightStruct.diffuseColor = diffuse
        lightStruct.specularColor = specular
    }
        
    // Upload light into the light buffer
    public func upload(buffer: MTLBuffer, offset: Int)
    {
        buffer.contents().storeBytes(of:lightStruct, toByteOffset:offset, as:LightStruct.self)
    }
}
