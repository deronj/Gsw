//
//  GlobalTransforms.swift
//  Gsw
//
//  Created by Deron Johnson on 6/30/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

// Provides initialization and management of the global matrices (ie. those hat are constant within a single frame):
// the view matrix, the projection matrix and the projection view matrix. The purpose of this class is to
// recalculate these matrices whenever the data they depend upon changes. The resulting public matrices
// (viewMatrix and projectionViewMatrix) are then combined by other software with per-object model matrices.
//
// Parameters of the projection matrix (foveaDegrees, nearZ clip and farZ clip) can optionally be specified.
// If not specified, default values will be used.
//
// As the rendering proceeds:
// + You need to set a new view matrix whenever the camera changes.
// + You need to set a new target size whenever the size of the target changes.
//
class GlobalTransforms
{
    public var dirty: Bool
    {
        get { return _viewDirty || !_projectionDirty }
    }
    
    public var foveaDegrees: Float
    {
        get { return _foveaDegrees }
        set { _foveaDegrees = newValue; _projectionDirty = true }
    }
    
    public var nearZ: Float
    {
        get { return _nearZ }
        set {_nearZ = newValue; _projectionDirty = true }
    }
    
    public var farZ: Float
    {
        get { return _farZ }
        set { _farZ = newValue; _projectionDirty = true }
    }
    
    public var viewMatrix: matrix_float4x4
    {
        get { return _viewMatrix }
        set { _viewMatrix = newValue; _viewDirty = true }
    }
    
    public var targetSize: float2!
    {
        get { return _targetSize }
        set { _targetSize = newValue; _projectionDirty = true }
    }
    
    private var _viewDirty = true
    private var _projectionDirty = true
    
    private var _viewMatrix = matrix_identity_float4x4
    private var _projectionMatrix = matrix_identity_float4x4

    public var projectionViewMatrix = matrix_identity_float4x4

    private var _targetSize : float2!
    
    private var _foveaDegrees: Float = 60.0
    
    private var _nearZ: Float = 0.1
    
    private var _farZ: Float = 100.0
    
    // Call this before frame rendering when the transforms are dirty
    public func update()
    {
        if (_projectionDirty)
        {
            // The projection matrix needs to be updated.
            let foveaRadians = degreesToRadians(_foveaDegrees)

            guard _targetSize != nil else { fatalError("GlobalTransforms: targetSize used before specified") }
            let aspectRatio = abs(_targetSize.x / _targetSize.y)

            _projectionMatrix = matrix_from_perspective_fov_aspectLH(foveaRadians, aspectRatio, nearZ, farZ)
        }

        if (_viewDirty || _projectionDirty)
        {
            // The projection view matrix needs to be updated
            projectionViewMatrix = matrix_multiply(_projectionMatrix, _viewMatrix)
        }

        _projectionDirty = false
        _viewDirty = false
    }
}
