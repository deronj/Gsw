//
//  Renderer.swift
//  Gsw
//
//  Created by Deron Johnson on 5/21/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import MetalKit

public class Renderer
{
    // The renderers allow multiple frames to be in-flight at a time (for optimal Metal performance).
    // This is the maximum number of these frames.
    public static let MAX_INFLIGHT_FRAMES = 3
    
    // Used to enforce the max number of in-flight frames
    var _frameSemaphore = DispatchSemaphore(value: Renderer.MAX_INFLIGHT_FRAMES)
    
    // This the shader constant (aka uniform) buffer (of a buffer set) to use for next frame.
    var _constantBufferIndex = 0
    
    var device : MTLDevice!
    var _commandQueue : MTLCommandQueue!
    
    var _camera: Camera!
    
    // The eye position in world coords
    internal var _eyePosWC = float3(0.0, 0.0, 0.0)
    
    // The renderer uses the color pixel format and sample count it is told, but
    // tells the client what depth/stencil format it needs
    //
    func getDesiredDepthStencilPixelFormat() -> MTLPixelFormat
    {
        // TODO: someday: We don't support separate depth/stencil yet. It isn't very well supported on all hardware.
        // So we only support combined depth/stencil at this time.
        return .depth32Float_stencil8
    }

    // Must be called before use
    func initialize(_ color0PixelFormat: MTLPixelFormat, _ depthStencilPixelFormat: MTLPixelFormat, _ sampleCount: Int, camera: Camera) throws -> MTLDevice
    {
        _camera = camera

        _setupMetal()
        try _loadAssets(color0PixelFormat, depthStencilPixelFormat, sampleCount)
        
        return device
    }

    private func _setupMetal()
    {
        // Set the view to use the default
        device = MTLCreateSystemDefaultDevice()!
    
        // Create a new command queue
        _commandQueue = device.makeCommandQueue()
    }

    func updateAndDraw(in view: MTKView)
    {
        // TODO: for now: eventually base on prev frame time
        let timeDelta: Float = 1.0 / 60.0

        // Updates to the scene objects
        _update(timeDelta)

        _draw(in:view)
    }
    
    // Signal the renderer's in-flight frame semaphore
    func signalFrameSemaphore()
    {
        _frameSemaphore.signal()
    }

    // Advance the in-flight buffer index
    func advanceConstantBufferIndex()
    {
        _constantBufferIndex = (_constantBufferIndex + 1) % Renderer.MAX_INFLIGHT_FRAMES
    }
    
    func setEyePosition(_ posWC: float3)
    {
        _eyePosWC = posWC
    }
    
    //////////////////////////
    // Subclass Must Implement
    
    internal func _loadAssets(_ color0PixelFormat: MTLPixelFormat, _ depthStencilPixelFormat: MTLPixelFormat, _ sampleCount: Int) throws
    {
        fatalError("Subclass must implement")
    }

    // Subclass should override in order to alter scene. But subclass must always first call super.update()
    internal func _update(_ timeDelta: Float)
    {
        // Synchronize frame rendering
        _ = _frameSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        // Recognize camera movement
        _camera.update(timestep: TimeInterval(timeDelta))
    }

    internal func _draw(in view: MTKView)
    {
        fatalError("Subclass must implement")
    }
    
    // Subclasses must inform the render passes of the target size change
    public func reshape (_ size: CGSize)
    {
        fatalError("Subclass must implement")
    }
}
