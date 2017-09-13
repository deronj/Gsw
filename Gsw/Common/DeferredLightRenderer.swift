NOT; YET

//
//  DeferredLightRenderer.swift
//  Gsw
//
//  Created by Deron Johnson on 6/8/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

#if false
    
class DeferredLightRenderer : Renderer
{
    // TODO
    // Max API memory buffer size.
    private let MAX_UNIFORM_BUF_SIZE = 1024*1024
    
    // Shadow Pass State and Resources
    private var _shadowPassDesc: MTLRenderPassDescriptor?
    private var _shadowPassRenderPipeline: MTLRenderPipeline?
    private var _shadowDepthStencilState: MTLDepthStencilState?
    private var _shadowPassUniformBuf: MTLBuffer?
    
    // Skybox State
    // TODO: is this really a dup of the shadow ds state?
    private var _skyboxDepthStencilState: MTLDepthStencilState?

    // The main geometry to be rendered
    private var _objects : Array<RenderableObject>?
    
    private let _fairies : FairyList
    
    // TODO: eventually will become a dag
    private let _renderPasses = Array<RenderPass>
    
    init()
    {
        _fairies = FairyList()
    }

    // TODO
    override func _loadAssets(_ color0PixelFormat: MTLPixelFormat, _ depthStencilPixelFormat: MTLPixelFormat, _ sampleCount: Int)
    {
        // An MDLMesh to be used with MetalKit requires a MetalKit allocator
        let allocator = MTKMeshBufferAllocator(device: device!)
        
        // Generate meshes
        let mdlMesh = MDLMesh.newBox(withDimensions: vector_float3(1.0, 1.0, 1.0),
                                     segments: vector_uint3(1, 1, 1),
                                     geometryType: .triangles,
                                     inwardNormals: false,
                                     allocator: allocator)
        _boxMesh = try! MTKMesh(mesh: mdlMesh, device: device!)
        
        // Allocate one region of memory for the uniform buffer
        _uniformBuffer = device!.makeBuffer(length:MAX_UNIFORM_BUF_SIZE, options:MTLResourceOptions.storageModeShared)
        _uniformBuffer!.label = "UniformBuffer"
        
        // Load the vertex program into the library
        let vertexProgram = _defaultLibrary!.makeFunction(name:"vertexLight")
        
        // Load the fragment program into the library
        let fragmentProgram = _defaultLibrary!.makeFunction(name:"fragmentPassThrough")
        
        // Create a vertex descriptor from the MTKMesh
        let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(_boxMesh!.vertexDescriptor)
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // Create a reusable pipeline state
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "MyPipeline"
        pipelineStateDescriptor.sampleCount = sampleCount
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.vertexDescriptor = vertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = color0PixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = depthStencilPixelFormat
        
        _renderPipeline = try! device!.makeRenderPipelineState(descriptor:pipelineStateDescriptor)
        
        let depthStateDesc = MTLDepthStencilDescriptor()
        depthStateDesc.depthCompareFunction = .less
        depthStateDesc.isDepthWriteEnabled = true
        _depthStencilState = device!.makeDepthStencilState(descriptor:depthStateDesc)
        
        // Specify passes
        _initRenderPasses()
    }
    
    private func _initRenderPasses()
    {
        // Pass 1: Shadow
        _renderPasses.append(ShadowPass)
        
        
        // TODO: _renderShadowPass(commandBuffer:cmdBuf)
        
        // Pass 1: Shadow
        // TODO: _renderShadowPass(commandBuffer:cmdBuf)
        
        // Remaining passes: Use same encoder
        let encoder = cmdBuf.makeRenderCommandEncoder(descriptor:_shadowPassDesc!)
        encoder.label = "Encoder for Remaining Passes"
        
        // Remaining passes
        // TODO: notyet _renderSkyBox(encoder:encoder)
        _renderGBuffer(encoder:encoder)
        _renderLightBuffer(encoder:encoder, time:frameTime) // TODO: where to get frametime?
        _composite(encoder:encoder) // TODO: includes sun
        
        // Render fairies directly to framebuffer
        _renderFairies(encoder:encoder)
        encoder.endEncoding()
        

    }

    // TODO
    override func _updateFrame(_ animationTick: Int)
    {
        let base_model = matrix_multiply(matrix_from_translation(0.0, 0.0, 5.0), matrix_from_rotation(_rotation, 0.0, 1.0, 0.0));
        let base_mv = matrix_multiply(_viewMatrix, base_model)
        let modelViewMatrix = matrix_multiply(base_mv, matrix_from_rotation(_rotation, 1.0, 1.0, 1.0))
        
        var uniformBufferData : FrameUniforms = FrameUniforms()
        uniformBufferData.normal = matrix_invert(matrix_transpose(modelViewMatrix))
        uniformBufferData.projectionView = matrix_multiply(_projectionMatrix, modelViewMatrix)
        
        // Load constant buffer data into appropriate buffer at current frame index
        _uniformBuffer!.contents().storeBytes(of:uniformBufferData, toByteOffset:MemoryLayout<FrameUniforms>.stride * _uniformBufferIndex, as:FrameUniforms.self)
        
        _rotation += 0.01
    }
    
    // TODO
    override func _drawFrame(desc: MTLRenderPassDescriptor, drawable: MTLDrawable)
    {
        // Create a new command buffer for each renderpass to the current drawable
        let cmdBuf = _commandQueue!.makeCommandBuffer()
        cmdBuf.label = "Command Buffer"
        
        // Encode render passes
        for renderPass in _renderPasses
        {
            renderPass.addEncoder(to:cmdBuf)
        }

        // Schedule a present
        commandBuffer.present(drawable)
        
        // Completion handler signals the semaphore when GPU has finished
        commandBuffer.addCompletedHandler { commandBuffer in
            self._frameSemaphore.signal()
        }
        
        // Advance uniform buffers to next frame
        _uniformBufferIndex = (_uniformBufferIndex + 1) % BufferSet.MAX_INFLIGHT_FRAMES
        
        // Make it so!
        commandBuffer.commit()
    }
    
   
    private func _renderSkyBox(encoder: MTLRenderCommandEncoder)
    {
        encoder.pushDebugGroup("Skybox")
        
        encoder.setRenderPipelineState(_skyBoxRenderPipeline)

        // TODO: transfer this comment to load assets:
        // Use the stencil buffer to ensure these pixels are not touched later
        encoder.setDepthStencilState(_skyBoxDepthStencilState)

        encoder.setVertexBuffer(_skyBoxGeometryBuf!, offset:0, at:Int(SkyBoxGeometryIndex.rawValue))
        encoder.setVertexBuffer(_skyBoxFrameUniformBuffer, offset:(MemoryLayout<SkyBoxFrameUniforms>.stride * _uniformBufferIndex),
                                at:Int(SkyBoxFrameUniformsIndex.rawValue))
        
        encoder.setFragmentTexture(skyboxTexture, at:Int(FragmentSkyBoxTextureIndex.rawValue))
        
        // TODO: study more: how is this value used and computed?
        encoder.setFragmentBuffer(_clearColorBuffer1, offset:0, at:Int(FragmentSkyBoxClearColorBufferIndex.rawValue))
        
        let numCubeFaces = 6
        let numFaceVertices = 4
        for idx in 0..<numCubeFaces
        {
            encoder.drawPrimitives(type:.typeTriangleStrip, vertexStart:(idx * numFaceVertices), vertexCount:numFaceVertices)
        }

        encoder.popDebugGroup()
    }

    private func _renderGBuffer(encoder: MTLRenderCommandEncoder)
    {
        encoder.pushDebugGroup("Gbuffer")
        
        encoder.setRenderPipelineState(_gbufferRenderPipeline)
        encoder.setCullMode(MTLCullModeBack)
        encoder.setDepthStencilState(_gBufferDepthStencilState)
        encoder.setStencilReferenceValue(128) // TODO: where does this come from? make symbol
        
        encoder.setVertexBuffer(_geometryBuf!, offset:0, at:Int(BufferGeometryIndex.rawValue))
        encoder.setVertexBuffer(_gBufferFrameUniformBuffer!, offset:(MemoryLayout<GBuferFrameUniforms>.stride * _uniformBufferIndex),
                                at:Int(GBufferFrameUniformsIndex.rawValue))

        
        // TODO: study more: how is this value used and computed?
        encoder.setFragmentBuffer(_clearColorBuffer2, offset:0, at:Int(FragmentGbufferClearColorBufferIndex.rawValue))
        
        for object in _objects!
        {
            object.encode(to:encoder)
        }

        encoder.popDebugGroup()
    }

    private func _renderLightBuffer(encoder: MTLRenderCommandEncoder, time:UInt16)
    {
        encoder.pushDebugGroup("Light Buffer")
        
        _fairies.update(time:time)

        // >>>>
        encoder.popDebugGroup()
    }
    
    private func _composite(encoder: MTLRenderCommandEncoder)
    {
        encoder.pushDebugGroup("Compositing")
        encoder.popDebugGroup()
    }
    
    private func _renderFairies(encoder: MTLRenderCommandEncoder)
    {
        encoder.pushDebugGroup("Render Fairies")
        encoder.popDebugGroup()
    }
}

#endif
