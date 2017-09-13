//
//  BrownianAnimator.swift
//  Gsw
//
//  Created by Deron Johnson on 7/9/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import simd

// At each update, randomlyy rotates a renderable around a random axis by a random angle, which is between 0.0...maxAngle (in degrees).
// Then translates the renderable by a displacement vector in a random direction with a random magnitude between 0.0...maxDisplacement.
//
class BrownianAnimator: Animator
{
    let _transform: TRSTransform
    let _maxDisplacement: Float
    let _maxAngleRadians: Float
    
    var _currentRotationAngle: Float = 0.0
    var _currentTranslation = float3(0.0, 0.0, 0.0)
    
    // The renderable must have a transform. Speed is in degrees per second.
    public init?(renderable: Renderable, maxDisplacement: Float = 0.1, maxAngle: Float = 1.0)
    {
        guard renderable.transform != nil else { return nil }
        
        _transform = renderable.transform!
        _maxDisplacement = maxDisplacement
        _maxAngleRadians = degreesToRadians(maxAngle)
    }

    public func update(timeDelta: Float)
    {
        var deltaTranslationVec = randomUnitVector() // Direction vec
        let deltaTranslationMagnitude = randomFloat(0.0, _maxDisplacement)
        deltaTranslationVec *= deltaTranslationMagnitude
        _transform.setTranslationDelta(deltaTranslationVec)

        let deltaRotationAngle = randomFloat(0.0, _maxAngleRadians)
        let deltaRotationAxisVec = randomUnitVector()
        _transform.setRotationAxis(deltaRotationAxisVec)
        
        // The last one updates the transformstore
        _transform.setRotationDelta(deltaRotationAngle)
    }
}
