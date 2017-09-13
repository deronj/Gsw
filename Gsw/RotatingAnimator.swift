//
//  RotatingAnimator.swift
//  Gsw
//
//  Created by Deron Johnson on 7/7/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import simd

// Rotates a renderable at a given speed around a given axis.
//
class RotatingAnimator: Animator
{
    private let _transform: TRSTransform
    private let _radiansPerFrame: Float

    // The cumulative rotation angle
    private var _angle: Float = 0.0

    // A concatenation of all the delta rotations received
    var _cumulativeRotationMatrix = matrix_identity_float4x4
    
    // The renderable must have a transform. Speed is in degrees per second.
    public init?(renderable: Renderable, speed degreesPerFrame: Float, axis: float3)
    {
        guard renderable.transform != nil else { return nil }

        _transform = renderable.transform!
        _radiansPerFrame = degreesToRadians(degreesPerFrame)
        
        _transform.setRotationAxis(axis)
    }

    public func update(timeDelta: Float)
    {
        let angleDelta = _radiansPerFrame * timeDelta
        _transform.setRotationDelta(angleDelta)
    }
}
