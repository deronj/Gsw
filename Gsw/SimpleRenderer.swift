//
//  SimpleRenderer.swift
//  Gsw
//
//  Created by Deron Johnson on 6/19/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import MetalKit

class SimpleRenderer: Renderer
{
    private let lightingEnabled = true
    private var _rotate = true
    
    private enum ObjectType {
        case cube
        case sphere
        case quad

        // .obj objects
        case airplane
        case monkeyHead
    }

    // Uses a single render pass
    private var _renderPass: ForwardOnScreenRenderPass?

    private var _objects : Array<Renderable>?
    
    private var _perObjectTransforms: PerObjectTransforms!

    private var _redMaterial: Material!
    private var _greenMaterial: Material!
    private var _blueMaterial: Material!
    
    private var _lights: Lights?
    
    override func _loadAssets(_ color0PixelFormat: MTLPixelFormat, _ depthStencilPixelFormat: MTLPixelFormat, _ sampleCount: Int) throws
    {
        _initRenderPass(color0PixelFormat)
        
        // Tell render pass what objects it will be working with
        //_objects = try _createSingleObject(objectType:.quad, textured:false, material:_greenMaterial)
        _objects = try _createSingleObject(objectType:.cube, textured:false, material:_greenMaterial)
        //_objects = try _createSingleObject(objectType:.sphere, textured:false, material:_blueMaterial)
        //_objects = try _createSingleObject(objectType:.monkeyHead, textured:false, material:_redMaterial)
        //_objects = try _createSingleObject(objectType:.airplane, textured:false, material:_redMaterial)
        //_objects = try _createFourRotatingObjects()
        //_objects = try _createTestObjects()
        
        _renderPass!.perObjectTransforms = _perObjectTransforms
        
        _renderPass!.add(objects:_objects!)
    }

    private func _initRenderPass(_ color0PixelFormat: MTLPixelFormat)
    {
        // TODO: eventually give more of the passdesc config responsibility to RenderPass
        let passDesc = MTLRenderPassDescriptor()
        
        // Use a single color attachment
        // Note: color attachment texture is set later
        let colorAttachment = MTLRenderPassColorAttachmentDescriptor()
        colorAttachment.loadAction = .clear
        colorAttachment.clearColor = MTLClearColor(red: 0.5, green: 0.4, blue: 0.5, alpha: 1.0)
        colorAttachment.storeAction = .store
        passDesc.colorAttachments[0] = colorAttachment

        // And use a depth attachment. The actual depth texture will be allocated by the pass.
        let depthAttachment = MTLRenderPassDepthAttachmentDescriptor()
        depthAttachment.loadAction = .clear
        depthAttachment.storeAction = .dontCare
        // TODO>>>>> Not assigning depth attach texture!
        passDesc.depthAttachment = depthAttachment
        
        // Enable lighting if necessary
        if lightingEnabled
        {
            _initLighting()
        }
        
        _renderPass = ForwardOnScreenRenderPass(descriptor:passDesc, color0PixelFormat:color0PixelFormat, sampleCount:1, camera:_camera,
                                                lights:_lights, device:device, renderer:self)
    }
    
    private func _initLighting()
    {        
        _initMaterials()
        _initLights()
    }
    
    // Initialize a set of materials we can use
    private func _initMaterials()
    {
        // For now, always use default specular reflectance
        let red = float4(1.0, 0.0, 0.0, 1.0)
        let green = float4(0.0, 1.0, 0.0, 1.0)
        let blue = float4(0.0, 0.0, 1.0, 1.0)
        
        _redMaterial = Material(diffuseAndAmbient:red, device:device)
        _greenMaterial = Material(diffuseAndAmbient:green, device:device)
        _blueMaterial = Material(diffuseAndAmbient:blue, device:device)
    }
    
    private func _initLights()
    {
        _lights = Lights(device:device)
        
        // TODO: for now, just use 1 directional light
        let dimGray = float4(0.2, 0.2, 0.1, 1.0)
        let white = float4(1.0, 1.0, 1.0, 1.0)

        // Light comes from "over the left shoulder" of viewer
        //let lightPositionWC = float4(_eyePosWC.x - 4.0, _eyePosWC.y + 4, _eyePosWC.z, 1.0)

        // TODO: x and y are flipped (negated) here. Maybe this has something to do with the way I flip normals in PerObjectTransforms
        let lightPositionWC = float4(4.0, 0.0, -4.0, 1.0)
        
        let light = DirectionalLight(ambient:dimGray, diffuse:white, specular:white, position:lightPositionWC, camera:_camera)
        _lights!.add(light)
        _lights!.upload()
    }
    
    // textured is ignored for .obj objects. For these, the texture comes from the .obj spec
    private func _createSingleObject(objectType: ObjectType, textured: Bool = false, material: Material? = nil, size: Float = 3.0) throws -> Array<Renderable>
    {
        var objects = Array<Renderable>()

        var numTransformableObjects = 0
        if (_rotate)
        {
            numTransformableObjects = 1
        }
        _perObjectTransforms = PerObjectTransforms(device:device, numTransformableObjects:numTransformableObjects)
        
        var transform: TRSTransform?
        if _rotate
        {
            transform = TRSTransform(perObjectTransforms:_perObjectTransforms)
        }
        
        // Load texture
        var tex: MTLTexture?
        if textured
        {
            let textureFileName = "StoneWallTexture.jpg"
            tex = TextureLoader.loadTexture(textureFileName, device:device)
            if tex == nil
            {
                fatalError("Cannot load texture \(textureFileName)")
            }
        }
        
        // Non-obj objects must have a specified material
        switch objectType
        {
            case .cube, .sphere, .quad:
                guard material != nil else { fatalError("Object must have a material") }

            default: break;
        }
        
        var obj: Renderable
        switch objectType
        {
            case .cube:
                if textured
                {
                    obj = try TexturedCubeObject(size:size, texture:tex!, transform:transform, device:device)
                    obj.label = "A Textured Cube"
                }
                else
                {
                    obj = try CubeObject(size:size, transform:transform, device:device)
                    obj.label = "A Cube"
                }
                obj.setMaterial(material!)
            
            case .sphere:
                if textured
                {
                    obj = try TexturedSphereObject(size:size, texture:tex!, transform:transform, device:device)
                    obj.label = "A Textured Sphere"
                }
                else
                {
                    obj = try SphereObject(size:size, transform:transform, device:device)
                    obj.label = "A Sphere"
                }
                obj.setMaterial(material!)
            
            case .quad:
                obj = try TexturableQuadObject(size:size, material:material!, texture:tex, transform:transform, device:device)
            
            case .airplane:
                obj = try AirplaneObject(transform:transform, device:device)
                obj.label = "An Airplane"
            
            case .monkeyHead:
                obj = try MonkeyHeadObject(transform:transform, device:device)
                obj.label = "Suzanne the Monkey"
        }
        
        objects.append(obj)
        
        if _rotate
        {
            // Configure object to rotate once every 5 seconds
            let rotationTimeInSecs: Float = 5.0
            let rotationsPerSec = 1 / rotationTimeInSecs
            let degreesPerRotation: Float = 360.0
            let framesPerSec: Float = 1.0/60.0
            let deltaAnglePerFrame = rotationsPerSec * degreesPerRotation / framesPerSec
            obj.animator = RotatingAnimator(renderable:obj, speed:deltaAnglePerFrame, axis:float3(1.0, 1.0, 0.0))
        }

        return objects
    }
    
    // TODO:DEBUG
    // An untextured cube and an untextured quad
    private func _createTestObjects() throws -> Array<Renderable>
    {
        var objects = Array<Renderable>()
        
        _perObjectTransforms = PerObjectTransforms(device:device, numTransformableObjects:4)
        
        var transform: TRSTransform
        var obj: Renderable
        
        #if false
        // An untextured cube
        transform = TRSTransform(perObjectTransforms:_perObjectTransforms)
        //transform.setTranslation(float3(-4.0, 0.0, -4.0))
        obj = try CubeObject(size:3.0, transform:transform, device:device)
        obj.setMaterial(_greenMaterial)
        obj.label = "Untextured Cube"
        objects.append(obj)
        #endif
        
        // An untextured quad
        transform = TRSTransform(perObjectTransforms:_perObjectTransforms)
        //transform.setTranslation(float3(4.0, 0.0, 4.0))
        obj = try TexturableQuadObject(size:5.0, material:_greenMaterial, texture:nil, device:device)
        obj.label = "Untextured Quad"
        objects.append(obj)
        
        // TODO: combine with the rotation code from createSingleObject
        // Configure all objects to rotate once every 5 seconds
        let rotationTimeInSecs: Float = 5.0
        let rotationsPerSec = 1 / rotationTimeInSecs
        let degreesPerRotation: Float = 360.0
        let framesPerSec: Float = 1.0/60.0
        let deltaAnglePerFrame = rotationsPerSec * degreesPerRotation / framesPerSec
        for idx in 0..<objects.count
        {
            var obj = objects[idx]
            obj.animator = RotatingAnimator(renderable:obj, speed:deltaAnglePerFrame, axis:float3(1.0, 1.0, 0.0))
        }
        
        return objects
    }

    // An untextured cube, a small textured cube, a big textured cube and an airplane
    private func _createFourRotatingObjects() throws -> Array<Renderable>
    {
        var objects = Array<Renderable>()
        
        _perObjectTransforms = PerObjectTransforms(device:device, numTransformableObjects:4)

        // An untextured cube
        var transform = TRSTransform(perObjectTransforms:_perObjectTransforms)
        transform.setTranslation(float3(-4.0, 0.0, -4.0))
        var obj: Renderable = try CubeObject(size:3.0, transform:transform, device:device)
        obj.label = "Untextured Cube"
        objects.append(obj)
        
        // A small textured cube
        transform = TRSTransform(perObjectTransforms:_perObjectTransforms)
        transform.setTranslation(float3(4.0, 0.0, -4.0))
        transform.setScale(0.5)
        obj = try TexturedCubeObject(size:3.0, textureFileName: "StoneWallTexture.jpg", transform:transform, device:device)
        obj.label = "A Small Textured Cube"
        objects.append(obj)
        
        // A big textured cube
        transform = TRSTransform(perObjectTransforms:_perObjectTransforms)
        transform.setTranslation(float3(-4.0, 0.0, 4.0))
        transform.setScale(2.0)
        obj = try TexturedCubeObject(size:3.0, textureFileName: "StoneWallTexture.jpg", transform:transform, device:device)
        obj.label = "A Big Textured Cube"
        objects.append(obj)
        
        // An airplane plane
        transform = TRSTransform(perObjectTransforms:_perObjectTransforms)
        transform.setTranslation(float3(4.0, 0.0, 4.0))
        transform.setScale(5.0)
        obj = try AirplaneObject(transform:transform, device:device)
        obj.label = "An Airplane"
        objects.append(obj)

        // TODO: combine with the rotation code from createSingleObject
        // Configure all objects to rotate once every 5 seconds
        let rotationTimeInSecs: Float = 5.0
        let rotationsPerSec = 1 / rotationTimeInSecs
        let degreesPerRotation: Float = 360.0
        let framesPerSec: Float = 1.0/60.0
        let deltaAnglePerFrame = rotationsPerSec * degreesPerRotation / framesPerSec
        for idx in 0..<objects.count
        {
            var obj = objects[idx]
            obj.animator = RotatingAnimator(renderable:obj, speed:deltaAnglePerFrame, axis:float3(1.0, 1.0, 0.0))
        }
        
        return objects
    }
    
    #if false
    // Random object creation
    
    // TODO
    private let _NUM_OBJECTS = 10
    private let _MAX_OBJECT_SIZE: Float = 3.0
    
    // TODO
    private let _objectTypes = [
        "Cube",
        "Airplane"
    ]

    // TODO
    // Objects are initially positioned with their origins within this cube
    private let creationBounds = BoundingBox(x:0.0, y:0.0, z:0.0, width:200.0, height:200.0, depth:200.0)

    // TODO
    // TODO: Initially objects just stay still
    private func createRandomObjects() throws -> Array<Renderable>
    {
        _perObjectTransforms = PerObjectTransforms(device:device, numTransformableObjects:_NUM_OBJECTS)

        for _ in 0..<_NUM_OBJECTS
        {
            createRandomObject()
        }
        
        return _objects!
    }

    // TODO
    private func createRandomObject()
    {
        // TODO: let center = creationBounds.randomPointWithin()

        let transform = TRSTransform(perObjectTransforms:_perObjectTransforms)

        // TODO: for now, always create cubes, but eventually pick a random object type
        var object: Renderable
        let whichTypeIdx = Int(arc4random_uniform(UInt32(_objectTypes.count)))
        switch _objectTypes[whichTypeIdx]
        {
            case "Cube":
                object = try! CubeObject(_MAX_OBJECT_SIZE, transform:transform, device:device)
            
            case "Airplane":
                fallthrough
            default:
                // TODO: object = AirplaneObject(_MAX_OBJECT_SIZE, perObjectTransforms:_perObjectTransforms, device:device)
                fatalError("Not yet implemented")
       }
        
        // TODO: eventually assign a random behavior
        object.animator = RotatingAnimator(renderable:object, speed:45.0, axis:float3(1.0, 1.0, 1.0))!

        _objects!.append(object)
    }
    #endif
    
    override func _update(_ timeDelta: Float)
    {
        // Required. Too bad there is no enforcement like in Objective-C.
        super._update(timeDelta)
        
        // Update all animatable objects
        for object in _objects!
        {
            if let animator = object.animator
            {
                animator.update(timeDelta:timeDelta)
            }
        }

        // The render pass may change its behavior from frame-to-frame
        _renderPass!.update(constantBufferIndex: _constantBufferIndex, timeDelta: timeDelta)
    }
    
    override func _draw(in view: MTKView)
    {
        let commandBuffer = _commandQueue.makeCommandBuffer()
        commandBuffer.label = "SimpleRenderer CommandBuffer"

        // Get next drawable
        if let drawable = view.currentDrawable
        {
            _renderPass!.render(to:commandBuffer, on:drawable, constantBufferIndex:_constantBufferIndex)
            _renderPass!.endOfFrameActions(commandBuffer:commandBuffer, drawable:drawable, renderer:self)
        }
    }
    
    public override func reshape (_ size: CGSize)
    {
        _renderPass!.reshape(float2(Float(size.width), Float(size.height)))
    }
}
