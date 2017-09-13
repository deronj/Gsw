//
//  OffScreenRenderPass.swift
//  Gsw
//
//  Created by Deron Johnson on 7/5/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

// The descriptor passed to the initialize should be initialized for the behavior you want. Except for
// descriptor colorAttachments[0].texture; this should be left uninitialized when you call the initializer.
// After you construct an instance of this render pass, call setColor0Target to specify the target texture.
//
// TODO: currently supports only one target (color0)
//
class OffScreenRenderPass: RenderPass
{
    public required init(target tex: MTLTexture, descriptor: MTLRenderPassDescriptor, camera: Camera,
                         lights: Lights, device: MTLDevice, renderer: Renderer, perObjectTransforms: PerObjectTransforms)
    {
        let color0PixelFormat = tex.pixelFormat
        let sampleCount = tex.sampleCount
        
        descriptor.colorAttachments[0].texture = tex
        
        super.init(descriptor:descriptor, color0PixelFormat:color0PixelFormat, sampleCount:sampleCount,
                   camera:camera, lights:lights, device:device, renderer:renderer)

        let targetSize = float2(Float(tex.width), Float(tex.height))
        _resizeDepthStencilTextures(targetSize)
        _globalTransforms.targetSize = targetSize
    }
    
    // Performs all rendering actions necessary to encode this pass's objects to the given command buffer. (This oes not include present and commit).
    // By default, simply sorts objects and encoders them using a single encoder. If a subclass wants to do more than this, it should override.
    public func render(to cmdBuf: MTLCommandBuffer, constantBufferIndex: Int, perObjectTransforms: PerObjectTransforms)
    {
        _sortSubobjects()
        _encode(to:cmdBuf, constantBufferIndex:constantBufferIndex)
    }
    
    public override func reshape(_ targetSize: float2)
    {
        // No-op
    }
}
