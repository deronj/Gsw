//
//  OnScreenRenderPass.swift
//  Gsw
//
//  Created by Deron Johnson on 7/5/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal
import Cocoa

// The descriptor passed to the initialize should be initialized for the behavior you want. Except for 
// descriptor colorAttachments[0].texture; this should be left uninitialized when you call the initializer. 
// This class will laster set this to the texture of the drawable.
//
// TODO: currently supports only one target (color0)
//
class OnScreenRenderPass: RenderPass
{
    public required override init(descriptor: MTLRenderPassDescriptor, color0PixelFormat: MTLPixelFormat, sampleCount: Int, camera: Camera,
                                  lights: Lights?, device: MTLDevice, renderer: Renderer)
    {
        super.init(descriptor:descriptor, color0PixelFormat:color0PixelFormat, sampleCount:sampleCount,
                   camera:camera, lights:lights, device:device, renderer:renderer)
    }

    // Renders to the specified drawable, as color attachment 0, by encoding commands to the given command buffer.
    // Performs all rendering actions necessary to encode this pass's objects to the given command buffer (This does not include present and commit).
    // By default, this simply sorts objects and encoders them using a single encoder. If a subclass wants to do more than this, it should override.
    //
    public func render(to cmdBuf: MTLCommandBuffer, on drawable: CAMetalDrawable, constantBufferIndex: Int)
    {
        _passDescriptor.colorAttachments[0].texture = drawable.texture

        if (_needsResort)
        {
            _sortSubobjects()
        }
        
        _encode(to:cmdBuf, constantBufferIndex:constantBufferIndex)
    }
    
    // Typical Metal end-of-frame processing for on-screen rendering
    public func endOfFrameActions(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable, renderer: Renderer)
    {
        commandBuffer.present(drawable)
        
        super.endOfFrameActions(commandBuffer:commandBuffer, renderer:renderer)
    }
    
    // The client is required to call the reshape method whenever the drawable size changes.
    public override func reshape(_ targetSize: float2)
    {
        _resizeDepthStencilTextures(targetSize)
        _globalTransforms.targetSize = targetSize
    }
}
