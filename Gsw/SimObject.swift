//
//  SimObject.swift
//  Gsw
//
//  Created by Deron Johnson on 1/2/18.
//  Copyright © 2018 Deron Johnson. All rights reserved.
//

import Metal

class SimObject : SphereObject
{
    // TODO: calibrate
    let _SIZE : Float = 0.1

    var _simTrace : SimTrace
    var _particleIndex : Int

    public init(particleIndex : Int, simTrace: SimTrace, perObjectTransforms: PerObjectTransforms, material: Material, device: MTLDevice) throws
    {
        _simTrace = simTrace
        _particleIndex = particleIndex

        let transform = TRSTransform(perObjectTransforms: perObjectTransforms)

        try super.init(size:_SIZE, transform:transform, device:device)

        setMaterial(material)
        animator = SimTraceAnimator(object:self)
    }

    public func numSimFrames() -> Int
    {
        return _simTrace.numSimFrames()
    }

    func getParticlePositionForFrame(frameIndex: Int) -> float3
    {
        return _simTrace.getParticlePosition(frameIndex:frameIndex, particleIndex:_particleIndex)
    }
}
