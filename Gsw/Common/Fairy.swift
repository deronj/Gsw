NOT; YET

//
//  Fairy.swift
//  Gsw
//
//  Created by Deron Johnson on 6/11/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal
import Darwin

class Fairy
{
    // Some fairies move across the floor and some go upward
    enum FairyType
    {
        case horizontal     // Some fairies go along the floor
        case vertical       // Some rise up
        case stationary     // This is a light which doesn't move
    }
    
    var type: FairyType

    private let ATTENUATION_RADIUS: Float = 0.5

    private var _light: Light

    private let _fairyColor: float3
    private let _fairyAngle: Float
    private let _fairyPhase: Float
    private let _fairySpeed: Float
    
    // Each fairy is created with a random set of properties
    required init(type theType: FairyType)
    {
        type = theType
        
        // TODO
        _fairyColor = float3(randomFloat(0.0, 1.0), randomFloat(0.0, 1.0), randomFloat(0.0, 1.0))
        _fairyAngle = randomFloat(0.0, Float.pi * 2.0)
        _fairyPhase = randomFloat(0.0, 1.0)
        _fairySpeed = randomFloat(5.0, 15.0)
    }
    
    func update(time: TimeInterval, camera: Camera)
    {
        switch (type)
        {
            case .horizontal:
                var fairyTime = Float(time) / _fairySpeed + _fairyPhase
                fairyTime -= floor(fairyTime);
                
                // Fairy light diminishes over time
                let fairyAlpha: Float = min(1.0, (0.5 - abs(0.5 - fairyTime)) * 8.0)

                // The time-increasing angle rotation multiplier of lights circulating along the floor
                let rot = 0.5 + 2.0 * pow(fairyTime, 5.0)
                
                _light.position = float4(cos(_fairyAngle) * rot, Float(fairyTime * 6.0), sin(_fairyAngle) * rot, 1.0)
                let attenRadiusColor = _fairyColor * fairyAlpha
                _light.attenuationRadius = float4(attenRadiusColor.x, attenRadiusColor.y, attenRadiusColor.z, ATTENUATION_RADIUS)

            case .vertical:
                // Radius away from y axis: increases toward top
                let radius: Float = 2.0 + 0.85 * cos(Float(time) / (4.0 * _fairySpeed));
                let t: Float = Float(time) * copysign(abs(_fairyPhase) + 0.25, _fairyPhase - 0.5) / 4.0
                
                _light.position = float4(cos(t) * radius, 1.5, sin(t) * radius, 1.0)
                _light.attenuationRadius = float4(_fairyColor.x, _fairyColor.y, _fairyColor.z, ATTENUATION_RADIUS)

            case .stationary:
                _light.position = float4(0.0, 2.0, 2.0, 1.0)
                _light.attenuationRadius = float4(1.0, 0.875, 0.75, 5.0)
        }

        // Let light update its internals based on current camera
        light.update(camera:camera)
    }

    func upload(buffer: MTLBuffer, index: Int)
    {
        light.upload(buffer, index, camera)
    }
}
