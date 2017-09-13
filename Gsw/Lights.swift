//
//  Lights.swift
//  Gsw
//
//  Created by Deron Johnson on 8/28/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

class Lights
{
    // Must be bound to LightsBufferBindIndex at render time
    public var buffer: MTLBuffer?
    
    public subscript(index: Int) -> Light { get { return _lights[index] } }

    public var count: Int { get { return _lights.count } }

    private let _device: MTLDevice
    
    private var _lights: Array<Light> = []
    
    private var _MAX_LIGHTS = 2
    
    private let _LIGHT_STRIDE = MemoryLayout<LightStruct>.stride

    private let _disabledLight = DisabledLight()
    
    public init (device: MTLDevice)
    {
        _device = device
    }
    
    public func add(_ light: Light)
    {
        guard _lights.count + 1 <= _MAX_LIGHTS else { fatalError("You may only specify \(_MAX_LIGHTS) lights") }
        
        _lights.append(light)
    }
    
    public func upload()
    {
        if (buffer == nil)
        {
            // TODO: would this be faster on macOS if it were private?
            buffer = _device.makeBuffer(length:_MAX_LIGHTS * _LIGHT_STRIDE, options:.storageModeShared)
        }

        var offset = 0
        for index in 0..<_MAX_LIGHTS
        {
            var light: Light = _disabledLight
            if index < _lights.count
            {
                light = _lights[index]
            }
            light.upload(buffer:buffer!, offset:offset)
            offset += _LIGHT_STRIDE
        }
    }
}
