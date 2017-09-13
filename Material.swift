//
//  Material.swift
//  Gsw
//
//  Created by Deron Johnson on 6/19/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

// A simple material. Can be textured or non-textured. When diffuseTexture is non-nil the diffuse color is ignored.
//
class Material
{
    public private(set) var fragmentShaderOptions = FragmentShaderOptions()
    
    public var opacity: Float = 1.0
    
    // Defaults
    public static let defaultAmbient = float4(1.0, 1.0, 1.0, 1.0) // White
    public static let defaultDiffuse = float4(1.0, 1.0, 1.0, 1.0) // White
    public static let defaultEmission = float4(0.0, 0.0, 0.0, 1.0) // Black
    public static let defaultSpecularPower: Float = 50.0
    
    // White specular reflectance uses the pure color of the light
    // This isn't the case for real materials, but it looks okay for now
    public static let defaultSpecular = float4(1.0, 0.0, 0.0, 1.0)
    
    // Only for untextured material
    public var ambient = defaultAmbient
    public var diffuse = defaultDiffuse
    
    // For all materials
    public var emission = defaultEmission
    public var specular: float4
    public var specularPower: Float
    
    public var diffuseTexture: MTLTexture?
    {
        willSet { _updateShaderOptions(for:newValue) }
    }
    
    public var materialBuffer: MTLBuffer?
    public var materialBufferOffset: Int = 0
    
    public init(specular theSpecular: float4 = defaultSpecular,
                specularPower theSpecularPower: Float = defaultSpecularPower,
                device: MTLDevice)
    {
        // TODO: uncomment this if this class ever becomes an NSObject again (for hashValue)
        //super.init()
        
        specular = theSpecular
        specularPower = theSpecularPower
        
        upload(device:device)
    }

    // Initialize untextured
    public init(diffuseAndAmbient theDiffuseAndAmb: float4,
                            specular theSpecular: float4 = defaultSpecular,
                            specularPower theSpecularPower: Float = defaultSpecularPower,
                            device: MTLDevice)
    {
        specular = theSpecular
        specularPower = theSpecularPower

        ambient = theDiffuseAndAmb
        diffuse = theDiffuseAndAmb
        
        upload(device:device)
    }
    
    // Initialize textured
    public convenience init(diffuseTexture tex: MTLTexture, device: MTLDevice)
    {
        self.init(device:device)
        _updateShaderOptions(for:tex)
        diffuseTexture = tex
        upload(device:device)
    }
    
    private func _updateShaderOptions(for newDiffuseTex: MTLTexture?)
    {
        if newDiffuseTex === diffuseTexture
        {
            return
        }
        
        // Update frag shader options appropriately
        if newDiffuseTex != nil
        {
            if !fragmentShaderOptions.contains(.diffuseTextured)
            {
                fragmentShaderOptions.insert(.diffuseTextured)
            }
        }
        else
        {
            fragmentShaderOptions.remove(.diffuseTextured)
        }
    }
    
    // Load the material params into their buffer.
    // 
    // For now, an object's material is constant for all frames.
    //
    public func upload(device: MTLDevice)
    {
        if materialBuffer == nil
        {
            // TODO: would this be faster on macOS if it were private?
            materialBuffer = device.makeBuffer(length:MemoryLayout<MaterialStruct>.stride, options:.storageModeShared)
        }

        if diffuseTexture == nil
        {
            let mps = MaterialStruct(emissiveColor:emission, ambientReflectance:ambient, diffuseReflectance:diffuse, specularReflectance:specular, shininess:specularPower)
            materialBuffer!.contents().storeBytes(of:mps, toByteOffset:0, as:MaterialStruct.self)
        }
        else
        {
            let black = float4(0.0, 0.0, 0.0, 1.0)
            let mps = MaterialStruct(emissiveColor:emission, ambientReflectance:black, diffuseReflectance:black, specularReflectance:specular, shininess:specularPower)
            materialBuffer!.contents().storeBytes(of:mps, toByteOffset:0, as:MaterialStruct.self)
        }
    }
}
