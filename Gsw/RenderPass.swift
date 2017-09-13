//
//  RenderPass.swift
//  Gsw
//
//  Created by Deron Johnson on 6/19/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

// An abstract base class for a render pass. A pass renders objects according to a specific graphics technique.
// This base class implements most of the basic machinery to render a single pass of opaque objects.
// The submeshes of the objects are sorted into same-material groups in order to reduce render pipe switching overhead.
// A single Metal render encoder will be used. A renderer should use one or more render passes to perform its rendering.
//
// Renderers should use one of two concrete subclasses which derive from this base class:
//
// 1. OnScreenRenderPass: Renders to the current drawable of an MTKView.
//    This provides a rendering function which renders to the drawable. This is render(to:on:constantBufferIndex:).
//
// 2. OffScreenRenderPass: Renders to an (offscreen) texture.
//    The texture is specified via setColor0Target. And there is a function render(to:constantBufferIndex:) which renders to this texture.
//
// The client should notify the pass when the size of the rendering target changes (via reshape), so the projection matrix can be recalculated.
//
// The perObjectTransforms property must be set prior to use.
//
class RenderPass
{
    // For Debug: Configure a vertex debug buffer
    private let _debugVertexShader = DEBUG_VERTEX_SHADER == 1 ? true : false
    private var _debugVertexShaderBuffers: BufferSet?
    private let _debugVertexShaderVertexSize = /*MemoryLayout<Vertex_Input_Textured_Unlit>.stride = (if it could be included in Swift)*/ 48
    
    private typealias SubobjectInfo = (subobject: Subrenderable,
                                       renderPipeHash: Int,
                                       renderPipe: MTLRenderPipelineState,
                                       vertexBufferInfo: Renderable.VertexBufferInfo,
                                       objTransformBufOffset: Int)
    
    private typealias ShaderCache =  [String: MTLFunction]

    // The objects to be rendered by this renderpass
    internal var _objects = Array<Renderable>()
    
    private let _device: MTLDevice
    internal let _passDescriptor: MTLRenderPassDescriptor
    
    // TODO: currently only a single color attachment is supported
    private let _numColorAttachments = 1

    private let _sampleCount: Int
    
    private var _camera: Camera
    
    private var _lightingEnabled = false
    private let _lights: Lights?
    
    // To be set by the subclass
    internal var _color0PixelFormat: MTLPixelFormat
    
    // Allocated by subclass if it uses depth or stencil
    private var _depthStencilTexture: MTLTexture?
    
    // Allocated by subclass if it uses depth or stencil (for multisample only)
    private var _depthStencilResolveTexture: MTLTexture?

    // The matrices which are constant throughout a frame
    internal var _globalTransforms: GlobalTransforms
    
    // The sortable list of subobjects along with their sort keys
    private var _subobjectInfos = Array<SubobjectInfo>()
    
    // If true, the list of subobjects needs to be sorted prior to calling encode.
    internal var _needsResort = true
    
    private var renderPipeCache: [Int/*Hash*/:MTLRenderPipelineState] = [:]

    internal var _shaderLib: MTLLibrary!
    
    public var perObjectTransforms: PerObjectTransforms!
    
    // These are populated with thedefault shaders. The subclass can add more using _getShaderFromCache.
    // Shaders are identified by pass-specific names.
    //
    private var _vertexShaderCache = ShaderCache()
    private var _fragmentShaderCache = ShaderCache()
    
    private weak var _renderer: Renderer!
    
    // For use by only the subclasses.
    //
    // The descriptor should be initialized for the behavior you want. Except for descriptor colorAttachments[0].texture;
    // this should be left uninitialized. How it gets set depends on the subclass. OnScreenRenderPass sets this to the
    // texture of the drawable. In contrast, OffScreenRendering requires the caller to call setColor0Target.
    //
    // Multisampling: if the sample count is > 1 the descriptor must provide a resolve texture, must provide a resolving store action.
    // After the pass is complete the output of the pass will be contained in this resolve texture.
    //
    // Note: A curious weakness of Metal is that you can't read the number of color attachments from the
    // descriptor. So we must provide it separately.
    //
    internal init(descriptor: MTLRenderPassDescriptor, color0PixelFormat: MTLPixelFormat, sampleCount: Int,
                  camera: Camera, lights: Lights?, device: MTLDevice, renderer: Renderer)
    {
        _passDescriptor = descriptor
        _device = device
        _color0PixelFormat = color0PixelFormat
        _sampleCount = sampleCount
        _camera = camera
        _renderer = renderer
        
        _lights = lights
        _lightingEnabled = lights != nil && lights!.count > 0
        
        _globalTransforms = GlobalTransforms()

        _shaderLib = _device.newDefaultLibrary()
        
        if _debugVertexShader
        {
            let bufLen = Int(DEBUG_VERTEX_SHADER_NUM_VERTICES) * _debugVertexShaderVertexSize
            _debugVertexShaderBuffers = BufferSet(device: device, length:bufLen)
        }
    }

    ////////////////////////
    // MARK: Object Addition

    // Add an object to be rendered. For best performance, objects should be added at init time.
    public func add(_ object: Renderable)
    {
        var objTransformBufOffset: Int = -1
        if let transform = object.transform
        {
            objTransformBufOffset = transform.bufferOffset
        }
        
        for subobject in object.subrenderables
        {
            let (renderPipe, renderPipeHash) = _renderPipeForSubrenderable(subobject, object:object)
            let subobjectInfo = (subobject: subobject, renderPipeHash:renderPipeHash, renderPipe:renderPipe,
                                 vertexBufferInfo:object.vertexBufferInfo, objTransformBufOffset:objTransformBufOffset)
            _subobjectInfos.append(subobjectInfo)
        }
        
        _objects.append(object)
        
        // Any time we add new subjects we need to (lazy) resort it
        _needsResort = true
    }

    // Add object to be rendered. For best performance, objects should be added at init time.
    public func add(objects: Array<Renderable>)
    {
        for object in objects
        {
            var objTransformBufOffset: Int = -1
            if let transform = object.transform
            {
                objTransformBufOffset = transform.bufferOffset
            }

            for subobject in object.subrenderables
            {
                let (renderPipe, renderPipeHash) = _renderPipeForSubrenderable(subobject, object:object)
                let subobjectInfo = (subobject: subobject, renderPipeHash:renderPipeHash, renderPipe:renderPipe,
                                     vertexBufferInfo:object.vertexBufferInfo, objTransformBufOffset:objTransformBufOffset)
                _subobjectInfos.append(subobjectInfo)
            }
        }
        
        _objects.append(contentsOf:objects)

        _needsResort = true
    }
    
    private func _renderPipeForSubrenderable(_ subobject: Subrenderable, object: Renderable) -> (MTLRenderPipelineState, Int)
    {
        let rpDesc = _renderPipeDescriptor(for:subobject, object:object)
        
        // Check cache
        let hash = rpDesc.hash
        if let renderPipe = renderPipeCache[hash]
        {
            return (renderPipe, hash)
        }
        
        if _debugVertexShader
        {
            rpDesc.isRasterizationEnabled = false
        }
                
        // Create new pipe (his is expensive), and then cache it. So this is why it is better
        // to add objects to a render pass at init time.
        let renderPipe = try! _device.makeRenderPipelineState(descriptor:rpDesc)
        renderPipeCache[hash] = renderPipe
        
        return (renderPipe, hash)
    }
    
    ///////////////////
    // MARK: Rendering

    // Sort objects in ascending order by render pipe (first) and vertexBuffer (second)
    internal func _sortSubobjects()
    {
        _subobjectInfos.sort() {
            $0.renderPipeHash < $1.renderPipeHash
        }
        
        _needsResort = false
    }

    // Create an encoder for the command buffer and encode the pass's objects into it.
    // It is the caller's responsibility to present (if necessary) and commit the command buffer.
    // Note: the pass subclass must make sure the subobjects are properly sorted (with _sortObjects) before calling this.
    //
    internal func _encode(to cmdBuf: MTLCommandBuffer, constantBufferIndex: Int)
    {
        guard _subobjectInfos.count > 0 else { return }
        guard _depthStencilState != nil else { fatalError("Render Pass subclass must provide a depth stencil state") }

        let encoder = cmdBuf.makeRenderCommandEncoder(descriptor:_passDescriptor)
        encoder.label = "\(_renderPassName) Encoder"
        
        // TODO
        // encoder.setCullMode(.back)
        //encoder.setFrontFacing(.counterClockwise)
        
        // Set context state
        encoder.pushDebugGroup("Render Subobjects")
        
        // A render pass has a single depth/stencil state
        encoder.setDepthStencilState(_depthStencilState)
        
        // Bind to the combined, per-object transforms buffer. Soon we'll change the offset to point to the transforms of specific objects
        encoder.setVertexBuffer(perObjectTransforms.getBuffer(constantBufferIndex), offset:0, at:Int(PerObjectMatricesBufferBindIndex.rawValue))
        
        // Bind the light buffer, if lighting is enabled
        if _lightingEnabled
        {
            encoder.setVertexBuffer(_lights!.buffer, offset:0, at:Int(LightsBufferBindIndex.rawValue))
            encoder.setFragmentBuffer(_lights!.buffer, offset:0, at:Int(LightsBufferBindIndex.rawValue))
        }
        
        // Render first object specially, to avoid use of optional render pipe and vertex buffer previous variables
        let subobjectInfo = _subobjectInfos[0]
        encoder.setRenderPipelineState(subobjectInfo.renderPipe)
        let vertexBufferInfo = subobjectInfo.vertexBufferInfo
        encoder.setVertexBuffer(vertexBufferInfo.buffer, offset:vertexBufferInfo.offset, at:Int(GeometryVertexBufferBindIndex.rawValue))
        if subobjectInfo.objTransformBufOffset != -1
        {
            encoder.setVertexBufferOffset(subobjectInfo.objTransformBufOffset, at:Int(PerObjectMatricesBufferBindIndex.rawValue))
        }
        subobjectInfo.subobject.encode(to:encoder)
        
        // Render rest of the objects, switching pipe as necessary
        var renderPipePrev = subobjectInfo.renderPipe
        for idx in 1..<_subobjectInfos.count
        {
            let subobjectInfo = _subobjectInfos[idx]

            let rp = subobjectInfo.renderPipe
            if (rp !== renderPipePrev)
            {
                encoder.setRenderPipelineState(rp)
                renderPipePrev = rp
            }
            
            let vertexBufferInfo = subobjectInfo.vertexBufferInfo
            encoder.setVertexBuffer(vertexBufferInfo.buffer, offset:vertexBufferInfo.offset, at:Int(GeometryVertexBufferBindIndex.rawValue))
            
            if subobjectInfo.objTransformBufOffset != -1
            {
                encoder.setVertexBufferOffset(subobjectInfo.objTransformBufOffset, at:Int(PerObjectMatricesBufferBindIndex.rawValue))
            }
            
            subobjectInfo.subobject.encode(to:encoder)
        }
        
        encoder.popDebugGroup()

        encoder.endEncoding()
    }

    //////////////////////////////////////////
    // MARK: Shader and Render Pipe Management
    
    private func _getShaderFromCache(_ shaderCache: inout ShaderCache, _ shaderName: String) -> MTLFunction
    {
        // First see if it is in the cache
        if let function = shaderCache[shaderName]
        {
            return function
        }
        
        let function = _shaderLib.makeFunction(name:shaderName)
        if let funct = function
        {
            print("Loaded shader function \(shaderName)")
            shaderCache[shaderName] = funct
            return funct
        }
        else
        {
            fatalError("Could not load shader \(shaderName)")
        }
    }

    // Default shader selection
    private func _selectShaders(desc: MTLRenderPipelineDescriptor, vertexShaderOptions: VertexShaderOptions, material mat: Material)
    {
        let fragShaderOptions = mat.fragmentShaderOptions

        let textured = fragShaderOptions.contains(.diffuseTextured)

        var vertexShader: String?
        var fragShader: String?
        
        if !_lightingEnabled
        {
            vertexShader = textured ? "vertex_Textured_Unlit" : "vertex_Untextured_Unlit"
            fragShader = textured ? "fragment_Textured_Unlit" : "fragment_Untextured_Unlit"
        }
        else
        {
            // Special Case: 1 directional ligght
            if _lights!.count == 1 && _lights![0] is DirectionalLight
            {
                // TODO: textured 1dir versions have not yet been implemented
                assert(!textured)
                vertexShader = textured ? "vertex_Textured_Lit_1dir" : "vertex_Untextured_Lit_1dir"
                fragShader = textured ? "fragment_Textured_Lit_1dir" : "fragment_Untextured_Lit_1dir"
            }

            // Fall back to general lighting
            if vertexShader == nil
            {
                // TODO: textured general versions have not yet been implemented
                assert(!textured)
                vertexShader = textured ? "vertex_Textured_Lit_General" : "vertex_Untextured_Lit_General"
                fragShader = textured ? "fragment_Textured_Lit_General" : "fragment_Untextured_Lit_General"
            }
        }

        // Cache the shaders
        desc.vertexFunction = _getShaderFromCache(&_vertexShaderCache, vertexShader!)
        desc.fragmentFunction = _getShaderFromCache(&_fragmentShaderCache, fragShader!)
    }
    
    // Initializes the render pipe attachment info, based in the pass's descriptor (e.g. attachments)
    // and whether transparent rendering is needed.
    //
    // TODO: currently supports only one color attachment
    //
    private func _configRenderPipeAttachmentInfo(desc rpDesc: MTLRenderPipelineDescriptor, blended: Bool)
    {
        let colorRPAttDesc = MTLRenderPipelineColorAttachmentDescriptor()
        colorRPAttDesc.pixelFormat = _color0PixelFormat

        if blended
        {
            colorRPAttDesc.isBlendingEnabled = true
            // TODO: init blend params
        }
        else
        {
            colorRPAttDesc.isBlendingEnabled = false
        }
            
        rpDesc.colorAttachments[0] = colorRPAttDesc
        
        let depthStencilPixelFormat = _renderer.getDesiredDepthStencilPixelFormat()
        if _passDescriptor.depthAttachment != nil
        {
            rpDesc.depthAttachmentPixelFormat = depthStencilPixelFormat
        }
        if _passDescriptor.stencilAttachment != nil
        {
            rpDesc.stencilAttachmentPixelFormat = depthStencilPixelFormat
        }
    }

    // Resize the depth and/or stencil textures as necessary
    // Note: we currently only support combined depth/stencil.
    //
    internal func _resizeDepthStencilTextures(_ targetSize: float2)
    {
        // Are we using depth and/or stencil?
        let depthAttachment = _passDescriptor.depthAttachment
        let stencilAttachment = _passDescriptor.stencilAttachment
        if depthAttachment == nil && stencilAttachment == nil
        {
            return
        }
        
        _resizeDepthStencilTexture(targetSize:targetSize, resolve:false)
        if (_sampleCount > 1)
        {
            _resizeDepthStencilTexture(targetSize:targetSize, resolve:true)
        }
    }
    
    // Performs first time allocation or resizing
    private func _resizeDepthStencilTexture(targetSize: float2, resolve: Bool)
    {
        let newWidth = Int(targetSize.x)
        let newHeight = Int(targetSize.y)
        
        let currentDepthStencilTex = resolve ? _depthStencilResolveTexture : _depthStencilTexture
        
        var alloc = false
        if let tex = currentDepthStencilTex
        {
            // Check for size change
            alloc = newWidth != tex.width || newHeight != tex.height
        }
        else
        {
            // First time allocation
            alloc = true
        }
        
        if !alloc
        {
            return
        }
        
        let newTex = _allocateDepthStencilTexture(newWidth, newHeight, resolve ? _sampleCount : 1)
        if resolve
        {
            _depthStencilResolveTexture = newTex
        }
        else
        {
            _depthStencilTexture = newTex
        }

        // Attach to pass descriptor
        if let depthAttachment = _passDescriptor.depthAttachment
        {
            if resolve
            {
                depthAttachment.resolveTexture = _depthStencilResolveTexture
            }
            else
            {
                depthAttachment.texture = _depthStencilTexture
            }
        }
        if let stencilAttachment = _passDescriptor.stencilAttachment
        {
            if resolve
            {
                stencilAttachment.resolveTexture = _depthStencilResolveTexture
            }
            else
            {
                stencilAttachment.texture = _depthStencilTexture
            }
        }
    }

    private func _allocateDepthStencilTexture(_ width: Int, _ height: Int, _ sampleCount: Int) -> MTLTexture
    {
        // TODO: someday: currently, only combined is supported
        let pixelFormat = MTLPixelFormat.depth32Float_stencil8

        let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:pixelFormat, width:width, height:height, mipmapped:false)
        texDesc.sampleCount = _sampleCount
        texDesc.storageMode = .private
        texDesc.usage = .renderTarget

        return _device.makeTexture(descriptor:texDesc)
    }

    ////////////////////////////////
    // MARK: Subclass Responsibility

    // The name of the render pass
    internal var _renderPassName = "Unnamed Render Pass"

    internal var _depthStencilState: MTLDepthStencilState?
    
    // Return a render pipe descriptor that is a combination of what the pass and the subobject need.
    // Performs pass-specific and object-specific render pipe configuration. 
    //
    // By default, the following configurations are made. The subclass should override if it needs anything more.
    //    /
    // + Appropriate vertex and fragment shaders are selected based on whether or not the object is textured
    //   and lighting is enabled.
    //
    // + Simple additive blending is enabled if the opacity of the object is < 1.0.
    //
    // The vertex descriptor and patch parameters are derived from the object. So are the vertex shader options.
    //
    // TODO: could eventually adopt an uber shader approach for object shader options (using Function Constants)
    //
    internal func _renderPipeDescriptor(for subobject: Subrenderable, object: Renderable) -> MTLRenderPipelineDescriptor
    {
        let rpDesc = MTLRenderPipelineDescriptor()
        
        rpDesc.vertexDescriptor = object.vertexDescriptor
        
        rpDesc.sampleCount = _sampleCount
        
        let mat = subobject.material
        _selectShaders(desc:rpDesc, vertexShaderOptions:object.vertexShaderOptions, material:mat)
        
        // TODO: impl transparent pass
        let blended = mat.opacity < 1.0

        _configRenderPipeAttachmentInfo(desc:rpDesc, blended:blended)
        
        return rpDesc
    }

    public func update(constantBufferIndex: Int, timeDelta: Float)
    {
        // If the camera has changed since we last rendered, get the latest view matrix
        // and make sure the global transforms are up-to-date
        if _camera.dirty
        {
            _globalTransforms.viewMatrix = _camera.viewMatrix
        }
        
        if _globalTransforms.dirty
        {
            _globalTransforms.update()
        }
        
        // Update the static transforms with the global transforms
        assert(perObjectTransforms != nil)
        perObjectTransforms.updateStaticTransform(globalTransforms:_globalTransforms, constantBufferIndex:constantBufferIndex)
        
        // For each object in this, combine the global transforms with the object's model matrix to produce the per-object matrices.
        // And load thee values into the perObjectMatrices buffer.
        for object in _objects
        {
            if let modelTransform = object.transform
            {
                if modelTransform.dirty
                {
                    modelTransform.update()
                }
                perObjectTransforms.combineAndUpload(modelTransform:modelTransform, globalTransforms:_globalTransforms, constantBufferIndex:constantBufferIndex)
            }
        }
    }
    
    // Typical Metal end-of-frame processing. Subclass should override if it needs something different.
    public func endOfFrameActions(commandBuffer: MTLCommandBuffer, renderer: Renderer)
    {
        commandBuffer.addCompletedHandler { commandBuffer in
            renderer.signalFrameSemaphore()
        }
        
        commandBuffer.commit()
        
        if _debugVertexShader
        {
            commandBuffer.waitUntilCompleted()
            
            let debugBuf = _debugVertexShaderBuffers![renderer._constantBufferIndex]
            
            // TODO: this assumes the vertex format xyz Nxyz st
            var pVertex = debugBuf.contents()
            for idx in 0..<DEBUG_VERTEX_SHADER_NUM_VERTICES
            {
                var pVert = pVertex
                let x = pVert.load(as:Float.self); pVert = pVert.advanced(by:4)
                let y = pVert.load(as:Float.self); pVert = pVert.advanced(by:4)
                let z = pVert.load(as:Float.self); pVert = pVert.advanced(by:4)
                print("Vertex\(idx) (\(x), \(y), \(z))")
                pVertex = pVertex.advanced(by:_debugVertexShaderVertexSize)
            }
        }

        renderer.advanceConstantBufferIndex()
    }
    
    public func reshape(_ targetSize: float2)
    {
        fatalError("Subclass must implement")
    }
}
