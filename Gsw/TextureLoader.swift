//
//  TextureLoader.swift
//  Gsw
//
//  Created by Deron Johnson on 7/19/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import MetalKit

class TextureLoader
{
    // Name includes extension
    class func loadTexture(_ withName: String, device: MTLDevice, sRGB: Bool = true) -> MTLTexture?
    {
        let fullPath = Bundle.main.url(forResource: withName, withExtension:"")
        
        do {
            let loader = MTKTextureLoader(device: device)
            let options = [MTKTextureLoaderOptionSRGB : sRGB]
            let tex = try loader.newTexture(withContentsOf: fullPath!, options: options as [String : NSObject]?)
            return tex
        }
        catch _ {
            return nil
        }
    }
}

