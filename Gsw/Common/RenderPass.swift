//
//  RenderPass.swift
//  Gsw
//
//  Created by Deron Johnson on 6/5/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

protocol RenderPass
{
    // Must call before using
    func initialize()
    
    // Encode an encoder to the given command buffer
    func submitEncoder(to cmdbuf:MTLCommandBuffer)
}

#if false
    
import Metal

class Resource
{
    
}

class Buffer : Resource
{
    var buf : MTLBuffer

    func makeResident() throws
}

class Texture : Resource
{
    var tex : MTLTexture
}

// Abstract class
class Pass
{
    // Resources that are consumed by the pass
    var inputBuffers : Array<Buffer>
    var inputTexture : Array<Texture>

    // Resources that are produced by the pass
    var inputBuffers : Array<Buffer>
    var inputTexture : Array<Texture>
    
    // TODO: eventually have subpasses (multiple renderpipelines per pass)
    
    func encode() throws
    {
        assert(false, "Subclass must implement")
    }
}

class RenderPass : Pass
{
    // renderencoder
}

class ComputePass : Pass
{
    
}

#endif
