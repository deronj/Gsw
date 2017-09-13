//
//  ConcreteCameraOSX.swift
//  Gsw
//
//  Created by Deron Johnson on 5/21/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Foundation
import simd

// For kVK keycodes
import Carbon.HIToolbox.Events

@objc class ConcreteCameraOSX : NSObject, Camera
{
    public static let EYE_Z_WC: Float = -15.0
    
    var dirty = true

    var position = float3(0, 1.5, -15) {
        willSet { if newValue != position { dirty = true } }
    }

    var direction = float3(0.0, 0.0, -1.0) {
        willSet { if newValue != direction { dirty = true } }
    }
    
    var up = float3(0.0, 1.0, 0.0) {
        willSet { if newValue != up { dirty = true } }
    }
    
    var right = float3(1, 0, 0)

    var moveLeft: Float = 0.0
    var moveRight: Float = 0.0
    var moveUp: Float = 0.0
    var moveDown: Float = 0.0
    var moveIn: Float = 0.0
    var moveOut: Float = 0.0
    
    var speed: Float = 10.0

    var mouseMovement = float2(0.0, 0.0)
    var mouseMovementSpeed: Float = 0.01
    
    private var _viewMatrix = matrix_identity_float4x4
    
    var viewMatrix: matrix_float4x4
    {
        if (dirty)
        {
            let at = position + direction
            _viewMatrix = lookAtMatrix(eye:position, center:at, up:up)
            dirty = false
        }
        return _viewMatrix
    }
    
    // The eye position in world coordinates
    init(eyePositionWC: float3)
    {
        position = eyePositionWC
    }
    
    func keyDown(_ keyCode: UInt16)
    {
        let key = Int(keyCode)

        switch (key)
        {
            // Horizontal movement
            case kVK_ANSI_A, kVK_LeftArrow: moveLeft = 1.0
            case kVK_ANSI_D, kVK_RightArrow: moveRight = -1.0

            // Vertical movement
            case kVK_ANSI_Q: moveUp = 1.0
            case kVK_ANSI_E: moveDown = -1.0

            // Movement in Z
            case kVK_ANSI_W, kVK_UpArrow: moveIn = -1.0
            case kVK_ANSI_S, kVK_DownArrow: moveOut = 1.0
            
            default: break
        }
    }
    
    func keyUp(_ keyCode: UInt16)
    {
        let key = Int(keyCode)
        
        switch (key)
        {
            // Horizontal movement
            case kVK_ANSI_A, kVK_LeftArrow: moveLeft = 0.0
            case kVK_ANSI_D, kVK_RightArrow: moveRight = 0.0
            
            // Vertical movement
            case kVK_ANSI_Q: moveUp = 0.0
            case kVK_ANSI_E: moveDown = 0.0
            
            // Movement in Z
            case kVK_ANSI_W, kVK_UpArrow: moveIn = 0.0
            case kVK_ANSI_S, kVK_DownArrow: moveOut = 0.0
            
            default: break
        }
    }
    
    func mouseMoved(_ deltaMovement: CGVector)
    {
        mouseMovement = float2(Float(deltaMovement.dx), Float(deltaMovement.dy))
    }
    
    func update(timestep: TimeInterval)
    {
        direction = vector_normalize(direction)
        up = vector_normalize(up)
        right = vector_cross(direction, up)
        
        // Calculate the camera-local movement direction
        let moveHorizontal = moveLeft + moveRight
        let moveVertical = moveUp + moveDown
        let moveZ = moveIn + moveOut
        var movementDir = float4(moveHorizontal, moveVertical, moveZ, 0)

        // Clamp the velocity to prevent too fast diagonal strafing
        if length(movementDir) > 1
        {
            movementDir = normalize(movementDir)
        }

        let velocity = speed * ((movementDir.x * right) + (movementDir.y * up) + (movementDir.z * direction))
        position += velocity * Float(timestep)
        
        mouseMovement *= mouseMovementSpeed
        if mouseMovement.x != 0
        {
            let yawRotation = matrix3x3_rotation(-mouseMovement.x, up)
            direction = matrix_multiply(yawRotation, direction)
            mouseMovement.x = 0
        }
        if mouseMovement.y != 0
        {
            right = vector_cross(direction, up)
            let pitchRotation = matrix3x3_rotation(-mouseMovement.y, right)
            direction = matrix_multiply(pitchRotation, direction)
            mouseMovement.y = 0
        }
    }
}
