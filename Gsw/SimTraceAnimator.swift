//
//  SimTraceAnimator.swift
//  Gsw
//
//  Created by Deron Johnson on 1/2/18.
//  Copyright © 2018 Deron Johnson. All rights reserved.
//

import Foundation

// This animator updates the properties of the particles in a sim trace, such as the position,
// at a given rate. Each animator is in charge of updating the properties for a single 
// object, which corresponds to a single particle.
//
class SimTraceAnimator : Animator
{
    private var _object : SimObject
    private var _initialSimFrameIndex = 0
    private var _simFrameRate : Float = 0.0

    private var _absoluteTimeSinceStart : Float = 0.0
    private var _maxNumSimFrames : Int

    // simFrameRate is the desired number of sim frames updated per second
    public init (object: SimObject, simFrameRate : Float = 30.0, initialSimFrameIndex : Int = 0)
    {
        _object = object
        _simFrameRate = simFrameRate
        _initialSimFrameIndex = initialSimFrameIndex

        _maxNumSimFrames = object.numSimFrames()
    }

    public func update(timeDelta: Float)
    {
        _absoluteTimeSinceStart += timeDelta

        // Number of sim frames from start
        let numFramesElapsed = _absoluteTimeSinceStart * _simFrameRate

        // Truncate to get current frame and wrap around
        let curFrameIndex = Int(numFramesElapsed) % _maxNumSimFrames

        let position = _object.getParticlePositionForFrame(frameIndex: curFrameIndex)
        _object.transform!.setTranslation(position)
    }
}
