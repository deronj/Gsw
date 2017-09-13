//
//  ScaleAnimator.swift
//  Gsw
//
//  Created by Deron Johnson on 7/8/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Foundation
import simd

// Animates an object by increasing its scale to a maximum and then decreasing its scale to a minimum,
// and then repeating.
//
class ScaleAnimator: Animator
{
    let _transform: TRSTransform
    let _speed: Float
    let _min: Float
    let _max: Float
    
    var _currentScale: Float = 1.0

    var increasing = true
    
    // The renderable must have a transform. Speed is in object coordinate units per second.
    public init?(renderable: Renderable, speed: Float, minScale: Float, maxScale: Float)
    {
        guard renderable.transform != nil else { return nil }
        
        _transform = renderable.transform!
        _speed = speed
        _min = minScale
        _max = maxScale
    }
 
    public func update(timeDelta: Float)
    {
        let scaleDelta = _speed * timeDelta
        _currentScale += scaleDelta * (increasing ? 1.0 : -1.0)

        // Change direction when we reach a limit
        if _currentScale <= _min
        {
            increasing = true
        }
        else if _currentScale >= _max
        {
            increasing = false
        }

        _currentScale = (_min..._max).clamp(_currentScale)
                
        // Scale all dimensions equally
        _transform.setScale(_currentScale)
    }
}
