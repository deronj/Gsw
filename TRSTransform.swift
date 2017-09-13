//
//  TRSTransform.swift
//  Gsw
//
//  Created by Deron Johnson on 8/8/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

enum TRSTransformError: String, Error {
    case cantSetMatrix = "Cannot call setMatrix directly"
}

// A transform that is controlled by a scale, rotation and translation.
// The scale is applied first, then the rotation, and finally the translation.
//
class TRSTransform: Transform
{
    public var dirty: Bool
    {
        get { return _rotationDirty || _translationDirty || _scaleDirty }
    }

    public private(set) var rotationAngle: Float = 0.0
    public private(set) var rotationAxis = float3(0.0, 1.0, 0.0)
    public private(set) var translation = float3(0.0, 0.0, 0.0)
    public private(set) var scale: Float = 1.0
    
    private var _rotMatrix = matrix_identity_float4x4
    private var _transMatrix = matrix_identity_float4x4
    private var _scaleMatrix = matrix_identity_float4x4
    
    private var _rotationDirty = false
    private var _translationDirty = false
    private var _scaleDirty = false

    public init(perObjectTransforms: PerObjectTransforms)
    {
        super.init(matrix_identity_float4x4, perObjectTransforms:perObjectTransforms)
    }
    
    // Specify rotation angle (in degrees). You must call update() for this to affect the perObjectTransforms.
    public func setRotation(_ angle: Float)
    {
        rotationAngle = angle
        _rotationDirty = true
    }

    // Specify rotation angle change (in degrees). You must call update() for this to affect the perObjectTransforms.
    public func setRotationDelta(_ deltaAngle: Float)
    {
        rotationAngle += deltaAngle
        _rotationDirty = true
    }

    // Specify rotation axis. You must call update() for this to affect the transformstore.
    public func setRotationAxis(_ axis: float3)
    {
        rotationAxis = axis
        _rotationDirty = true
    }

    // Specify the translation. You must call update() for this to affect the perObjectTransforms.
    public func setTranslation(_ theTranslation: float3)
    {
        translation = theTranslation
        _translationDirty = true
    }
    
    // Specify the translation. You must call update() for this to affect the perObjectTransforms.
    public func setTranslationDelta(_ theDeltaTranslation: float3)
    {
        translation += theDeltaTranslation
        _translationDirty = true
    }

    // Specify the scale. You must call update() for this to affect the perObjectTransforms.
    public func setScale(_ theScale: Float)
    {
        scale = theScale
        _scaleDirty = true
    }

    // Specify a scale change. You must call update() for this to affect the perObjectTransforms.
    public func setScaleDelta(_ theDeltaScale: Float)
    {
        scale += theDeltaScale
        _scaleDirty = true
    }

    // Call this when the transform is dirty to update the model matrix 
    public func update()
    {
        if _rotationDirty
        {
            let rotRadians = degreesToRadians(rotationAngle)
            _rotMatrix = matrix_from_rotation(rotRadians, rotationAxis.x, rotationAxis.y, rotationAxis.z)
            _rotationDirty = false
        }

        if _translationDirty
        {
            _transMatrix = matrix_from_translation(translation.x, translation.y, translation.z)
            _translationDirty = false
        }
        
        if _scaleDirty
        {
            _scaleMatrix = matrix_from_scale(scale, scale, scale)
            _scaleDirty = false
        }

        modelMatrix = matrix_multiply(matrix_multiply(_transMatrix, _rotMatrix), _scaleMatrix)
    }
}
