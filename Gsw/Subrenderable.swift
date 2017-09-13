//
//  Subrenderable.swift
//  Gsw
//
//  Created by Deron Johnson on 6/22/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

// A renderable consists of multiple subrenderables, all of which share the same geometry buffer.
// Each subrenderable can have a different material.
//
protocol Subrenderable
{
    // All subrenderables must have a material, regardless of whether they are textured or not
    var material: Material { get set }
    
    func encode(to encoder: MTLRenderCommandEncoder)
}
