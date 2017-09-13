//
//  ForwardOnScreenRenderPass.swift
//  Gsw
//
//  Created by Deron Johnson on 6/19/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

class ForwardOnScreenRenderPass: OnScreenRenderPass
{
    public required init(descriptor: MTLRenderPassDescriptor, color0PixelFormat: MTLPixelFormat, sampleCount: Int, camera: Camera,
                         lights: Lights?, device: MTLDevice, renderer: Renderer)
    {
        super.init(descriptor:descriptor, color0PixelFormat:color0PixelFormat, sampleCount:sampleCount, camera:camera,
                   lights:lights, device:device, renderer:renderer)
        _renderPassName = "Forward Render Pass"

        // Render fragments on top (in front of what was there before).
        // Z = 0 is at the eye, so these are the ones that. And, in order to 
        // implement a painter's algorithm, ties should win.
        let dssDesc = MTLDepthStencilDescriptor()
        dssDesc.depthCompareFunction = .lessEqual
        dssDesc.isDepthWriteEnabled = true
        _depthStencilState = device.makeDepthStencilState(descriptor:dssDesc)
    }
}
