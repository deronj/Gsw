//
//  TexturedCubeObject.swift
//  Gsw
//
//  Created by Deron Johnson on 7/19/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import MetalKit

enum TexturedCubeError: String, Error
{
    case badFile = "Cannot find texture file name"
}

class TexturedCubeObject: CubeObject
{
    private let _device: MTLDevice
    
    public init(size: Float, texture tex: MTLTexture, transform: TRSTransform? = nil, device: MTLDevice) throws
    {
        _device = device
        try super.init(size:size, transform:transform, device:device)
        setTexture(tex)
    }
    
    public convenience init(size: Float, textureFileName: String, transform: TRSTransform? = nil, device:MTLDevice) throws
    {
        if let tex = TextureLoader.loadTexture(textureFileName, device:device)
        {
            try self.init(size:size, texture:tex, transform:transform, device:device)
        }
        else
        {
            throw TexturedCubeError.badFile
        }
    }
    
    public func setTexture(_ tex: MTLTexture)
    {
        // Assign texture to all submeshes
        let texturedMat = Material(diffuseTexture:tex, device:_device)
        for var subrenderable in subrenderables
        {
            subrenderable.material = texturedMat
        }
    }
}
