//
//  Camera.swift
//  Gsw
//
//  Created by Deron Johnson on 5/21/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Foundation
import simd

protocol Camera: class 
{
    // Indicates that the currentViewMatrix has changed. Must be set to true by the 
    // adopting class whenever a view matrix modifying property is set.
    var dirty: Bool { get set }
    
    // The main output property of the camera
    var viewMatrix: matrix_float4x4 { get }
    
    // These are used to compute the the view matrix
    var position: float3 { get set }
    var direction: float3 { get set }
    var up: float3 { get set }

    // How fast the camera moves (in world space units)
    var speed: Float { get set }
    
    func update(timestep: TimeInterval)
}


