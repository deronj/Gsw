//
//  ShadowPass.swift
//  Gsw
//
//  Created by Deron Johnson on 6/17/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

/*
 TODO: Shadow must do:
 [encoder setVertexBuffer: _structureVertexBuffer offset: 0 atIndex: 0];
 i[encoder setVertexBuffer: _zOnlyProjectionBuffers[_currFrameIndex] offset: 0 atIndex: 1];
 
 */

import Metal

class ShadowPass : RenderPass
{
    private let _device: MTLDevice
    
    private let _passDesc: MTLRenderPassDescriptor?
    
    private let _renderPipeline: MTLRenderPipelineState?
    
    private let _cullMode = MTLCullModeFront
    
    init(device: MTLDevice)
    {
        _device = device
        
        // init encdesc
    }

    // Encode an encoder to the given command buffer.
    // For best performance, the objects should be sorted into consecutive subgroups that share the same renderpipe hash.
    // Also for best performance
    func submitEncoder(to cmdbuf:MTLCommandBuffer, objects:Array<RenderableObject>)
    {
        let encoder = cmdBuf.makeRenderCommandEncoder(descriptor:_passDesc!)
        encoder.label = "Shadow Pass Encoder"
        
        encoder.pushDebugGroup("Shadow Pass")
        
        encoder.setDepthStencilState(_depthStencilState)
        encoder.setCullMode(_cullMode)
        
        // TODO: really need?
        //encoder.setDepthBias(0.01, slopeScale:1.0f, clamp:0.01)
        
        // Move into the object encodings?
        encoder.setVertexBuffer(_geometryBuf!, offset:0, at:Int(ShadowGeometryIndex.rawValue))
        encoder.setVertexBuffer(_shadowFrameUniformBuffer!, offset:(MemoryLayout<ShadowFrameUniforms>.stride * _uniformBufferIndex),
                                at:Int(ShadowFrameUniformsIndex.rawValue))
        
        // Must handle first object differently because there is no invalid hash value
        var renderPipeHash
        var renderPipeline
        if objects.count > 0
        {
            (renderPipe, renderPipeHash) = objects[0].getRenderPipe(for:self)
            encoder.setRenderPipelineState(renderPipe)
            objects[idx].encode(to:encoder)
        }

        // Change renderpipe whenever we encounter an object that needs
        var prevRenderPipeHash: Int
        for idx in 1..<_objects.count
        {
            // If an object hasn't been associated with this pass it will have a hash which is always different than prevHash
            // and will always create a unique render pipe, rather than sharing with others in the pass

            renderPipeHash = objects[idx].getRenderPipeHash(for:self, prevHash:prevRenderPipeHash)
            if (renderPipeHash != prevRenderPipeHash)
            {
                renderPipeline = objects[idx].getRenderPipe(self)
                encoder.setRenderPipelineState(renderPipe)
            }

            objects[idx].encode(to:encoder)
        }
        
        encoder.popDebugGroup()
        encoder.endEncoding()
    }

}

