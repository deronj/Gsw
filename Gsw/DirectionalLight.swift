//
//  DirectionalLight.swift
//  Gsw
//
//  Created by Deron Johnson on 8/26/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

class DirectionalLight: Light
{
    private let lightDirectionEC: float3
    private let halfAngleVectorEC: float3
    
    // We specify a directional light with a position, but this is just to give us a 
    // a direction. The light actually acts like it is positioned at infinity in that
    // direction. (position.w is ignored).
    //
    public init(ambient: float4, diffuse: float4, specular: float4, position: float4, camera: Camera)
    {
        let positionEC = matrix_multiply(camera.viewMatrix, position)
        lightDirectionEC = normalize(float3(positionEC.x, positionEC.y, positionEC.z))
        
        // Infinite eye (aka non-local viewer)
        let eyeVec = float3(0.0, 0.0, 1.0)
        
        halfAngleVectorEC = normalize(eyeVec - lightDirectionEC)

        super.init(ambient:ambient, diffuse:diffuse, specular:specular, position:position)
    }
    
    public override func upload(buffer: MTLBuffer, offset: Int)
    {
        lightStruct.type = LightTypeDirectional
        lightStruct.lightDirectionEC = lightDirectionEC
        lightStruct.halfAngleVecEC = halfAngleVectorEC
        super.upload(buffer:buffer, offset:offset)
    }
}
